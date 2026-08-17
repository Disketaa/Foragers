import re
from pathlib import Path
from _shared import find_block_end

# Cross-component single-writer enforcement. Reads FieldOwnership.toml,
# a hand-maintained manifest mapping a field -> owning component. Flags:
#   - writes to parent.<field> / self.parent.<field> (cross-component write)
#   - reads of parent.<field> / self.parent.<field> inside any update() function (single-writer violation)
# Disabled by default in Settings.toml until the manifest is seeded.

MANIFEST = Path(__file__).resolve().parent.parent / "FieldOwnership.toml"


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
    stem = Path(path).stem
    lines = text.split("\n")
    n = len(lines)
    i = 0
    while i < n:
        if re.match(r"\s*(local\s+)?function\s+[\w.:]*update\b", lines[i]):
            start = i
            end = find_block_end(lines, i)
            end = min(end, len(lines) - 1)
            for field, cfg in manifest.items():
                owner = cfg.get("owner", "?")
                if stem == owner:
                    continue
                wre = re.compile(r"(?:self\.parent|parent)\." + re.escape(field) + r"\s*=")
                rre = re.compile(r"(?:self\.parent|parent)\." + re.escape(field) + r"\b")
                for j in range(start, end + 1):
                    if wre.search(lines[j]):
                        violations.append((j + 1, f"field '{field}' (owner '{owner}') written via parent — cross-component write", "error"))
                    elif rre.search(lines[j]):
                        violations.append((j + 1, f"field '{field}' (owner '{owner}') read inside update() — single-writer rule", "error"))
            i = end + 1
            continue
        i += 1
    return violations
