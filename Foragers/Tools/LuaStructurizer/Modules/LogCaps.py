import re

# Flags Log.write(...) / Log.error(...) message strings that "yell" in ALL CAPS.
# Project convention (see log.schema memory): log messages use normal case, e.g.
# "shader: %s", "entry missing required field 'sprite'". TextEmitter.lua used
# "FONT REQUIRE FAILED" / "FONT INSTANTIATE FAILED" — inconsistent with the rest.
#
# String contents are blanked in `stripped`, so this rule needs the original text
# (fed via set_original, mirroring the existing set_path hook). We locate the call
# line in `stripped` (code, not blanked) and read the same line index in `original`.

CALL_RE = re.compile(r"Log\.(?:write|error)\s*\(")
CAPS_WORD_RE = re.compile(r"\b[A-Z]{3,}\b")
COMMENT_RE = re.compile(r"--[^\n]*")

_original = None


def set_original(text):
    global _original
    _original = text


def check(stripped, path, config):
    if _original is None:
        return []
    findings = []
    orig_lines = _original.splitlines()
    stripped_lines = stripped.splitlines()
    for idx, sline in enumerate(stripped_lines):
        if not CALL_RE.search(sline):
            continue
        if idx >= len(orig_lines):
            continue
        # Drop the trailing -- comment so caps words inside a comment can't
        # false-positive a Log line. (Log messages in this project never contain
        # "--", so stripping it from the line is safe here.)
        oline = COMMENT_RE.sub("", orig_lines[idx])
        caps = CAPS_WORD_RE.findall(oline)
        if len(caps) >= 2:
            findings.append(
                (idx + 1, "Log message uses ALL-CAPS words (%s); use normal case for consistency" % ", ".join(caps), "warn")
            )
    return findings
