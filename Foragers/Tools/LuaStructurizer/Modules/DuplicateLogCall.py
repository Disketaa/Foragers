import re

# Flags duplicate Log.error/Log.write calls within one file that share the same
# tag (1st arg) and format string (2nd arg). Two copies of one error message
# drift apart on future edits. Flag-only: suggests extracting the call into a
# local helper.
#
# String literals are blanked in `text` (see Structurizer.strip_comments_and_strings),
# so call SITES are found in `text` (real code only — comments/strings are blanked)
# but the tag/fmt are read from the un-blanked `original` via set_original(). The two
# texts are length-aligned, so offsets map 1:1. ARG_RE is anchored with match() at the
# call site so a later call in the same slice can't be mis-attributed to this one.

CALL_RE = re.compile(r'Log\.(error|write)\s*\(')
# A Lua short string: ' or " delimited, escapes allowed, the opposite quote is
# permitted inside the content. Group 3 = tag, group 5 = fmt; \2 / \4 close the
# respective quotes. (Backreferences must point at the quote groups, not \1 which
# would be the method-name group.)
ARG_RE = re.compile(
    r'Log\.(error|write)\s*\(\s*'
    r'(["\'])((?:\\.|[^\n\\])*?)\2'
    r'\s*,\s*'
    r'(["\'])((?:\\.|[^\n\\])*?)\4'
)

# A format that is only conversion specs plus units (e.g. "%-30s %8.1fms") is a
# shared measurement template, not a copy-pasted message; duplicates of it don't
# drift apart, so they shouldn't trip the rule. Real messages ("Failed to load
# sound: %s") keep literal words after specs are stripped and still flag.
# Matches the Lua printf grammar (optional -, width, .precision, conversion char)
# rather than a loose char blob — note: a dash inside a class forms a range, so it
# must sit at the class edge (here it's the literal flag, outside any []).
_SPEC = re.compile(r"%-?\d*\.?\d*[sdfxcge]")


def _is_template(fmt: str) -> bool:
    stripped = _SPEC.sub("", fmt)
    stripped = re.sub(r"\bms\b", "", stripped, flags=re.IGNORECASE)
    return not re.search(r"[A-Za-z]{2,}", stripped)


_original = ""


def set_original(text):
    global _original
    _original = text


def check(text, path, config):
    src = _original if _original else text
    calls = {}  # (tag, fmt) -> [line, ...]
    for m in CALL_RE.finditer(text):
        start = m.start()
        mm = ARG_RE.match(src, start)
        if not mm:
            continue
        tag, fmt = mm.group(3), mm.group(5)
        if _is_template(fmt):
            continue
        line = text[:start].count("\n") + 1
        calls.setdefault((tag, fmt), []).append(line)
    violations = []
    for (tag, fmt), lines in calls.items():
        if len(lines) >= 2:
            for ln in lines[1:]:
                violations.append((ln, f"duplicate Log call (tag='{tag}') also at line {lines[0]}; extract to a helper", "warn"))
    return violations
