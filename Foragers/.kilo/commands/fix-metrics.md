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
- Clone pair is required boilerplate idiom (event `attach()` subscription, component factory pattern) — not copy-pasted business logic
- Fix requires touching Section I constraints (event system, single-writer rule, component boundaries)
- File matches `Settings.toml` `exclude_files`

**Do not silently drop a skip.** Every skip must be recorded.

## Skip format (strict)
```
file:line:col - rule_name: SKIP — reason
```

Reason must be concrete, not advisory. Reject: "seems fine". Require: "14-state FSM dispatch, branches structurally distinct, not sloppy".

If the skip should persist across future scans (not just this pass):
- **CC skip**: add the function name to `targets.exclude_functions` in `Tools/LuaMetrics/Settings.toml`. The tool writes accepted skips to `Tools/LuaMetrics/Baseline.json` automatically; that file should contain only excluded/accepted functions, not every function in the project. On subsequent runs:
  - fingerprint matches → silently skipped
  - fingerprint mismatches → reported as `[BASELINE CHANGED]` so you know the code drifted
- **Clone skip**: add the clone fingerprint to `Tools/LuaMetrics/Baseline.json` under key `clone:rel1:line1:rel2:line2`. Fingerprint = sha256 of the normalized 6-line clone window (strings/comments stripped, empty lines removed). On subsequent runs:
  - fingerprint matches → silently skipped
  - code drifts → fingerprint changes → clone is reported again

Do not edit `Baseline.json` manually for CC skips; edit `Settings.toml` and let the tool regenerate the baseline. For clone skips, add entries directly to `Baseline.json` using the format above.

### Generating clone fingerprints
To add a clone skip to `Baseline.json`:
1. Identify the clone pair: `file1:line1` and `file2:line2`
2. Extract the normalized 6-line window from each location (strings/comments stripped, empty lines removed)
3. Compute sha256 of the joined normalized lines
4. Add entry to `Baseline.json`:
   ```json
   "clone:Source\\Path\\File1.lua:LINE1:Source\\Path\\File2.lua:LINE2": {
     "fingerprint": "sha256hex",
     "updated": "ISO_TIMESTAMP"
   }
   ```
5. Re-run LuaMetrics — the clone should be silently skipped

If the code at either location changes, the fingerprint will mismatch and the clone will be reported again.

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
| Clone | Extract shared code into a helper; call from both sites. If extraction is not viable (boilerplate, distinct contexts), record skip in `Baseline.json` with clone fingerprint |

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
Ask webai, using --claude --new to approve your solution. Attach relevant files with @
If webai telling you send more info, use --same tag!

## Known issues
### LuaMetrics depth-tracking false positives
`Tools/LuaMetrics/LuaMetrics.py` historically missed `local function` boundaries, inflating CC for any function containing nested named locals. Reported CC=26/58 for `drawProfiler`/`Debug.draw` were unreliable; true CC unknown until tool is fixed. Patch: recognize `^(local\s+)?function\b` and `^(do|if|while|for|repeat)\b` as depth openers.

### LuaMetrics end-counting overcount
`extract_functions` used `clean.count("end")`, which matches the substring anywhere. Fix: `re.findall(r"\bend\b", s)` so only the keyword counts.

### LuaLS parameter drift after extraction
When extracting helpers from a large draw/update function, LuaLS will flag:
- unused params in the new helper
- undefined globals where the helper reads a parent local that wasn't passed through
- arity mismatches at call sites
- stale `---@param` LuaDoc on the extracted function

Fix pattern: after each extraction, run LuaLS, then audit the helper signature against its body and every call site. Remove unused params, add missing ones, update LuaDoc. Do not leave placeholder params "for symmetry" — they trigger unused-argument warnings.

### Parameter propagation rule
A helper extracted from a parent function can only use what is explicitly passed. If the helper references a local defined in the parent (color, font, offset, gap, etc.), that local must become a parameter. Do not rely on closure over parent locals — LuaLS treats them as undefined globals inside the helper.

## Reference
- `.kilo/AGENTS.md` — full architecture, component rules, event system, error handling
- `.kilo/documentation/components.md` — component config fields, subscribed/emitted events
- `.kilo/documentation/events.md` — all events, emitters, listener priorities
- `.kilo/documentation/data-format.md` — sprite data file format
- `Tools/LuaMetrics/Settings.toml` — CC thresholds, clone min lines, exclusions