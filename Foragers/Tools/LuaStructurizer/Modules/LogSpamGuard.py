import re
from _shared import _function_spans

# Heuristic: flags Log.write/Log.error calls that live inside a per-frame
# function (named update/draw/tick) without a nearby dedupe guard. A log with no
# guard inside a per-frame function spams the log every frame.
#
# This is intentionally a WARN (not error): it's heuristic and has moderate
# false-positive risk. Legit one-shot logs guarded by external state (e.g. an
# xpcall `if not ok then ... _broken = true` that stops re-entry) may still be
# flagged; triage hits rather than treat them as hard failures.
#
# A "guard" is detected as either a `_warned` reference or an `if not <var>`
# one-shot guard anywhere in the enclosing per-frame function (broadened from the
# plan's `if not <var>[` so xpcall-style `if not ok then` guards also count).
# Scanning the whole function (not just a few lines above the call) avoids
# missing a dedupe flag declared earlier in a long update/draw loop.

HOT_NAME = re.compile(r"\b(update|draw|tick)\b", re.I)
LOG_CALL = re.compile(r"\bLog\.(write|error)\s*\(")
GUARD = re.compile(r"(?:_warned|if\s+not\s+\w+)", re.I)


def check(text, path, config):
    violations = []
    lines = text.split("\n")
    spans = _function_spans(lines)
    for (s, e) in spans:
        # Only per-frame functions are interesting.
        if not HOT_NAME.search(lines[s]):
            continue
        # One dedupe guard anywhere in the function protects every Log call in it.
        func_has_guard = any(GUARD.search(lines[j]) for j in range(s, e + 1))
        if func_has_guard:
            continue
        for i in range(s, e + 1):
            if LOG_CALL.search(lines[i]):
                violations.append((
                    i + 1,
                    "Log.write/error inside per-frame function (update/draw/tick) "
                    "without a dedupe guard — risk of per-frame log spam",
                    "warn",
                ))
    return violations
