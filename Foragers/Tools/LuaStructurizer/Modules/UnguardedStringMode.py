import re

# Flags string-mode comparison chains (if x == "a" elseif x == "b" ... else) whose
# final else branch has no error/assert/Log guard. An unvalidated mode that falls
# through silently (typo'd mode string) is exactly the Canvas.lua "inner"/"outer" risk.

STR_CMP = re.compile(r'==\s*"')
GUARD = re.compile(r"\b(error|assert|Log\.error|Log\.write)\b")
# Type-dispatch (type(x) == "string") is not a string-mode enum; skip it.
TYPE_CHECK = re.compile(r"\b(?:type|typeof)\s*\(")


def check(text, path, config):
    violations = []
    lines = text.split("\n")
    n = len(lines)
    i = 0
    while i < n:
        line = lines[i]
        if re.search(r"\bif\b", line) and STR_CMP.search(line) and not TYPE_CHECK.search(line):
            nest = 0
            k = i
            else_line = -1
            end_line = -1
            while k < n:
                lk = lines[k]
                if re.match(r"\s*if\b", lk):
                    nest += 1
                elif re.match(r"\s*elseif\b", lk):
                    pass
                elif re.match(r"\s*else\b", lk):
                    if nest == 1:
                        else_line = k
                elif re.match(r"\s*end\b", lk):
                    nest -= 1
                    if nest == 0:
                        end_line = k
                        break
                k += 1

            if else_line != -1 and end_line != -1:
                body = "\n".join(lines[else_line + 1:end_line])
                if body.strip() and not GUARD.search(body):
                    violations.append((else_line + 1, "string-mode 'else' branch has no error/assert/Log guard — unvalidated mode falls through silently", "warn"))
                i = end_line + 1
                continue
            i = k + 1
            continue
        i += 1
    return violations
