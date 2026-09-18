---
description: Guide for fixing a single metrics violation in Foragers
---

## Before you start
2. Read the flagged file and the exact function/region mentioned in the violation
3. Check `.kilo/documentation/` for LÖVE2D API docs if the fix touches engine calls
4. Comments only if:
- explain "why", not "what" (code already says what)
- describe non-obvious contract between functions/modules
- LuaDoc type annotations

Do NOT write a comment if removing it leaves the code
self-explanatory. When unsure — don't write.


## Not every violation gets fixed
Before fixing, decide: **fix** or **skip**.

**Skip if any apply:**
- CC exceeds threshold but branches are structurally distinct (state machine, parser dispatch, event router) — not repeated/near-identical logic
- Clone pair is a required boilerplate idiom (event `attach()` subscription, component factory pattern) — not copy-pasted business logic
- Fix requires touching Section I constraints (event system, single-writer rule, component boundaries)
- File matches `Settings.toml` `exclude_files`
**Do not silently drop a skip.** Every skip must be recorded.

## Skip format (strict)

```
file:line:col - rule_name: SKIP — reason
```

Reason must be concrete, not advisory. Reject: "seems fine". Require: "14-state FSM dispatch, branches structurally distinct, not sloppy".

If the skip should persist across future scans (not just this pass), also add a baseline entry:
```
Tools/LuaMetrics/baseline.json
```
keyed by structural fingerprint, not file:line — see `Tools/LuaMetrics/README.md` for fingerprint generation. Do not add a line-number-keyed entry; it invalidates on refactor.

If the skip is architectural (Section I conflict), use `REVIEW REQUIRED` instead of `SKIP`:
```
file:line:col - rule_name: REVIEW REQUIRED — architectural change needed
```

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
- Do not touch Section I constraints — if the fix requires that, stop and flag `REVIEW REQUIRED`

### 4. Verify
- Run the specific gate that reported the violation
- If the violation is gone and no new violations appeared — done
- If blocked by architecture — emit `REVIEW REQUIRED` instead of forcing it

## Output format
After processing each violation, report exactly one of:
```
file:line:col - rule_name: FIXED — what was done
file:line:col - rule_name: SKIP — reason
file:line:col - rule_name: REVIEW REQUIRED — architectural change needed
```

## After fixing
Tell the user what to check in-game to verify the fix didn't break anything.

## Reference
- `.kilo/AGENTS.md` — full architecture, component rules, event system, error handling
- `.kilo/documentation/components.md` — component config fields, subscribed/emitted events
- `.kilo/documentation/events.md` — all events, emitters, listener priorities
- `.kilo/documentation/data-format.md` — sprite data file format
- `Tools/LuaMetrics/Settings.toml` — CC thresholds, clone min lines, exclusions