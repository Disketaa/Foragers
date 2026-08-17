import re
from pathlib import Path

# Cross-component single-writer enforcement. Reads Tools/StructureRules/field_ownership.toml,
# a hand-maintained manifest mapping a field -> owning component. Flags:
#   - writes to parent.<field> / self.parent.<field> (cross-component write)
#   - reads of .<field> inside any update() function (single-writer violation)
# Disabled by default in StructureRules.toml until the manifest is seeded.

MANIFEST = Path(__file__).resolve().parent / "field_ownership.toml"


def _load_manifest():
    if not MANIFEST.is_file():
        return {}
    try:
        import tomllib
        return tomllib.loads(MANIFEST.read_text(encoding="utf-8"))
    except Exception:
        return {}


def check(text, path, config):
    violations = []
    manifest = _load_manifest()
    if not manifest:
        return violations

    lines = text.split("\n")
    for field, cfg in manifest.items():
        owner = cfg.get("owner", "?")
        wre = re.compile(r"(?:self\.parent|parent)\." + re.escape(field) + r"\s*=")
        for li, line in enumerate(lines):
            if wre.search(line):
                violations.append((li + 1, f"field '{field}' (owner '{owner}') written via parent — cross-component write", "error"))

        rre = re.compile(r"(?<!\.)\." + re.escape(field) + r"\b")
        n = len(lines)
        i = 0
        while i < n:
            if re.match(r"\s*(local\s+)?function\s+[\w.:]*update\b", lines[i]):
                nest = 0
                j = i
                while j < n:
                    lj = lines[j]
                    if re.match(r"\s*(local\s+)?function\b", lj):
                        nest += 1
                    elif re.match(r"\s*end\b", lj):
                        nest -= 1
                        if nest == 0:
                            break
                    if rre.search(lj):
                        violations.append((j + 1, f"field '{field}' (owner '{owner}') read inside update() — single-writer rule", "error"))
                    j += 1
                i = j + 1
                continue
            i += 1
    return violations
