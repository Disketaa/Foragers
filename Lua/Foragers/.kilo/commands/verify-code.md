---
description: Check written/changed code for hidden runtime instabilities before task delivery
agent: code
---

# Verify Code Workflow

A task is not complete when the code "runs on launch". Explicitly verify it won't break under conditions you didn't test manually. Follow steps in order.

## Step 1. List changed/added files

List every .lua file you created or modified in this task. The checklist below runs **per file individually**, not on the whole project — otherwise it's easy to skip a file that looked "too simple to have anything wrong".

## Step 2. Category checklist

For each file from step 1, go through all items. Answer not with "yes/no" but point to a specific line if you find an issue.

**2.1 Declaration order**
- Is each `local function` used by another function in this file declared ABOVE the usage site? (`local function` does not hoist — unlike `function name()`.)
- If a function is called from a LÖVE callback (`love.load`, `love.update`, `love.keypressed`, etc.) — is it definitely defined before the engine can call that callback?

**2.2 Nil and initialization order**
- Does each `local` variable that will be read before explicit assignment (e.g. in `love.update`/`love.draw` before `love.load` finishes) have a safe default (`{}`, `0`, explicit nil-check), not just implicit nil?
- What happens if `require(...)` or a data loading function (`SpriteLoader.loadAll`, reading a Lua config, etc.) returns `nil` or throws an error mid-way — does the module below it crash with "attempt to index/call a nil value", or is it handled?
- If a variable is read inside a component from `self.parent` — is `self.parent` checked for nil before accessing its fields (`self.parent.x`, `self.parent.tweens`)?

**2.3 Names and scope (scope/shadowing)**
- Are there two different entities with the same name in different scopes?
- Variables captured in closures

**2.4 Draw passes (`drawBehind`, `drawOnTop`)**
- Does a component that draws decals/underlays have `drawBehind = true` set?
- Does a component that draws debug graphics (collision wireframe) have `drawOnTop = true` set?
- Do `drawBehind` and `drawOnTop` conflict on the same component? (Lua allows both flags, but behavior is undefined.)

**2.5 Single-writer rule and event model**
- Does the component NOT write `parent._state` or `parent.flipX` directly, unless it's Control? (Violates the single-writer rule from `.kilo/AGENTS.md` §IV.)
- Does the component NOT read another component's fields in `update()`? Even through `parent`? (Cross-component communication — events only.)
- If a new component subscribes to an event — is the priority chosen with a gap of 5 (5/10/15/20)?
- Are all event references string constants from `Source/Helpers/Events.lua`?

**2.6 Design constants in config**
- Is every number or string that could affect gameplay or behavior (safe zone size, animation speed, collision radius, gravity strength, etc.) placed in `Content/Data/`, not hardcoded? (Violates data-driven design from `.kilo/AGENTS.md` §I.)

**2.7 Modding and external data (if the file touches these)**
- If the file reads mod/content data — what happens when a field is missing, a type is wrong, or the mod's Lua file is corrupted? Does it give clean degradation (mod ignored / error log), not a full game crash?
- Is there an assumption "this field definitely exists" without a guard, for data that a mod could potentially override?

**2.8 Side effects on re-execution**
- If a function/file can be executed again (repeated `require` after `package.loaded[...] = nil`) — does it accumulate side effects: duplicate event subscriptions, duplicate objects in tables, leaked old resources (e.g. unreleased `Image`/`Quad`)?

**2.9 Documentation (Rationale comments only rule)**
- Is there a decision implemented in a non-obvious way (e.g. a particular declaration order from 2.1, a non-standard way to work around a LÖVE2D limitation, a non-obvious workaround) — and if so, is **why** explained next to the code, not left as a bare fact?
- Does every `love.*` call / object method / enum string whose behavior doesn't follow directly from its name have a reference to a specific file/symbol in `.kilo/documentation/`, not a generic "see LÖVE2D docs"?
- If the file exports functions that mods can call (this module's modding API) — do they have LuaDoc/EmmyLua annotations (`---@param`, `---@return`)?
- Are there comments that just restate the code in words? (Violates the Rationale comments only rule in reverse — this is also a problem, not just missing needed comments.)

## Step 3. Comments

Comments only if:
- explain "why", not "what" (code already says what)
- describe non-obvious contract between functions/modules
- this is LuaDoc type annotations

Do NOT write a comment if removing it leaves the code
self-explanatory. When unsure — don't write.

## Step 4. Report

After going through the checklist — briefly, for each item found:
- file and line
- what scenario this breaks (specific conditions, not "could be a problem") — or for item 2.9, which decision remained unexplained
- proposed minimal fix: either a code change (without rewriting the architecture — see MINIMAL CHANGES and SIMPLICITY FIRST), or a missing comment/LuaDoc annotation (see RATIONALE COMMENTS, NOT NARRATION)

If no problems are found for a checklist item — don't describe it to the user, just omit it from the report. If all items are clean — say so in one line, don't artificially find nitpicks for the sake of looking busy.

## Step 5. Applying fixes

Fixes from the report are applied only after user confirmation — do not make silent changes within this workflow. This is a verification step, not a rewrite step.
