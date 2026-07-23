import re


def matching_brace(text: str, open_idx: int) -> int:
    depth = 0
    for i in range(open_idx, len(text)):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return i
    raise ValueError("Unbalanced braces")


def split_top_level(inner: str) -> list[str]:
    parts, depth, cur = [], 0, ""
    for ch in inner:
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        if ch == "," and depth == 0:
            if cur.strip():
                parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
    if cur.strip():
        parts.append(cur.strip())
    return parts


def apply(text: str, config: dict) -> str:
    order = config.get("component_order", {}).get("order", [])
    if not order:
        return text

    pattern = re.compile(r"^([ \t]*)components\s*=\s*\{$", re.MULTILINE)
    m = pattern.search(text)
    if not m:
        return text

    indent = m.group(1)
    open_idx = m.end() - 1
    close_idx = matching_brace(text, open_idx)
    inner = text[open_idx + 1: close_idx]

    entries = split_top_level(inner)
    if not entries:
        return text

    order_index = {name: i for i, name in enumerate(order)}

    def component_name(entry: str):
        cm = re.search(r'component\s*=\s*"([^"]+)"', entry)
        return cm.group(1) if cm else None

    def sort_key(entry: str):
        return order_index.get(component_name(entry), len(order))

    sorted_entries = sorted(entries, key=sort_key)

    entry_indent = indent + "\t"
    joined = f",\n\n{entry_indent}".join(sorted_entries)
    return (
        text[:m.start()]
        + f"{indent}components = {{\n{entry_indent}{joined},\n{indent}}}"
        + text[close_idx + 1:]
    )
