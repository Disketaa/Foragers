import re

from _lua import matching_brace, split_top_level


def collapse(s: str) -> str:
    return re.sub(r"\s+", " ", s.strip())


def format_value_list(items: list[str], indent: str) -> str:
    flat = [collapse(it) for it in items]
    if len(flat) == 1:
        item = flat[0]
        if item.startswith("{") and item.endswith("}"):
            inner = item[1:-1].strip()
            item = "{ " + inner + " }"
        return "{ " + item + " }"
    body = ",\n".join(f"{indent}\t{it}" for it in flat)
    return "{\n" + body + ",\n" + indent + "}"


def format_key_entries(inner: str, indent: str) -> str:
    out = []
    for entry in split_top_level(inner):
        m = re.match(r"^(\w+)\s*=\s*\{", entry)
        if not m:
            out.append(f"{indent}\t{collapse(entry)},")
            continue
        key = m.group(1)
        open_idx = m.end() - 1
        close_idx = matching_brace(entry, open_idx)
        items = split_top_level(entry[open_idx + 1: close_idx])
        if not items:
            out.append(f"{indent}\t{key} = {{}},")
            continue
        value_str = format_value_list(items, indent + "\t")
        out.append(f"{indent}\t{key} = {value_str},")
    return "\n".join(out)


def apply(text: str, config: dict) -> str:
    pattern = re.compile(r"^[ \t]*tags\s*=\s*\{$", re.MULTILINE)
    out, pos = [], 0
    for m in pattern.finditer(text):
        if m.start() < pos:
            continue
        out.append(text[pos:m.start()])
        indent = re.match(r"[ \t]*", m.group()).group()
        open_idx = m.end() - 1
        close_idx = matching_brace(text, open_idx)
        inner = text[open_idx + 1: close_idx]
        if inner.strip():
            body = format_key_entries(inner, indent)
            out.append(f"{indent}tags = {{\n{body}\n{indent}}}")
        else:
            out.append(f"{indent}tags = {{}}")
        pos = close_idx + 1
    out.append(text[pos:])
    return "".join(out)
