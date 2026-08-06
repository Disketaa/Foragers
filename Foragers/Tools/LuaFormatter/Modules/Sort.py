"""Reorder Lua table fields: params by word-match groups, components by type order, tween targets by target order."""

import re

from _lua import matching_brace, split_top_level, table_block


def _key_of(entry: str):
    if "\n" in entry:
        return None
    m = re.match(r"(\w+)\s*=", entry)
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


def _sort_params(text: str, groups) -> str:
    if not groups:
        return text
    m = re.search(r"^([ \t]*)return\s*\{$", text, re.M)
    if not m:
        return text
    indent = m.group(1)
    _, close, inner = table_block(text, m)
    entries = split_top_level(inner)
    if len(entries) < 2:
        return text

    def sort_key(entry):
        key = _key_of(entry)
        if key is None:
            return (1, 0, 0)
        gi, ti = _group_rank(key, groups)
        return (0, gi, ti)

    sorted_entries = sorted(entries, key=sort_key)
    entry_indent = indent + "\t"
    return (
        text[:m.start()]
        + f"{indent}return {{\n{entry_indent}{f',\n{entry_indent}'.join(sorted_entries)},\n{indent}}}"
        + text[close + 1:]
    )


def _sort_components(text: str, order: list) -> str:
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

    entries.sort(key=lambda e: oi.get(component_name(e), len(order)))
    entry_indent = indent + "\t"
    return (
        text[:m.start()]
        + f"{indent}components = {{\n{entry_indent}{f',\n\n{entry_indent}'.join(entries)},\n{indent}}}"
        + text[close + 1:]
    )


def _sort_component_params(text: str, groups) -> str:
    if not groups:
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
        rebuilt.append(f"{{\n{param_indent}{f',\n{param_indent}'.join(sorted_parts)},\n{entry_indent}}}")
    joined = f",\n\n{entry_indent}".join(rebuilt)
    return (
        text[:m.start()]
        + f"{indent}components = {{\n{entry_indent}{joined},\n{indent}}}"
        + text[close + 1:]
    )


def _tween_target(part: str):
    m = re.search(r'target\s*=\s*"([^"]+)"', part)
    return m.group(1) if m else None


def _sort_tween_array(text: str, open_idx: int, close_idx: int, oi: dict) -> str:
    inner = text[open_idx + 1: close_idx]
    items = split_top_level(inner)
    if len(items) < 2:
        return text

    def key(it):
        t = _tween_target(it)
        return (-1, 0) if t is None else (0, oi.get(t, len(oi)))

    sorted_items = sorted(items, key=key)
    if sorted_items == items:
        return text
    if "\n" in inner:
        line_start = text.rfind("\n", 0, open_idx) + 1
        base_indent = re.match(r"[ \t]*", text[line_start:open_idx]).group()
        entry_indent = base_indent + "\t"
        new_inner = f"\n{entry_indent}{f',\n{entry_indent}'.join(sorted_items)},\n{base_indent}"
    else:
        new_inner = " " + ", ".join(sorted_items) + " "
    return text[:open_idx + 1] + new_inner + text[close_idx:]


def _sort_tween_tags(block: str, tags_open: int, tags_close: int, oi: dict) -> str:
    sub = block[tags_open + 1: tags_close]
    arrs = []
    for am in re.finditer(r"\b(\w+)\s*=\s*\{", sub):
        ao = am.end() - 1
        arrs.append((ao, matching_brace(sub, ao)))
    # reversed so earlier indices stay valid as splices shorten the slice
    for ao, ac in reversed(arrs):
        sub = _sort_tween_array(sub, ao, ac, oi)
    return block[:tags_open + 1] + sub + block[tags_close:]


def _sort_tweens(text: str, order: list) -> str:
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
            block = _sort_tween_array(block, ao, matching_brace(block, ao), oi)
        gm = re.search(r"\btags\s*=\s*\{", block)
        if gm:
            tao = block.index("{", gm.start())
            block = _sort_tween_tags(block, tao, matching_brace(block, tao), oi)
        out.append(text[pos: open_idx])
        out.append(block)
        pos = close_idx + 1
    out.append(text[pos:])
    return "".join(out)


def apply(text: str, config: dict) -> str:
    groups = _parse_groups(config)
    text = _sort_params(text, groups)
    text = _sort_components(text, config.get("component_order", {}).get("order", []))
    text = _sort_component_params(text, groups)
    return _sort_tweens(text, config.get("tween_order", {}).get("order", []))
