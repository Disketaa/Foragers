import re

# Enforces the project's component-construction convention: the `type` field must
# live inside the setmetatable({...}, X) table literal (as its last key), not as a
# separate `self.type = "..."` assignment after the metatable is built. 4 of 5
# component files use the in-literal form; Sound.lua is the lone divergence.
# Flags the offending `self.type =` write so it can be hoisted into the literal.
#
# Gating keeps false positives low: a setmetatable literal that lacks a `type`
# key is only flagged when the same file also assigns `self.type = "..."`
# outside it. Plain Tween objects (Tween.new) have no type field and no
# self.type assignment, so they stay silent. Reads like `self.type == "..."`
# don't match the assignment regex.

_SETMETA = re.compile(r"setmetatable\s*\(")
_TYPE_ASSIGN = re.compile(r"self\.type\s*=\s*\"[^\"]*\"")
_TYPE_KEY = re.compile(r"type\s*=\s*\"[^\"]*\"")


def _find_literal_close(text, open_idx):
    # open_idx points at the opening '{'. Return index of the matching '}' or -1.
    # Brace counting ignores string/comment content (already blanked upstream).
    depth = 0
    i = open_idx
    n = len(text)
    while i < n:
        c = text[i]
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
            if depth == 0:
                return i
        i += 1
    return -1


def check(text, path, config):
    violations = []
    for m in _SETMETA.finditer(text):
        i = text.find("{", m.end())
        if i == -1:
            continue
        close = _find_literal_close(text, i)
        if close == -1:
            continue
        literal = text[i:close + 1]
        if _TYPE_KEY.search(literal):
            continue  # type already in literal — canonical form, OK
        # Literal lacks a type key: flag a self.type = "..." assignment if present.
        am = _TYPE_ASSIGN.search(text)
        if am:
            line = text[:am.start()].count("\n") + 1
            violations.append((
                line,
                "type set via `self.type = \"...\"` outside setmetatable literal; "
                "hoist into the literal as its last key",
                "warn",
            ))
            break  # one report per file is enough
    return violations
