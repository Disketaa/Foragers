import re

# Block-depth keywords for Lua. Used to bound a scan to the block that opens at a
# given line so inner if/for/while/do/repeat blocks don't prematurely close the
# scan window. Operates on comment/string-stripped text (see
# Structurizer.strip_comments_and_strings) so keywords inside strings/comments
# never perturb the count.
_BLOCK_KW = re.compile(r"\b(if|for|while|function|do|repeat|end|until)\b")
_OPEN_KW = re.compile(r"\b(if|for|while|function|do|repeat)\b")
_OPENS = {"if", "for", "while", "function", "do", "repeat"}


def _line_block_delta(line: str) -> int:
    delta = 0
    for kw in _BLOCK_KW.findall(line):
        delta += 1 if kw in _OPENS else -1
    return delta


def _has_open(line: str) -> bool:
    return bool(_OPEN_KW.search(line))


def find_block_end(lines, start):
    """Return the index of the line closing the block that opens at lines[start].

    Returns len(lines) if unterminated. Handles single-line blocks
    (e.g. `function f() end`) and arbitrary nesting.
    """
    n = len(lines)
    nest = 0
    i = start
    while i < n:
        delta = _line_block_delta(lines[i])
        nest += delta
        if i == start:
            if nest <= 0 and _has_open(lines[i]):
                return i
            i += 1
            continue
        if nest <= 0:
            return i
        i += 1
    return n
