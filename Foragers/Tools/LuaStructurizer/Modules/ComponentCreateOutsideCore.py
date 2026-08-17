import re

# Flags ComponentRegistry.create(...) outside the two files allowed to build/register
# components (ComponentRegistry.lua defines it, SpriteLoader.lua wires them from
# data). All other call sites must go through the loader. Mirrors the former
# verify-code Step 3 item 3 grep.

CREATE_RE = re.compile(r"ComponentRegistry\.create\s*\(")
ALLOWED = {"ComponentRegistry.lua", "SpriteLoader.lua"}


def check(text, path, config):
    violations = []
    if path.name in ALLOWED:
        return violations
    for m in CREATE_RE.finditer(text):
        line = text[:m.start()].count("\n") + 1
        violations.append((line, "ComponentRegistry.create(...) outside ComponentRegistry.lua/SpriteLoader.lua — use SpriteLoader", "error"))
    return violations
