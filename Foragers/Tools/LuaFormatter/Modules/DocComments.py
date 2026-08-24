import re
import sys

# A LuaLS / EmmyLua annotation written with only two dashes (`--@tag`).
# LuaLS requires three dashes (`---@tag`); two dashes makes the tooling
# treat it as a plain comment and silently drop the type info.
_ANNOTATION_FIX = re.compile(r"^(\s*)--@")
# A horizontal divider like `----------------` (not a doc comment).
_DIVIDER = re.compile(r"^--[-]+$")
# Declaration lines a `---` doc comment may legitimately precede.
_DECL = re.compile(
    r"^\s*(local\s+function|function\b|"
    r"\w[\w.]*\s*=\s*function|"
    r"\w[\w.]*\s*=\s*\{|"
    r"local\s+\w[\w.]*\s*=|"
    r"local\s+[\w\s,.]+\s*=|"
    r"return\b|\[\[)"
)


def _is_doc_line(line: str) -> bool:
    s = line.rstrip("\r\n")
    stripped = s.lstrip()
    if _DIVIDER.match(stripped):
        return False
    return stripped.startswith("---")


def apply(text: str, config: dict) -> str:
    lines = text.split("\n")
    out = []

    for line in lines:
        m = _ANNOTATION_FIX.match(line)
        if m:
            # `--@tag` -> `---@tag`: keep leading whitespace, add one dash.
            ws_end = m.end(1)
            line = line[:ws_end] + "---" + line[ws_end + 2:]
        out.append(line)

    if config.get("warn_misused_doc_comments", False):
        _warn_misused(out)

    return "\n".join(out)


def _warn_misused(lines: list[str]) -> None:
    """Opt-in: flag `---` blocks that carry no annotation and are not
    attached to a declaration. Such blocks should usually be `--` notes."""
    n = len(lines)
    i = 0
    while i < n:
        if _is_doc_line(lines[i]):
            j = i
            while j < n and _is_doc_line(lines[j]):
                j += 1
            block = "\n".join(lines[i:j])
            if "@" not in block:
                k = j
                while k < n and lines[k].strip() == "":
                    k += 1
                if k < n and not _DECL.match(lines[k]):
                    print(
                        f"DocComment: '---' block without annotation, "
                        f"not above a declaration (line {i + 1})",
                        file=sys.stderr,
                    )
            i = j
        else:
            i += 1
