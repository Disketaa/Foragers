"""Reorder Lua table fields by declared order lists: sprite params, components, component params, tween targets."""

import re
import sys
from pathlib import Path

from _lua import matching_brace, split_top_level, table_block

_found = []
_current_path = None


def set_path(path) -> None:
    global _current_path
    _current_path = path


def finalize(base_dir) -> None:
    """Report keys the order lists didn't cover, so a data file typo is visible."""
    if not _found:
        return
    by_param = {}
    for path, key in _found:
        by_param.setdefault(key, []).append(Path(path).name)
    print("\n\u26a0\ufe0f [Error] Unknown params not in [param_order]:", file=sys.stderr)
    for key, names in sorted(by_param.items()):
        print(f"  {key}: {', '.join(sorted(names))}", file=sys.stderr)


def _key_of(entry: str):
    """Sort key of a single-line `key = value` entry; multiline blocks are unsortable."""
    if "\n" in entry:
        return None
    m = re.match(r"(\w+)\s*=", entry)
    return m.group(1) if m else None


def _order_index(order: list) -> dict:
    return {name: i for i, name in enumerate(order)}


def _sort_params(text: str, order: list) -> str:
    """Sort `return {...}` params: declared order first, unknown params next, blocks last."""
    if not order:
        return text
    m = re.search(r"^([ \t]*)return\s*\{$", text, re.M)
    if not m:
        return text
    indent = m.group(1)
    _, close, inner = table_block(text, m)
    entries = split_top_level(inner)
    if len(entries) < 2:
        return text
    oi = _order_index(order)
    keyed = [(e, _key_of(e)) for e in entries]

    def sort_key(item):
        _, key = item
        return (1, 0) if key is None else (0, oi.get(key, len(order)))

    sorted_entries = [e for e, _ in sorted(keyed, key=sort_key)]
    for _, key in keyed:
        if key is not None and key not in oi:
            _found.append((_current_path, key))
    entry_indent = indent + "\t"
    return (
        text[:m.start()]
        + f"{indent}return {{\n{entry_indent}{f',\n{entry_indent}'.join(sorted_entries)},\n{indent}}}"
        + text[close + 1:]
    )


def _sort_components(text: str, order: list) -> str:
    """Sort `components = {...}` entries by declared component order."""
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


def _sort_component_params(text: str, order_map: dict) -> str:
    """Sort each component entry's params by that component's declared param order."""
    if not order_map:
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
        cm = re.search(r'component\s*=\s*"([^"]+)"', entry)
        order = order_map.get(cm.group(1)) if cm else None
        if not order:
            rebuilt.append(entry)
            continue
        e_open = entry.index("{")
        e_close = matching_brace(entry, e_open)
        parts = split_top_level(entry[e_open + 1: e_close])
        if len(parts) < 2:
            rebuilt.append(entry)
            continue
        oi = _order_index(order)

        def sort_key(item):
            _, key = item
            if key == "component":
                return (-2, 0)
            if key is None:
                return (1, 0)
            return (0, oi.get(key, len(order)))

        sorted_parts = [p for p, _ in sorted([(p, _key_of(p)) for p in parts], key=sort_key)]
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
    """Sort an array block's items by tween target; non-target flags stay first."""
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
    """Sort each `tags.<name> = {...}` array inside the tags block."""
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
    """Sort items in a tween component's `tweens = {...}` and each `tags.<name> = {...}`."""
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
    text = _sort_params(text, config.get("param_order", {}).get("order", []))
    text = _sort_components(text, config.get("component_order", {}).get("order", []))
    text = _sort_component_params(text, config.get("component_param_order", {}))
    return _sort_tweens(text, config.get("tween_order", {}).get("order", []))
