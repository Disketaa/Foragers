import re

# Flags `local function scan` definitions outside Path.lua. The project's shared
# directory-walk helper is Path.scanDirectory; local reimplementations duplicate
# it (and skip its exclusions). Mirrors the former verify-code Step 3 item 12 grep.

SCAN_RE = re.compile(r"local\s+function\s+scan\b")
ALLOWED = {"Path.lua"}


def check(text, path, config):
    violations = []
    if path.name in ALLOWED:
        return violations
    for m in SCAN_RE.finditer(text):
        line = text[:m.start()].count("\n") + 1
        violations.append((line, "local function scan defined outside Path.lua — use Path.scanDirectory", "error"))
    return violations
