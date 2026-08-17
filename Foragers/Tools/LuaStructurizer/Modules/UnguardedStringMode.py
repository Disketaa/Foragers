import re
from _shared import find_block_end, _line_block_delta

# Flags string-mode comparison chains (if x == "a" elseif x == "b" ... else) whose
# final else branch has no error/assert/Log guard. An unvalidated mode that falls
# through silently (typo'd mode string) is exactly the Canvas.lua "inner"/"outer" risk.

STR_CMP = re.compile(r'==\s*"')
GUARD = re.compile(r"\b(error|assert|Log\.error|Log\.write)\b")
# Type-dispatch (type(x) == "string") is not a string-mode enum; skip it.
TYPE_CHECK = re.compile(r"\b(?:type|typeof)\s*\(")
# A single `if x == "a" ... else` is a binary structural split (exhaustive
# catch-all), not an unvalidated mode enum. Only flag chains with 2+
# elseif-branches doing string compares — real multi-way enums (3+ named
# states), where a typo'd 4th value silently falls into the wrong bucket.
ELSEIF_STR_CMP = re.compile(r"^\s*elseif\b.*==\s*\"")


def check(text, path, config):
    violations = []
    lines = text.split("\n")
    n = len(lines)
    i = 0
    while i < n:
        line = lines[i]
        if re.search(r"\bif\b", line) and STR_CMP.search(line) and not TYPE_CHECK.search(line):
            end = find_block_end(lines, i)
            end = min(end, len(lines) - 1)
            # Track depth with the shared keyword set (if/for/while/do/repeat/
            # function all open, end/until close) so a loop nested inside a
            # branch no longer invisibly corrupts the else-detection. elseif/else
            # are depth-neutral. Record the else only at the outer if's level.
            nest = 0
            else_line = -1
            elseif_branches = 0
            for k in range(i, end + 1):
                lk = lines[k]
                nest += _line_block_delta(lk)
                if nest == 1 and ELSEIF_STR_CMP.match(lk):
                    elseif_branches += 1
                if nest == 1 and re.match(r"\s*else\b", lk):
                    else_line = k
                if nest <= 0:
                    break
            if else_line != -1 and elseif_branches >= 2:
                body = "\n".join(lines[else_line + 1:end])
                if body.strip() and not GUARD.search(body):
                    violations.append((else_line + 1, "string-mode 'else' branch has no error/assert/Log guard — unvalidated mode falls through silently", "warn"))
            i = end + 1
            continue
        i += 1
    return violations
