---
description: Guide for fixing a single metrics violation in Foragers
---

## Before you start

1. Read `.kilo/AGENTS.md` — architecture rules, component system, event system, error handling
2. Read the flagged file and the exact function/region mentioned in the violation
3. Check `.kilo/documentation/` for LÖVE2D API docs if the fix touches engine calls

## Fixing one violation

### 1. Identify the violation type
- **LuaMetrics CC>20** — erosion: function too complex
- **LuaMetrics CC>10** — complexity warning
- **LuaMetrics clone** — duplicated code block

### 2. Choose the fix

| Violation | Fix |
|---|---|
| CC>20 | Extract logic into a helper function; reduce branches |
| CC>10 | Simplify conditionals, extract helper |
| Clone | Extract shared code into a helper; call from both sites |

### 3. Apply the fix

- One file, one region, one violation at a time
- Do not batch multiple fixes in one edit
- Do not refactor beyond the scope of this violation
- Do not touch Section I constraints (event system, single-writer rule, component boundaries) — if the fix requires that, stop and flag for manual review

### 4. Verify

- Run the specific gate that reported the violation
- If the violation is gone and no new violations appeared — done
- If the fix is blocked by architecture — emit `REVIEW REQUIRED` instead of forcing it

## Output format

After fixing, report:

```
file:line:col - rule_name: FIXED — what was done
```

If blocked:

```
file:line:col - rule_name: REVIEW REQUIRED — architectural change needed
```

## Reference

- `.kilo/AGENTS.md` — full architecture, component rules, event system, error handling
- `.kilo/documentation/components.md` — component config fields, subscribed/emitted events
- `.kilo/documentation/events.md` — all events, emitters, listener priorities
- `.kilo/documentation/data-format.md` — sprite data file format
- `Tools/LuaMetrics/Settings.toml` — CC thresholds, clone min lines, exclusions
