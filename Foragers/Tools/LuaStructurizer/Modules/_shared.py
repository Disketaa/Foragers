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
    # In Lua, `for`/`while` always carry a mandatory `do` on the same clause
    # (for i=1,n do / while x do). That `do` is part of the loop's own syntax,
    # not a separate block — counting it would open +2 for one block closed by
    # a single `end`, corrupting all downstream depth. Skip `do` when the line
    # also has `for`/`while`. Standalone `do ... end` blocks (no for/while) still
    # count as a real opener.
    kws = _BLOCK_KW.findall(line)
    has_loop = any(k in ("for", "while") for k in kws)
    delta = 0
    for kw in kws:
        if kw == "do" and has_loop:
            continue
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


# A function definition line. Used to bound scans to the enclosing function so
# module-scope checks don't false-positive on calls that live inside a function
# body. Matches `function NAME(...)`, `local function NAME(...)`, assigned
# functions `NAME = function(...)` (incl. table methods `handlers.build =
# function()`), and inline callbacks `foo(function() ... end)` — any line that
# opens a function block, so anonymous/table-valued/argument callbacks are still
# recognized as a function scope.
FUNC_START = re.compile(
    r"(?:"
    r"^\s*(?:local\s+)?function\s*[\w.:]*\s*\("
    r"|"
    r".*\bfunction\s*[\w.:]*\s*\("
    r")"
)


def _function_spans(lines):
    """Return list of (start, end) line indices for each top-level function."""
    spans = []
    i, n = 0, len(lines)
    while i < n:
        if FUNC_START.match(lines[i]):
            end = min(find_block_end(lines, i), n - 1)
            spans.append((i, end))
            i = end + 1
        else:
            i += 1
    return spans


def _enclosing_func(spans, idx):
    """Return the (start, end) span containing idx, or None if module scope."""
    for s, e in spans:
        if s <= idx <= e:
            return (s, e)
    return None
