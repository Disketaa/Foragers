import re

# Flags `local ok, X = pcall(require, ...)` whose success flag (`ok`) is never
# referenced again. A require that fails silently (ok never checked) degrades to
# a nil/error-value crash later instead of a logged load failure.
#
# The project guards either with the negative form (`if not ok then ...`) OR the
# positive short-circuit form (`if ok and data then ...` — a failed require
# short-circuits and the data is simply skipped). Both consume the `ok` flag, so
# we treat "ok referenced again anywhere below the pcall" as guarded. Scanning
# the whole file (no fixed window) avoids false positives when the check sits
# far below the require in a long init module.

PCALL_REQ = re.compile(r"local\s+(\w+)\s*,\s*(\w+)\s*=\s*pcall\(\s*require\s*,")


def check(text, path, config):
    violations = []
    rcfg = config.get("Rules", {}).get("UnguardedPcallRequire", {})
    allow_files = set(rcfg.get("allow_files", []))
    name = path.name
    if name in allow_files:
        return violations
    if any(part == "Debug" for part in path.parts):
        return violations

    lines = text.split("\n")
    for m in PCALL_REQ.finditer(text):
        ok_var = m.group(1)
        pcall_line = text[: m.start()].count("\n")
        guarded = False
        for idx in range(pcall_line + 1, len(lines)):
            # Negative lookbehind for . and : so `self.ok` / `data.ok` field
            # accesses don't satisfy the guard (they aren't checking the pcall
            # result). The harness already strips comments/strings, so a
            # `-- check ok` comment can't false-positive either.
            if re.search(rf"(?<![.:])\b{re.escape(ok_var)}\b", lines[idx]):
                guarded = True
                break
        if not guarded:
            violations.append((
                pcall_line + 1,
                f"pcall(require, ...) success flag '{ok_var}' is never checked "
                f"— a failed require fails silently",
                "warn",
            ))
    return violations
