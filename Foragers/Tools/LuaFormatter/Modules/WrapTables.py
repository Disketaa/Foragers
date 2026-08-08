"""Break single-line table literals that exceed column_limit into multiline, one element per line.

Does NOT collapse multiline tables back to one line — that direction causes needless churn.
Repeatedly breaks the innermost offending table until stable (breaking an inner table puts
newlines into its parent, so the parent naturally stops being a candidate).
"""

import re

from _lua import split_top_level


def _scan_tables(text: str):
    """Yield (open_idx, close_idx) for every table literal, in closing order, ignoring strings."""
    stack = []
    n = len(text)
    in_s = in_d = esc = False
    i = 0
    pairs = []
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
            stack.append(i)
        elif ch == "}" and stack:
            pairs.append((stack.pop(), i))
        i += 1
    return pairs


def _break_table(text: str, open_idx: int, close_idx: int) -> str:
    line_start = text.rfind("\n", 0, open_idx) + 1
    indent = re.match(r"[ \t]*", text[line_start:open_idx]).group()
    items = split_top_level(text[open_idx + 1: close_idx])
    if len(items) < 2:
        return text
    entry_indent = indent + "\t"
    body = "\n" + entry_indent + (",\n" + entry_indent).join(items) + ",\n" + indent
    return text[:open_idx + 1] + body + text[close_idx:]


def apply(text: str, config: dict) -> str:
    modules = config.get("Modules", {})
    limit = (modules.get("WrapTables") or {}).get("column_limit", 120)

    while True:
        candidates = []
        for open_idx, close_idx in _scan_tables(text):
            if "\n" in text[open_idx: close_idx + 1]:
                continue  # already multiline — leave alone
            line_start = text.rfind("\n", 0, open_idx) + 1
            line_end = text.find("\n", close_idx)
            if line_end == -1:
                line_end = len(text)
            if line_end - line_start > limit:
                candidates.append((open_idx, close_idx))
        if not candidates:
            return text
        # innermost = largest open index; breaking it shrinks any enclosing line
        open_idx, close_idx = max(candidates)
        text = _break_table(text, open_idx, close_idx)
