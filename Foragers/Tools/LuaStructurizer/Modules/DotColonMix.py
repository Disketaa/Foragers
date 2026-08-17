import re

# Flags call/definition convention mismatches for the same table method within one file.
# A method defined as `function T:method()` (instance, expects self) but invoked as
# `T.method(...)` (missing self) is a real bug; vice-versa passes an extra self.
# Only fires when both the definition and a conflicting call exist in the same file,
# which keeps false positives low (library calls like math.random are never defined here).

DEF_DOT = re.compile(r"function\s+([A-Za-z_]\w*)\.([A-Za-z_]\w*)\s*\(")
DEF_COLON = re.compile(r"function\s+([A-Za-z_]\w*):([A-Za-z_]\w*)\s*\(")
CALL_DOT = re.compile(r"([A-Za-z_]\w*)\.([A-Za-z_]\w*)\s*\(")
CALL_COLON = re.compile(r"([A-Za-z_]\w*):([A-Za-z_]\w*)\s*\(")


def check(text, path, config):
    violations = []
    static_defs = {(m.group(1), m.group(2)) for m in DEF_DOT.finditer(text)}
    instance_defs = {(m.group(1), m.group(2)) for m in DEF_COLON.finditer(text)}

    for m in CALL_COLON.finditer(text):
        tbl, meth = m.group(1), m.group(2)
        if (tbl, meth) in static_defs and meth != "new":
            line = text[:m.start()].count("\n") + 1
            violations.append((line, f"{tbl}:{meth}(...) called with colon but defined static as {tbl}.{meth} (extra self arg)", "warn"))

    for m in CALL_DOT.finditer(text):
        tbl, meth = m.group(1), m.group(2)
        if (tbl, meth) in instance_defs:
            line = text[:m.start()].count("\n") + 1
            violations.append((line, f"{tbl}.{meth}(...) called with dot but defined instance as {tbl}:{meth} (missing self)", "warn"))

    return violations
