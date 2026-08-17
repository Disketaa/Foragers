import re

# Flags Sprite.new(...) calls outside the two files allowed to instantiate sprites
# (Sprite.lua defines the class, SpriteLoader.lua builds them from data via
# instantiate()). All other call sites must go through the loader. Mirrors the
# former verify-code Step 3 item 2 grep.

NEW_RE = re.compile(r"Sprite\.new\s*\(")
ALLOWED = {"Sprite.lua", "SpriteLoader.lua"}


def check(text, path, config):
    violations = []
    if path.name in ALLOWED:
        return violations
    for m in NEW_RE.finditer(text):
        line = text[:m.start()].count("\n") + 1
        violations.append((line, "Sprite.new(...) outside Sprite.lua/SpriteLoader.lua — use SpriteLoader.instantiate()", "error"))
    return violations
