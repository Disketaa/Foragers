import re

# Flags inline tuning literals that belong in Content/Data rather than code:
#   - `or <number>` fallback defaults (e.g. `data.smoothness or 0.02`)
#   - `= <float>` inline float assignments (e.g. `smoothness = 0.02`)
# Structural numbers (0, 1, 2, 0.0, 1.0, loop bounds) are ignored to limit noise.
# Scoped to include_folders (default Source/) so Content/ data files are not flagged.

OR_NUM = re.compile(r"\bor\s+(\d+\.\d+|\d+)\b")
ASSIGN_FLOAT = re.compile(r"(?<![=<>~:])=\s*(\d+\.\d+)\b")
IGNORE_OR = {"0", "1", "2", "nil"}
IGNORE_FLOAT = {"0.0", "1.0"}


def check(text, path, config):
    violations = []
    rcfg = config.get("Rules", {}).get("MagicNumbers", {})
    include = rcfg.get("include_folders", ["Source/"])
    proj = config.get("_project_root")
    rel = path.relative_to(proj).as_posix() if proj else str(path)
    if not any(rel.startswith(f) for f in include):
        return violations

    for m in OR_NUM.finditer(text):
        num = m.group(1)
        if num in IGNORE_OR:
            continue
        line = text[:m.start()].count("\n") + 1
        violations.append((line, f"magic fallback 'or {num}' — move tuning value to Content/Data", "warn"))

    for m in ASSIGN_FLOAT.finditer(text):
        num = m.group(1)
        if num in IGNORE_FLOAT:
            continue
        line = text[:m.start()].count("\n") + 1
        violations.append((line, f"inline float literal '= {num}' — move tuning value to Content/Data", "warn"))

    return violations
