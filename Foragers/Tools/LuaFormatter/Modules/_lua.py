"""Shared Lua-aware helpers: tokenize text while ignoring quoted strings and long-bracket strings."""

import re


def collapse(s: str) -> str:
    """Flatten any run of whitespace to one space, for single-lining entries."""
    return re.sub(r"\s+", " ", s.strip())


def _long_string_skip(text: str, i: int) -> int:
    """If text[i] == '[' opens a long-bracket string ([[..]] / [=[..]=]), return the index just past its close. Else -1."""
    if text[i] != "[":
        return -1
    j = i + 1
    while j < len(text) and text[j] == "=":
        j += 1
    if j >= len(text) or text[j] != "[":
        return -1
    level = j - i - 1
    idx = text.find("]" + "=" * level + "]", j + 1)
    if idx == -1:
        return -1
    return idx + level + 2  # close = `]` + `=`*level + `]`


def matching_brace(text: str, open_idx: int) -> int:
    """Index of the `}` matching the `{` at open_idx, ignoring strings."""
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
                i = skip - 1
                continue
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    raise ValueError("Unbalanced braces")


def split_top_level(inner: str) -> list[str]:
    """Split a block body on top-level commas (not inside {} , () or strings)."""
    parts, cur = [], ""
    depth = paren = 0
    in_s = in_d = esc = False
    i, n = 0, len(inner)
    while i < n:
        ch = inner[i]
        if esc:
            cur += ch
            esc = False
        elif in_d:
            cur += ch
            if ch == "\\":
                esc = True
            elif ch == '"':
                in_d = False
        elif in_s:
            cur += ch
            if ch == "\\":
                esc = True
            elif ch == "'":
                in_s = False
        elif ch == '"':
            in_d = True
            cur += ch
        elif ch == "'":
            in_s = True
            cur += ch
        elif ch == "[":
            skip = _long_string_skip(inner, i)
            if skip != -1:
                cur += inner[i:skip]
                i = skip
                continue
            cur += ch  # plain `[` (e.g. `[10] = x`) is not a long string — keep it
        elif ch == "(":
            paren += 1
            cur += ch
        elif ch == ")":
            paren = max(0, paren - 1)
            cur += ch
        elif ch == "{":
            depth += 1
            cur += ch
        elif ch == "}":
            depth -= 1
            cur += ch
        elif ch == "," and depth == 0 and paren == 0:
            if cur.strip():
                parts.append(cur.strip())
            cur = ""
        else:
            cur += ch
        i += 1
    if cur.strip():
        parts.append(cur.strip())
    return parts


def table_block(text: str, m) -> tuple:
    """Given a regex match ending on a `{` (a table literal opener), return (open_idx, close_idx, inner)."""
    open_idx = m.end() - 1
    close_idx = matching_brace(text, open_idx)
    return open_idx, close_idx, text[open_idx + 1: close_idx]
