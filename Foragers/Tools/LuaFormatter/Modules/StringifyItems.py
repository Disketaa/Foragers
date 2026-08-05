import re

from _lua import matching_brace, split_top_level


def _collapse(s: str) -> str:
    """Collapse any run of whitespace to a single space, strip edges."""
    return re.sub(r"\s+", " ", s.strip())


def _weight(entry: str):
    """Return the numeric `weight = N` of an entry, or None."""
    m = re.search(r"weight\s*=\s*([0-9]+(?:\.[0-9]+)?)", entry)
    return float(m.group(1)) if m else None


def _stringify(entry: str) -> str:
    """Collapse a multi-line `{ data = "...", weight = N }` into one line."""
    e_open = entry.index("{")
    e_close = matching_brace(entry, e_open)
    inner = entry[e_open + 1: e_close]
    parts = [p.strip() for p in split_top_level(inner) if p.strip()]
    return "{ " + ", ".join(_collapse(p) for p in parts) + " }"


def apply(text: str, config: dict) -> str:
    pattern = re.compile(r"^([ \t]*)items\s*=\s*\{$", re.MULTILINE)
    out, pos = [], 0
    for m in pattern.finditer(text):
        if m.start() < pos:
            continue
        out.append(text[pos:m.start()])
        indent = m.group(1)
        open_idx = m.end() - 1
        close_idx = matching_brace(text, open_idx)
        inner = text[open_idx + 1: close_idx]
        entries = [e for e in split_top_level(inner)]
        if not entries:
            out.append(f"{indent}items = {{}}")
        else:
            stringified = [_stringify(e) for e in entries]
            # stable sort: by weight ascending, entries without weight keep order
            stringified.sort(key=lambda e: (_weight(e) is None, _weight(e) or 0))
            item_indent = indent + "\t"
            body = ",\n".join(f"{item_indent}{e}" for e in stringified)
            out.append(f"{indent}items = {{\n{body},\n{indent}}}")
        pos = close_idx + 1
    out.append(text[pos:])
    return "".join(out)
