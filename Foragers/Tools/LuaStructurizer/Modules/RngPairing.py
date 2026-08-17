import re
from _shared import find_block_end

# Flags RNG state save/restore imbalance inside a single function: a call to
# love.math.getRandomState() without a matching love.math.setRandomState() (or
# vice-versa) corrupts the global RNG seed on some exit path. Counts per function
# block; unequal counts = missing restore. Cheap approximation (not full path
# reachability) — catches the common "restore missing entirely" case.

GET = "love.math.getRandomState("
SET = "love.math.setRandomState("


def check(text, path, config):
    violations = []
    lines = text.split("\n")
    n = len(lines)
    i = 0
    while i < n:
        if re.match(r"\s*(local\s+)?function\b", lines[i]):
            start = i
            end = find_block_end(lines, i)
            end = min(end, len(lines) - 1)
            gets = 0
            sets = 0
            for j in range(start, end + 1):
                lj = lines[j]
                if GET in lj:
                    gets += 1
                if SET in lj:
                    sets += 1
            if (gets > 0 or sets > 0) and gets != sets:
                violations.append((start + 1, f"RNG state save/restore mismatch: getRandomState x{gets} vs setRandomState x{sets}", "error"))
            i = end + 1
            continue
        i += 1
    return violations
