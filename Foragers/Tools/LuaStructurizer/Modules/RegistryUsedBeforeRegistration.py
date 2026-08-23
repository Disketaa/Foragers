import re
from _shared import _function_spans, _enclosing_func  # promoted from ModuleSingleton

# Flags ValueParser.table(...) called at module top-level scope (outside any
# function). ValueParser routes the "text" key through a handler registered at
# boot (love.load); a top-level ValueParser.table() call parses before that
# handler exists and silently degrades (raw string kept, no localization). The
# ValueParser doc contract forbids calling ValueParser.table at module scope.
#
# Opt-out: a line containing "structure:allow-registry" (e.g. in a trailing
# comment) is skipped. The token is read from the un-blanked original because
# Structurizer strips comment contents from `text`.

TABLE_CALL = re.compile(r"\bValueParser\.table\s*\(")
ALLOW_TOKEN = "structure:allow-registry"

_original_lines = None


def set_original(original):
    global _original_lines
    _original_lines = original.split("\n")


def check(text, path, config):
    violations = []
    lines = text.split("\n")
    # Guard against global-state desync: only trust the cached original when its
    # line count matches the stripped text (Structurizer always calls
    # set_original per file, but fall back to `lines` if they ever diverge).
    orig_lines = _original_lines if (_original_lines and len(_original_lines) == len(lines)) else lines
    spans = _function_spans(lines)
    for i, line in enumerate(lines):
        if not TABLE_CALL.search(line):
            continue
        if ALLOW_TOKEN in orig_lines[i]:
            continue
        if not _enclosing_func(spans, i):
            violations.append((
                i + 1,
                "ValueParser.table() called at module scope — handlers may not be registered yet",
                "error",
            ))
    return violations
