import re

from _lua import matching_brace, split_top_level


def apply(text: str, config: dict) -> str:
    order_map = config.get("component_param_order", {})
    if not order_map:
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

    entry_indent = indent + "\t"

    def param_key(part: str):
        if "\n" in part:
            return None  # nested block
        km = re.match(r"(\w+)\s*=", part)
        return km.group(1) if km else None

    rebuilt = []
    for entry in entries:
        cm = re.search(r'component\s*=\s*"([^"]+)"', entry)
        order = order_map.get(cm.group(1)) if cm else None
        e_open = entry.index("{")
        e_close = matching_brace(entry, e_open)
        parts = split_top_level(entry[e_open + 1: e_close])
        if not order or len(parts) < 2:
            rebuilt.append(entry)
            continue

        order_index = {name: i for i, name in enumerate(order)}

        def sort_key(item):
            part, key = item
            if key == "component":
                return (-2, 0)
            if key is None:
                return (1, 0)
            return (0, order_index.get(key, len(order)))

        sorted_parts = [p for p, _ in sorted([(p, param_key(p)) for p in parts], key=sort_key)]

        param_indent = entry_indent + "\t"
        joined = f",\n{param_indent}".join(sorted_parts)
        rebuilt.append(f"{{\n{param_indent}{joined},\n{entry_indent}}}")

    joined_entries = f",\n\n{entry_indent}".join(rebuilt)
    return (
        text[:m.start()]
        + f"{indent}components = {{\n{entry_indent}{joined_entries},\n{indent}}}"
        + text[close_idx + 1:]
    )
