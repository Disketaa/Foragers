"""Reorder Lua table fields: params by word-match groups, components by type order, tween targets by target order."""

import re
import sys
from pathlib import Path

from _lua import matching_brace, split_top_level, table_block


# Unlisted-value debug state, accumulated across the whole run.
_current_path = None
_issues = {  # kind -> value -> ordered list of files using it
    "param": {},
    "component": {},
    "tween": {},
}


def set_path(path):
    global _current_path
    _current_path = str(path)


def _short(path: str) -> str:
    return Path(path).stem


def _report(kind: str, value: str):
    files = _issues[kind].setdefault(value, [])
    if _current_path and _short(_current_path) not in files:
        files.append(_short(_current_path))


def finalize(script_dir):
    labels = {
        "param": "Param not listed in param_groups",
        "component": "Component not in component_order",
        "tween": "Tween target not in tween_order",
    }
    for kind in ("param", "component", "tween"):
        for value, files in _issues[kind].items():
            loc = ", ".join(files) if files else "?"
            print(f"⚠️  {labels[kind]}: '{value}'  ({loc})", file=sys.stderr)


def _key_of(entry: str):
    # Key is always on the first line (e.g. `spacing = {`); a multiline value
    # must not lose its key, or group-based sorting breaks.
    first = entry.split("\n", 1)[0]
    m = re.match(r"(\w+)\s*=", first)
    return m.group(1) if m else None


def _words(s: str) -> list:
    words, cur = [], []
    for ch in s:
        if ch.isalnum():
            if ch.isupper() and cur and cur[-1].islower():
                words.append("".join(cur).lower())
                cur = []
            cur.append(ch)
        elif cur:
            words.append("".join(cur).lower())
            cur = []
    if cur:
        words.append("".join(cur).lower())
    return words


def _parse_groups(config: dict):
    """[(group_name, [frozenset(tag_words), ...])] in declared group order."""
    g = config.get("param_groups") or {}
    order = g.get("order")
    if isinstance(order, str):
        order = order.replace(",", " ").split()
    if not order:
        return None
    groups = []
    for name in order:
        entry = g.get(name) or {}
        tags = entry.get("tags") if isinstance(entry, dict) else None
        if isinstance(tags, str):
            tags = tags.replace(",", " ").split()
        groups.append((name, [frozenset(_words(t)) for t in (tags or [])]))
    return groups


def _group_rank(key: str, groups) -> tuple:
    """(group_index, tag_index) of the most specific match — the tag sharing the most words wins;
    ties break to the earlier group. This beats "first match" so shared words (max, radius, x)
    can't pull a key into the wrong group. No shared word -> last."""
    kw = frozenset(_words(key))
    best = None  # (shared_count, -group_index, -tag_index); negated so ties pick the earlier group
    for gi, (_, tags) in enumerate(groups):
        for ti, twords in enumerate(tags):
            shared = len(kw & twords)
            if shared and (best is None or (shared, -gi, -ti) > best):
                best = (shared, -gi, -ti)
    if best is None:
        return (len(groups), 10 ** 9)
    return (-best[1], -best[2])


def _order_index(order: list) -> dict:
    return {name: i for i, name in enumerate(order)}


def _listed_param_keys(config: dict) -> set:
    """Explicitly-named param keys across all param_groups tags."""
    g = config.get("param_groups") or {}
    keys = set()
    for name, entry in g.items():
        if name == "order" or not isinstance(entry, dict):
            continue
        tags = entry.get("tags")
        if isinstance(tags, str):
            tags = tags.replace(",", " ").split()
        keys.update(tags or [])
    return keys


_STRUCTURAL_KEYS = {"component", "components", "tweens", "tags"}


def _collect_params(entries, listed: set, missing: list):
    if missing is None:
        return
    for e in entries:
        key = _key_of(e)
        if (
            key
            and key not in _STRUCTURAL_KEYS
            and key not in listed
            and key not in missing
        ):
            missing.append(key)


def _sort_params(text: str, groups, listed: set | None = None, missing: list | None = None) -> str:
    if not groups:
        return text
    if listed is None or missing is None:
        return text
    m = re.search(r"^([ \t]*)return\s*\{$", text, re.M)
    if not m:
        return text
    indent = m.group(1)
    _, close, inner = table_block(text, m)
    entries = split_top_level(inner)
    if len(entries) < 2:
        return text
    _collect_params(entries, listed, missing)

    def sort_key(entry):
        key = _key_of(entry)
        if key is None:
            return (1, 0, 0)
        gi, ti = _group_rank(key, groups)
        return (0, gi, ti)

    sorted_entries = sorted(entries, key=sort_key)
    entry_indent = indent + "\t"
    sorted_body = f",\n{entry_indent}".join(sorted_entries)
    return (
        text[:m.start()]
        + f"{indent}return {{\n{entry_indent}{sorted_body},\n{indent}}}"
        + text[close + 1:]
    )


def _sort_components(text: str, order: list, missing=None) -> str:
    if not order:
        return text
    m = re.search(r"^([ \t]*)components\s*=\s*\{$", text, re.M)
    if not m:
        return text
    indent = m.group(1)
    _, close, inner = table_block(text, m)
    entries = split_top_level(inner)
    if not entries:
        return text
    oi = _order_index(order)

    def component_name(e):
        cm = re.search(r'component\s*=\s*"([^"]+)"', e)
        return cm.group(1) if cm else None

    if missing is not None:
        for e in entries:
            name = component_name(e)
            if name and name not in oi and name not in missing:
                missing.append(name)

    entries.sort(key=lambda e: oi.get(component_name(e), len(order)))
    entry_indent = indent + "\t"
    joined_entries = f",\n\n{entry_indent}".join(entries)
    return (
        text[:m.start()]
        + f"{indent}components = {{\n{entry_indent}{joined_entries},\n{indent}}}"
        + text[close + 1:]
    )


def _sort_component_params(text: str, groups, listed: set | None = None, missing: list | None = None) -> str:
    if not groups:
        return text
    if listed is None or missing is None:
        return text
    m = re.search(r"^([ \t]*)components\s*=\s*\{$", text, re.M)
    if not m:
        return text
    indent = m.group(1)
    _, close, inner = table_block(text, m)
    entries = split_top_level(inner)
    if not entries:
        return text
    entry_indent = indent + "\t"
    rebuilt = []
    for entry in entries:
        e_open = entry.index("{")
        e_close = matching_brace(entry, e_open)
        parts = split_top_level(entry[e_open + 1: e_close])
        if len(parts) < 2:
            rebuilt.append(entry)
            continue
        _collect_params(parts, listed, missing)

        def sort_key(part):
            key = _key_of(part)
            if key == "component":
                return (-2, 0, 0)
            if key is None:
                return (1, 0, 0)
            gi, ti = _group_rank(key, groups)
            return (0, gi, ti)

        sorted_parts = sorted(parts, key=sort_key)
        param_indent = entry_indent + "\t"
        joined_parts = f",\n{param_indent}".join(sorted_parts)
        rebuilt.append(f"{{\n{param_indent}{joined_parts},\n{entry_indent}}}")
    joined = f",\n\n{entry_indent}".join(rebuilt)
    return (
        text[:m.start()]
        + f"{indent}components = {{\n{entry_indent}{joined},\n{indent}}}"
        + text[close + 1:]
    )


def _tween_target(part: str):
    m = re.search(r'target\s*=\s*"([^"]+)"', part)
    return m.group(1) if m else None


def _sort_tween_array(text: str, open_idx: int, close_idx: int, oi: dict, missing=None) -> str:
    inner = text[open_idx + 1: close_idx]
    items = split_top_level(inner)
    if len(items) < 2:
        return text

    def key(it):
        t = _tween_target(it)
        return (-1, 0) if t is None else (0, oi.get(t, len(oi)))

    if missing is not None:
        for it in items:
            t = _tween_target(it)
            if t and t not in oi and t not in missing:
                missing.append(t)

    sorted_items = sorted(items, key=key)
    if sorted_items == items:
        return text
    if "\n" in inner:
        line_start = text.rfind("\n", 0, open_idx) + 1
        base_match = re.match(r"[ \t]*", text[line_start:open_idx])
        base_indent = base_match.group() if base_match else ""
        entry_indent = base_indent + "\t"
        inner_joined = f",\n{entry_indent}".join(sorted_items)
        new_inner = f"\n{entry_indent}{inner_joined},\n{base_indent}"
    else:
        new_inner = " " + ", ".join(sorted_items) + " "
    return text[:open_idx + 1] + new_inner + text[close_idx:]


def _sort_tween_tags(block: str, tags_open: int, tags_close: int, oi: dict, missing=None) -> str:
    sub = block[tags_open + 1: tags_close]
    arrs = []
    for am in re.finditer(r"\b(\w+)\s*=\s*\{", sub):
        ao = am.end() - 1
        arrs.append((ao, matching_brace(sub, ao)))
    # reversed so earlier indices stay valid as splices shorten the slice
    for ao, ac in reversed(arrs):
        sub = _sort_tween_array(sub, ao, ac, oi, missing)
    return block[:tags_open + 1] + sub + block[tags_close:]


def _sort_tweens(text: str, order: list, missing=None) -> str:
    if not order:
        return text
    oi = _order_index(order)
    out = []
    pos = 0
    for m in re.finditer(r'component\s*=\s*"tween"', text):
        open_idx = text.rfind("{", 0, m.start())
        close_idx = matching_brace(text, open_idx)
        block = text[open_idx: close_idx + 1]
        tm = re.search(r"\btweens\s*=\s*\{", block)
        if tm:
            ao = block.index("{", tm.start())
            block = _sort_tween_array(block, ao, matching_brace(block, ao), oi, missing)
        gm = re.search(r"\btags\s*=\s*\{", block)
        if gm:
            tao = block.index("{", gm.start())
            block = _sort_tween_tags(block, tao, matching_brace(block, tao), oi, missing)
        out.append(text[pos: open_idx])
        out.append(block)
        pos = close_idx + 1
    out.append(text[pos:])
    return "".join(out)


def apply(text: str, config: dict) -> str:
    groups = _parse_groups(config)
    listed = _listed_param_keys(config)
    missing_params = []
    missing_components = []
    missing_tweens = []
    text = _sort_params(text, groups, listed, missing_params)
    text = _sort_components(
        text, config.get("component_order", {}).get("order", []), missing_components
    )
    text = _sort_component_params(text, groups, listed, missing_params)
    text = _sort_tweens(
        text, config.get("tween_order", {}).get("order", []), missing_tweens
    )
    for value in missing_params:
        _report("param", value)
    for value in missing_components:
        _report("component", value)
    for value in missing_tweens:
        _report("tween", value)
    return text
