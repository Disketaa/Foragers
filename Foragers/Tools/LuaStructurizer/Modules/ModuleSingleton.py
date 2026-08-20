import re
from _shared import find_block_end, _line_block_delta

# Flags module-level mutable singletons: `local name = nil` at file scope whose
# mutation is SCATTERED across the module (real "hidden shared state" smell),
# not merely reassigned. A 1-2 function init/clear pair (Log.saveDir) or a
# struct reassigned from one call site (AttackSystem.attacker) is intentional
# module state, not the antipattern. Snapshot.lua (10 vars, 5+ funcs) is the
# target pattern this rule exists for.

NIL_DECL = re.compile(r"^\s*local\s+([A-Za-z_]\w*)\s*=\s*nil\s*$")
ASSIGN = re.compile(r"(?<![\w.])([A-Za-z_]\w*)\s*=(?!=)")
FUNC_START = re.compile(r"^\s*(?:local\s+)?function\s+[\w.:]+\s*\(")


def _function_spans(lines):
    spans = []
    i, n = 0, len(lines)
    while i < n:
        if FUNC_START.match(lines[i]):
            end = min(find_block_end(lines, i), n - 1)
            spans.append((i, end))
            i = end + 1
        else:
            i += 1
    return spans


def _enclosing_func(spans, idx):
    for s, e in spans:
        if s <= idx <= e:
            return (s, e)
    return None


def check(text, path, config):
    violations = []
    lines = text.split("\n")
    spans = _function_spans(lines)

    decls = [(idx, m.group(1)) for idx, l in enumerate(lines) if (m := NIL_DECL.match(l))]

    per_var = {}
    for idx, name in decls:
        funcs = set()
        for j in range(idx + 1, len(lines)):
            lj = lines[j]
            if lj.lstrip().startswith(f"local {name} ="):
                continue
            am = ASSIGN.search(lj)
            if am and am.group(1) == name:
                enc = _enclosing_func(spans, j)
                if enc:
                    funcs.add(enc)
        per_var[name] = (idx, funcs)

    # (b) single var mutated by 3+ distinct functions
    flagged = set()
    for name, (idx, funcs) in per_var.items():
        if len(funcs) >= 3:
            violations.append((idx + 1, f"module-level singleton '{name}' reassigned across {len(funcs)} functions — prefer an explicit state object", "warn"))
            flagged.add(name)

    # (a) 3+ vars co-mutated by overlapping functions
    groups = []
    for name, (idx, funcs) in per_var.items():
        if name in flagged or not funcs:
            continue
        target = next((g for g in groups if g["funcs"] & funcs), None)
        if target:
            target["names"].add(name)
            target["funcs"] |= funcs
        else:
            groups.append({"names": {name}, "funcs": set(funcs)})
    for g in groups:
        if len(g["names"]) >= 3 and len(g["funcs"]) >= 2:
            first_idx = min(per_var[n][0] for n in g["names"])
            violations.append((first_idx + 1, f"module-level singletons {sorted(g['names'])} co-mutated across overlapping functions — prefer an explicit state object", "warn"))

    return violations
