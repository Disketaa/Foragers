import re

# Flags module-level mutable singletons: `local name = nil` at file scope that is
# later reassigned from multiple sites. Hidden cross-function state via closure,
# no ownership marker (the terrainBatch pattern from WorldBuilder.lua).

NIL_DECL = re.compile(r"^\s*local\s+([A-Za-z_]\w*)\s*=\s*nil\s*$")
ASSIGN = re.compile(r"(?<![\w.])([A-Za-z_]\w*)\s*=(?!=)")


def check(text, path, config):
    violations = []
    lines = text.split("\n")
    for idx, line in enumerate(lines):
        m = NIL_DECL.match(line)
        if not m:
            continue
        name = m.group(1)
        count = 0
        for j in range(idx + 1, len(lines)):
            lj = lines[j]
            if lj.lstrip().startswith(f"local {name} ="):
                continue
            am = ASSIGN.search(lj)
            if am and am.group(1) == name:
                count += 1
        if count >= 2:
            violations.append((idx + 1, f"module-level singleton '{name}' (local = nil) reassigned {count}x — prefer an explicit state object", "warn"))
    return violations
