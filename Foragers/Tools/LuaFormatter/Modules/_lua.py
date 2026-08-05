"""Shared Lua-aware helpers. Ignore braces/commas inside quoted strings."""


def matching_brace(text: str, open_idx: int) -> int:
    depth = 0
    i = open_idx
    n = len(text)
    in_s = in_d = esc = False
    while i < n:
        ch = text[i]
        if esc:
            esc = False
        elif in_d:
            if ch == "\\":
                esc = True
            elif ch == '"':
                in_d = False
        elif in_s:
            if ch == "\\":
                esc = True
            elif ch == "'":
                in_s = False
        elif ch == '"':
            in_d = True
        elif ch == "'":
            in_s = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("Unbalanced braces")


def split_top_level(inner: str) -> list[str]:
    parts, cur = [], ""
    depth = 0
    in_s = in_d = esc = False
    for ch in inner:
        if esc:
            cur += ch
            esc = False
            continue
        if in_d:
            cur += ch
            if ch == "\\":
                esc = True
            elif ch == '"':
                in_d = False
            continue
        if in_s:
            cur += ch
            if ch == "\\":
                esc = True
            elif ch == "'":
                in_s = False
            continue
        if ch == '"':
            in_d = True
            cur += ch
            continue
        if ch == "'":
            in_s = True
            cur += ch
            continue
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
