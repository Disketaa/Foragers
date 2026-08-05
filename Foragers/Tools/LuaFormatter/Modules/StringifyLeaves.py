import re

from _lua import matching_brace, split_top_level


def _collapse(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip())


def _is_table_child(entry: str) -> bool:
    """True if the entry's value is a table literal (bare `{` or `key = {`)."""
    return bool(re.match(r"^(\w+\s*=\s*)?\{", entry.strip()))


def _process_block(inner: str, indent: str):
    """Process a block's entries. Returns (processed_list, has_table_child)."""
    entries = [e for e in split_top_level(inner) if e.strip()]
    processed = []
    has_table = False
    for e in entries:
        pe = _process_entry(e, indent)
        processed.append(pe)
        if _is_table_child(pe):
            has_table = True
    return processed, has_table


def _process_entry(entry: str, indent: str) -> str:
    """Collapse a `key = { ... }` block iff all its children are scalars."""
    stripped = entry.strip()
    m = re.match(r"^(\w+)\s*=\s*\{", stripped)
    if not m or "\n" not in entry:
        return entry  # scalar, single-line table, or bare array — leave as-is
    key = m.group(1)
    open_idx = entry.index("{")
    close_idx = matching_brace(entry, open_idx)
    inner = entry[open_idx + 1: close_idx]
    children, has_table = _process_block(inner, indent + "\t")
    if not children:
        return f"{key} = {{}}"
    if has_table:
        body = ",\n".join(f"{indent}\t{c}" for c in children)
        return f"{key} = {{\n{body},\n{indent}}}"
    flat = ", ".join(_collapse(c) for c in children)
    return f"{key} = {{ {flat} }}"


def apply(text: str, config: dict) -> str:
    pattern = re.compile(r"^([ \t]*)return\s*\{$", re.MULTILINE)
    m = pattern.search(text)
    if not m:
        return text
    indent = m.group(1)
    open_idx = m.end() - 1
    close_idx = matching_brace(text, open_idx)
    inner = text[open_idx + 1: close_idx]
    children, _ = _process_block(inner, indent + "\t")
    body = ",\n".join(f"{indent}\t{c}" for c in children)
    return (
        text[:m.start()]
        + f"{indent}return {{\n{body},\n{indent}}}"
        + text[close_idx + 1:]
    )
