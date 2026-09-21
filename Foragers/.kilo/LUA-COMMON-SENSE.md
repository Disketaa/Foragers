# LUA-COMMON-SENSE.md — Read Before You Write Lua

Generic, project-agnostic checklist for any Lua codebase. A project's own
AGENTS.md / style guide wins if it conflicts with anything here.

## ⚠️ CRITICAL — Use a To-Do List, Section by Section

Before writing any code, add one to-do item per section below to your
task-tracking tool. Go through them **in order, one at a time**. Check a
section off only after applying it to the actual code you wrote — not after
just reading it. Do not skip ahead, do not batch sections together, do not
mark the whole file "done" in one pass. Most rules here get missed because
this step gets skipped, not because the rule was unclear.

## 1. Before You Write Anything
- [ ] Read the actual file you're changing — not a summary of it.
- [ ] Search for an existing function/module that already does this.
- [ ] Understand *why* the code is shaped this way before reshaping it.
- [ ] Check for a style guide or prior-art notes before proposing a change.
- [ ] Say "I'm not sure" instead of guessing, when you actually are unsure.

## 2. Lua Gotchas Cheat Sheet
- **`local` isn't automatic** — omitting it creates or overwrites a global.
- **Only `nil` and `false` are falsy.** `0` and `""` are truthy:
  `if count ~= nil then` — not `if count then` — when `0` is a valid value.
- **`#t` is undefined if the table has holes.** Don't nil out the middle of
  an array; rebuild it instead.
- **`pairs()` has no guaranteed order** — use `ipairs`/numeric `for` for
  sequences.
- **Multiple returns truncate outside the last position** — wrap in parens
  `(f())` to force exactly one value.
- **A trailing comma silently merges two statements.** Lua has no statement
  terminator; format/lint to catch it.
- **`obj.method(obj,...)` is `obj:method(...)`.** Forgetting the colon is a
  classic nil-`self` bug.
- **Never remove/insert into an array while iterating it forward.**
  `ipairs`/a forward `for` skips or misreads entries once a mid-loop
  `table.remove` shifts indices. Iterate backwards (`for i = #t, 1, -1 do`)
  when removing in place, or collect the targets first and remove them in a
  second pass after the loop ends.
- **Closures capture the variable, not a snapshot.** A `local` declared
  inside a loop body is fresh per iteration; one declared outside the loop
  is shared by every closure made inside it.
- **Don't assume language-version features exist** — Lua 5.1/LuaJIT has no
  `goto`, no bitwise operators, no `utf8` library.
- **`pcall`/`xpcall` return `true, result` or `false, err`** — always check
  the boolean before touching the second value.

## 3. Structure & Architecture
- [ ] One module, one responsibility.
- [ ] No god object — split by concern (rendering vs input vs save data).
- [ ] Composition over inheritance; inheritance only for a genuine "is-a".
- [ ] Data that can change without a code change lives in a data file, not
      inline in logic.
- [ ] Shared mutable state has exactly **one writer per field.** Different
      modules can each own different fields of the same shared table — the
      bug is two modules writing the *same* field, not a shared table existing.
- [ ] A registry/factory exposes `register()`/`create()` functions — callers
      never reach into its internal table directly.
- [ ] Decide on purpose whether a piece of state is transient (a module-local,
      fine to lose on reload) or must persist/be visible elsewhere (an
      explicit state field) — don't let that split happen by accident.
- [ ] No new dependency for something the language/codebase already does; no
      drive-by renames or reformatting outside the task's scope.

## 4. Defensive Coding — the Right Amount
- [ ] Nil-check anything from outside your control: file loads, mod/user
      data, optional fields, API responses.
- [ ] A caught or expected failure is handled — logged, returned to the
      caller as an explicit `nil, reason` (Lua's own idiom, mirroring
      `pcall`), or otherwise acted on. Never a bare empty catch whose result
      is left unread.
- [ ] Don't wrap everything in `pcall`/try-catch "just in case" — that hides
      bugs instead of fixing them. Handle what you expect; let the rest surface.
- [ ] Fail loudly in development; degrade gracefully for anything a user or
      mod can trigger.

## 5. Performance Sense
- [ ] Profile before optimizing — never guess where the slow part is.
- [ ] Reuse tables/strings in per-frame code instead of allocating fresh
      ones every iteration.
- [ ] Hoist a repeated lookup into a local before a hot loop, not inside it.
- [ ] Prefer numeric `for`/`ipairs` over `pairs` for sequences you control.
- [ ] Correctness first — optimize only where measurement shows it matters.

## 6. Red Flags — "Nobody Reviewed This"
- [ ] A function/API call that was never verified to exist.
- [ ] An abstraction, interface, or config option built for a need nobody
      asked for and nothing else uses.
- [ ] `pcall`/try-catch on every line, none of them logging or handling anything.
- [ ] A comment restating the line under it, instead of explaining *why*.
- [ ] Style or naming that doesn't match the rest of the file.
- [ ] "TODO: handle this later" on the exact path the task was meant to finish.
- [ ] A test or check that runs code without asserting on its output.
- [ ] A new helper duplicating one that already exists elsewhere.
- [ ] 4+ levels of nested `if`/`for` where a guard clause would flatten it.
- [ ] Removing or inserting into a table while iterating it forward.
- [ ] Reaching into another module's internal table instead of the functions
      it exposes for that purpose.

## 7. Before You Say the Task Is Done
- [ ] Actually ran it — or said plainly that you couldn't.
- [ ] Re-read your own diff top to bottom, as if reviewing someone else's PR.
- [ ] Checked the nil/failure path, not just the happy path.
- [ ] Ran whatever static check/linter/type checker the project provides and
      fixed what it flagged — don't rely on your own read-through alone.
- [ ] Removed debug prints, dead code, and commented-out old versions.
- [ ] Matches the surrounding file's style — not a generic style pasted in.
- [ ] Left a *why* comment on anything non-obvious.

## 8. Quick Reference

| Smell | Instead |
|---|---|
| `x = 5` at file scope | `local x = 5` |
| `if count then` when `count` can be `0` | `if count ~= nil then` |
| Magic number in a condition | Named constant |
| `pcall` result's `err` never read | Log it or act on it |
| One 200-line function | A few small, single-job functions |
| Guessing a method name | Grep the source or read the docs first |
| Two modules writing the same field | One writer per field; others read or request |
| `table.remove` while iterating forward | Iterate backwards, or collect-then-remove |
| Reaching into a registry's internal table | Use its `register()`/`create()` functions |