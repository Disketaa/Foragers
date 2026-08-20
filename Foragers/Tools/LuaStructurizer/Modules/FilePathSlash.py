import re

# Flags dot-separated Content-relative paths used where forward slashes are required.
# In this project, filesystem paths (particle, replaceWith, types, etc.) MUST use
# forward slashes because Path.png() passes them to love.filesystem.
#
# Dots are correct only in these patterns (all passed to Lua require()):
#   require("Content.Data.World")
#   extends = "Content.Assets.Sprites.Props.__Props"
#   data = "Content.Assets.Sprites.Props.Bush"
#   font = "Content.Assets.Sprites.UI.SpriteFonts.X"
#   Path.moduleToPath("Content.Assets.Sprites.Tiles.X")

# Match both single and double-quoted dot paths
_DOT_PATH = re.compile(r'["\']Content\.(?:Assets|Data|Helpers|Mods|Source)\.[A-Za-z_]\w*')
_EXEMPT_LINE = re.compile(r'\b(?:require\(|extends\s*=\s*|data\s*=\s*|Path\.moduleToPath\()')
_HAS_FONT_REF = re.compile(r'\bfont\b')
_COMMENT_LINE = re.compile(r'^\s*--')

_original = ""


def set_original(text: str) -> None:
    global _original
    _original = text


def _find_closing_quote(text: str, start: int) -> int:
    """Find matching unescaped closing quote starting after position start."""
    quote_char = text[start - 1] if start > 0 else '"'
    i = start
    while i < len(text):
        if text[i] == "\\" and i + 1 < len(text):
            # Escaped char — skip the backslash and the following char
            i += 2
            continue
        if text[i] == quote_char and text[i - 1] != "\\":
            return i
        i += 1
    return len(text)


def _get_line_at(text: str, pos: int) -> str:
    line_start = text.rfind("\n", 0, pos)
    if line_start == -1:
        line_start = 0
    else:
        line_start += 1
    line_end = text.find("\n", pos)
    if line_end == -1:
        line_end = len(text)
    return text[line_start:line_end]


def check(text, path, config) -> list:
    global _original
    # Consume immediately to prevent stale state between files
    raw_text = _original
    _original = ""

    violations = []
    if not raw_text:
        return violations

    for m in _DOT_PATH.finditer(raw_text):
        pos = m.start()
        line_num = raw_text[:pos].count("\n") + 1
        line_text = _get_line_at(raw_text, pos)

        # Skip if the path is inside a comment
        comment_pos = line_text.find("--")
        if comment_pos != -1 and comment_pos < (pos - raw_text.rfind("\n", 0, pos) - 1 if pos > 0 else pos):
            continue

        # Skip exempt require/extends/data/moduleToPath patterns
        if _EXEMPT_LINE.search(line_text):
            continue

        # Skip font references (require-fed)
        if _HAS_FONT_REF.search(line_text):
            continue

        end = _find_closing_quote(raw_text, m.end())
        full_string = raw_text[m.start() + 1:end]

        violations.append((
            line_num,
            f"path uses dots where slashes needed: \"{full_string}\". Use forward slashes like \"Content/Assets/...\"",
            "error",
        ))

    return violations