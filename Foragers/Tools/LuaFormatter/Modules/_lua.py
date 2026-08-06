"""Shared Lua-aware helpers. Ignore braces/commas inside quoted strings and long-bracket strings."""


def _long_string_skip(text: str, i: int) -> int:
    """If text[i] == '[' starts a long-bracket string ([[..]] / [=[..]=]), return index just past its close. Else return -1."""
    if text[i] != "[":
        return -1
    j = i + 1
    while j < len(text) and text[j] == "=":
        j += 1
    if j >= len(text) or text[j] != "[":
        return -1
    level = j - i - 1
    close = "]" + "=" * level + "]"
    idx = text.find(close, j + 1)
    if idx == -1:
        return -1
    return idx + len(close)


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
        elif ch == "[":
            skip = _long_string_skip(text, i)
            if skip != -1:
                i = skip - 1  # skip the whole long string; loop will i += 1
                continue
            # not a long string (e.g. `t[k]`, `{ [1] = x }`) — no brace depth effect
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
    paren = 0  # ignore commas inside (...), e.g. table.concat(names, "_")
    in_s = in_d = esc = False
    i = 0
    n = len(inner)
    while i < n:
        ch = inner[i]
        if esc:
            cur += ch
            esc = False
            i += 1
            continue
        if in_d:
            cur += ch
            if ch == "\\":
                esc = True
            elif ch == '"':
                in_d = False
            i += 1
            continue
        if in_s:
            cur += ch
            if ch == "\\":
                esc = True
            elif ch == "'":
                in_s = False
            i += 1
            continue
        if ch == '"':
            in_d = True
            cur += ch
            i += 1
            continue
        if ch == "'":
            in_s = True
            cur += ch
            i += 1
            continue
        if ch == "[":
            skip = _long_string_skip(inner, i)
            if skip != -1:
                cur += inner[i:skip]
                i = skip  # skip the whole long string
                continue
        if ch == "(":
            paren += 1
        elif ch == ")":
            paren = max(0, paren - 1)
        if ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        if ch == "," and depth == 0 and paren == 0:
            if cur.strip():
                parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
        i += 1
    if cur.strip():
        parts.append(cur.strip())
    return parts
