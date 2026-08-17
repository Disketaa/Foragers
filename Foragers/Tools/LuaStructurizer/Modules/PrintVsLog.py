import re

# Flags raw print() calls. Project logging API is Log.write(...) / Log.error(...).
# Debug-only files (anything under a "Debug" directory, or listed in allow_files) are skipped.

PRINT_RE = re.compile(r"(?<![\w.])print\s*\(")


def check(text, path, config):
    violations = []
    rcfg = config.get("Rules", {}).get("PrintVsLog", {})
    allow_files = set(rcfg.get("allow_files", []))
    name = path.name
    if name in allow_files:
        return violations
    if any(part == "Debug" for part in path.parts):
        return violations

    for m in PRINT_RE.finditer(text):
        line_start = text.rfind("\n", 0, m.start()) + 1
        line_text = text[line_start:m.start()]
        if "structure:allow-print" in line_text:
            continue
        line = text[:m.start()].count("\n") + 1
        violations.append((line, "print() used; use Log.write(...) or Log.error(...) instead", "error"))
    return violations
