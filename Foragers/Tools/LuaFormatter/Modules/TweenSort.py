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


def _target(part: str):
    m = re.search(r'target\s*=\s*"([^"]+)"', part)
    return m.group(1) if m else None


def sort_items(items: list[str], order_index: dict) -> list[str]:
    def key(it):
        t = _target(it)
        if t is None:
            return (-1, 0)  # flags like destroyOnComplete stay first
        return (0, order_index.get(t, len(order_index)))

    return sorted(items, key=key)


def splice_array(text: str, open_idx: int, close_idx: int, order_index: dict):
    """Sort items inside an array block in place. Returns (text, changed)."""
    inner = text[open_idx + 1: close_idx]
    items = split_top_level(inner)
    if len(items) < 2:
        return text, False
    sorted_items = sort_items(items, order_index)
    if sorted_items == items:
        return text, False

    multiline = "\n" in inner
    if multiline:
        line_start = text.rfind("\n", 0, open_idx) + 1
        base_indent = re.match(r"[ \t]*", text[line_start:open_idx]).group()
        entry_indent = base_indent + "\t"
        body = f",\n{entry_indent}".join(sorted_items)
        new_inner = f"\n{entry_indent}{body},\n{base_indent}"
    else:
        new_inner = " " + ", ".join(sorted_items) + " "

    return text[:open_idx + 1] + new_inner + text[close_idx:], True


def process_tags(text: str, tags_open: int, tags_close: int, order_index: dict) -> str:
    """Sort items inside each named array of a tags map."""
    inner = text[tags_open + 1: tags_close]
    arrs = []
    for m in re.finditer(r"\b(\w+)\s*=\s*\{", inner):
        ao = m.end() - 1
        ac = matching_brace(inner, ao)
        arrs.append((m.start(), ao, ac))
    for start, ao, ac in reversed(arrs):
        inner, _ = splice_array(inner, ao, ac, order_index)
    return text[:tags_open + 1] + inner + text[tags_close:]


def apply(text: str, config: dict) -> str:
    order = config.get("tween_order", {}).get("order", [])
    if not order:
        return text
    order_index = {name: i for i, name in enumerate(order)}

    out = []
    pos = 0
    for m in re.finditer(r'component\s*=\s*"tween"', text):
        open_idx = text.rfind("{", 0, m.start())
        close_idx = matching_brace(text, open_idx)
        block = text[open_idx: close_idx + 1]

        # sort tweens = { ... }
        new_block = block
        tm = re.search(r"\btweens\s*=\s*\{", new_block)
        if tm:
            ao = new_block.index("{", tm.start())
            ac = matching_brace(new_block, ao)
            new_block, _ = splice_array(new_block, ao, ac, order_index)

        # sort each tags.<name> = { ... }
        gm = re.search(r"\btags\s*=\s*\{", new_block)
        if gm:
            tao = new_block.index("{", gm.start())
            tac = matching_brace(new_block, tao)
            new_block = process_tags(new_block, tao, tac, order_index)

        out.append(text[pos: open_idx])
        out.append(new_block)
        pos = close_idx + 1
    out.append(text[pos:])
    return "".join(out)
