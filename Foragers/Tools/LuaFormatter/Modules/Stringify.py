"""Collapse Lua literals to single lines: scalar table children, items/tags blocks, inline single-return functions."""

import re

from _lua import collapse, matching_brace, split_top_level, table_block

_NAMED_TABLE = re.compile(r"^(\w+)\s*=\s*\{")
_ANY_TABLE = re.compile(r"^(\w+\s*=\s*)?\{")


def _is_table_child(entry: str) -> bool:
    return bool(_ANY_TABLE.match(entry.strip()))


def _collapse_leaves(text: str) -> str:
    m = re.search(r"^([ \t]*)return\s*\{$", text, re.M)
    if not m:
        return text
    indent = m.group(1)
    _, close, inner = table_block(text, m)
    children, _ = _process_block(inner, indent + "\t")
    body = ",\n".join(f"{indent}\t{c}" for c in children)
    return text[:m.start()] + f"{indent}return {{\n{body},\n{indent}}}" + text[close + 1:]


def _process_block(inner: str, indent: str) -> tuple:
    out, has_table = [], False
    for e in split_top_level(inner):
        if not e.strip():
            continue
        out.append(_process_entry(e, indent))
        if _is_table_child(out[-1]):
            has_table = True
    return out, has_table


def _process_entry(entry: str, indent: str) -> str:
    m = _NAMED_TABLE.match(entry)
    if not m or "\n" not in entry:
        return entry
    key = m.group(1)
    _, close, inner = table_block(entry, m)
    children, has_table = _process_block(inner, indent + "\t")
    if not children:
        return f"{key} = {{}}"
    if has_table:
        body = ",\n".join(f"{indent}\t{c}" for c in children)
        return f"{key} = {{\n{body},\n{indent}}}"
    return f"{key} = {{ {', '.join(collapse(c) for c in children)} }}"


def _collapse_tags(text: str) -> str:
    pattern = re.compile(r"^[ \t]*tags\s*=\s*\{$", re.M)
    out, pos = [], 0
    for m in pattern.finditer(text):
        if m.start() < pos:
            continue
        out.append(text[pos:m.start()])
        indent = re.match(r"[ \t]*", m.group()).group()
        _, close, inner = table_block(text, m)
        if inner.strip():
            body = _format_tags(inner, indent)
            out.append(f"{indent}tags = {{\n{body}\n{indent}}}")
        else:
            out.append(f"{indent}tags = {{}}")
        pos = close + 1
    out.append(text[pos:])
    return "".join(out)


def _format_tags(inner: str, indent: str) -> str:
    out = []
    for entry in split_top_level(inner):
        m = _NAMED_TABLE.match(entry)
        if not m:
            out.append(f"{indent}\t{collapse(entry)},")
            continue
        key = m.group(1)
        _, close, sub = table_block(entry, m)
        values = split_top_level(sub)
        if not values:
            out.append(f"{indent}\t{key} = {{}},")
        else:
            out.append(f"{indent}\t{key} = {_format_value_list(values, indent + '\t')},")
    return "\n".join(out)


def _format_value_list(values: list, indent: str) -> str:
    flat = [collapse(v) for v in values]
    if len(flat) == 1:
        item = flat[0]
        if item.startswith("{") and item.endswith("}"):
            item = "{ " + item[1:-1].strip() + " }"
        return "{ " + item + " }"
    body = ",\n".join(f"{indent}\t{v}" for v in flat)
    return "{\n" + body + ",\n" + indent + "}"


def _item_weight(entry: str):
    m = re.search(r"weight\s*=\s*([0-9]+(?:\.[0-9]+)?)", entry)
    return float(m.group(1)) if m else None


def _collapse_items(text: str) -> str:
    pattern = re.compile(r"^([ \t]*)items\s*=\s*\{$", re.M)
    out, pos = [], 0
    for m in pattern.finditer(text):
        if m.start() < pos:
            continue
        out.append(text[pos:m.start()])
        indent = m.group(1)
        _, close, inner = table_block(text, m)
        entries = [e for e in split_top_level(inner) if e.strip()]
        if not entries:
            out.append(f"{indent}items = {{}}")
        else:
            stringified = [_stringify_item(e) for e in entries]
            stringified.sort(key=lambda e: (_item_weight(e) is None, _item_weight(e) or 0))
            body = ",\n".join(f"{indent}\t{e}" for e in stringified)
            out.append(f"{indent}items = {{\n{body},\n{indent}}}")
        pos = close + 1
    out.append(text[pos:])
    return "".join(out)


def _stringify_item(entry: str) -> str:
    _, close, inner = table_block(entry, re.search(r"^\{", entry))
    parts = [collapse(p) for p in split_top_level(inner) if p.strip()]
    return "{ " + ", ".join(parts) + " }"


def _collapse_functions(text: str) -> str:
    pattern = re.compile(
        r"(\bfunction\s*\([^()\n]*\))\s*\n([ \t]*)return\s+([^\n]+?)\s*\n[ \t]*end"
    )

    def repl(m):
        if re.search(r"\b(function|end)\b", m.group(3)):
            return m.group(0)
        return f"{m.group(1)} return {m.group(3)} end"

    return pattern.sub(repl, text)


def apply(text: str, config: dict) -> str:
    text = _collapse_leaves(text)
    text = _collapse_tags(text)
    text = _collapse_items(text)
    return _collapse_functions(text)
