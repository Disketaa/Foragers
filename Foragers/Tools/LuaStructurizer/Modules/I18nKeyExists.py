import re
from pathlib import Path

# Flags `{ key = "card.durability" }` references whose key is absent from the
# canonical English.lua table. A typo'd key silently falls back to the raw key
# in production (I18n.lookup returns the key itself when missing), so a missing
# key is a real localization bug, not just a cosmetic gap.
#
# The canonical translatable form is `text = { key = "..." }` (resolved by
# TextParser). We match that exact form rather than a bare `key = "..."` because
# other tables use `key = "..."` for unrelated purposes (e.g. Debug.lua menu
# entries, ShaderLoader cache keys) and would false-positive.
#
# The structurizer blanks string contents in the `text` passed to check(), so the
# key value is invisible there. We use the set_original() hook to receive the raw
# source and run the key scan against it (mirrors FilePathSlash). Comment lines
# are skipped so doc-comment examples don't false-positive.

KEY_REF = re.compile(r'text\s*=\s*\{\s*key\s*=\s*["\']([\w.]+)["\']')
ENGLISH_KEYS_RE = re.compile(r'\[["\']([\w.]+)["\']\]\s*=')
# `--[[ ... ]]` block-comment spans (so keys inside them aren't flagged).
_BLOCK_COMMENT = re.compile(r'--\[(=*)\[.*?\]\1\]', re.DOTALL)

_keys_cache = None  # None = not loaded yet; set() = loaded (possibly empty)
_original = ""


def set_original(text: str) -> None:
    global _original
    _original = text


def _load_english_keys(config):
    global _keys_cache
    if _keys_cache is not None:
        return _keys_cache
    root = config.get("_project_root")
    if root is None:
        _keys_cache = set()
        return _keys_cache
    path = Path(root) / "Content" / "Data" / "I18n" / "English.lua"
    try:
        src = path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        # Can't validate without the canonical table — skip rather than flag
        # every key as missing (which would be a mass false error).
        _keys_cache = set()
        return _keys_cache
    _keys_cache = set(ENGLISH_KEYS_RE.findall(src))
    return _keys_cache


def check(text, path, config):
    global _original
    raw = _original
    _original = ""  # consume to avoid stale state across files

    # Don't self-check the language files (their keys ARE the canonical set).
    norm = str(path).replace("\\", "/")
    if "Content/Data/I18n" in norm:
        return []

    valid = _load_english_keys(config)
    if not valid:
        # English.lua missing/unreadable — cannot validate; skip to avoid
        # flagging every key as a false error.
        return []

    if not raw:
        return []

    # Block-comment (`--[[ ... ]]`) spans — matches inside them are doc/examples.
    block_spans = [(b.start(), b.end()) for b in _BLOCK_COMMENT.finditer(raw)]

    violations = []
    for m in KEY_REF.finditer(raw):
        pos = m.start()
        # Skip if inside a `--[[ ... ]]` block comment.
        if any(s <= pos < e for s, e in block_spans):
            continue
        # Skip if the match sits inside a `--` line comment (before it on its line).
        line_start = raw.rfind("\n", 0, pos) + 1
        line_end = raw.find("\n", pos)
        if line_end == -1:
            line_end = len(raw)
        before = raw[line_start:pos]
        if "--" in before:
            continue
        key = m.group(1)
        if key not in valid:
            line = raw[: m.start()].count("\n") + 1
            violations.append((
                line,
                f"i18n key '{key}' is not defined in English.lua (typo? missing entry?)",
                "error",
            ))
    return violations
