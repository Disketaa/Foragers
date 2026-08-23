import re
from _shared import find_block_end, _line_block_delta, _function_spans, _enclosing_func

# Flags module-level mutable singletons: `local name = nil` at file scope whose
# mutation is SCATTERED across the module (real "hidden shared state" smell),
# not merely reassigned. A 1-2 function init/clear pair (Log.saveDir) or a
# struct reassigned from one call site (AttackSystem.attacker) is intentional
# module state, not the antipattern. Snapshot.lua (10 vars, 5+ funcs) is the
# target pattern this rule exists for.
#
# Also catches the namespaced variant: a private field on the module table
# (`ModName._field = ...`) reassigned inside 3+ functions. The bare `local x =
# nil` rule is blind to this because the state lives on the returned table, not
# a file-scope local. Only reassignment (`M._field = v`) inside functions counts;
# module-scope init (`M._field = {}`) and index mutation (`M._field[k] = v`,
# i.e. caching) are skipped to avoid false positives.

NIL_DECL = re.compile(r"^\s*local\s+([A-Za-z_]\w*)\s*=\s*nil\s*$")
ASSIGN = re.compile(r"(?<![\w.])([A-Za-z_]\w*)\s*=(?!=)")
FUNC_START = re.compile(r"^\s*(?:local\s+)?function\s+[\w.:]+\s*\(")

# Module table declaration: `local M = {}` / `local M = setmetatable(...)`.
MODULE_TABLE = re.compile(r"^\s*local\s+([A-Za-z_]\w*)\s*=\s*(?:setmetatable|\{)")
# Private field reassignment on a module table: `M._field = v` (underscore
# prefix filters out public method defs like `M.foo = function`).
NS_REASSIGN = re.compile(r"^\s*([A-Za-z_]\w*)\._([A-Za-z_]\w*)\s*=(?!=)")


def check(text, path, config):
    violations = []
    lines = text.split("\n")
    spans = _function_spans(lines)

    # --- bare `local x = nil` track (original rule) ---
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

    # --- namespaced singleton track (`ModName._field = ...` inside functions) ---
    module_tables = set()
    for idx, l in enumerate(lines):
        if _enclosing_func(spans, idx):
            continue
        m = MODULE_TABLE.match(l)
        if m:
            module_tables.add(m.group(1))

    per_field = {}  # field -> set of enclosing function indices
    for idx, l in enumerate(lines):
        m = NS_REASSIGN.match(l)
        if not m:
            continue
        mod = m.group(1)
        if mod not in module_tables:
            continue
        field = f"{mod}._{m.group(2)}"
        enc = _enclosing_func(spans, idx)
        if enc is None:
            continue  # module-scope init, not scattered mutation
        per_field.setdefault(field, set()).add(enc)

    for field, funcs in per_field.items():
        if len(funcs) >= 3:
            # Report at the module-scope declaration line if present, else first use.
            decl_idx = next((i for i, l in enumerate(lines)
                             if NS_REASSIGN.match(l) and l.strip().startswith(field)
                             and _enclosing_func(spans, i) is None), None)
            report_idx = decl_idx if decl_idx is not None else min(funcs)
            violations.append((report_idx + 1,
                f"module-table singleton '{field}' reassigned across {len(funcs)} functions — prefer an explicit state object",
                "warn"))

    return violations
