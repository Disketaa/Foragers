---
description: Verify changed code for runtime instabilities and pattern regressions before task delivery
---

# Verify Code Workflow

Task not done when code "runs on launch". Verify it won't break under untested conditions. Follow in order.

## Step 1. List changed/added files
List every .lua created/modified this task. Checklist runs **per file**, not whole project — easy to skip "simple" files otherwise.

## Step 1.5 Lint (nil checks live here)
Run the LuaLS static check — it surfaces `need-check-nil` and type warnings across all files:
```
powershell.exe -ExecutionPolicy Bypass -File Tools/lua-ls-check.ps1
```
(or VS Code task `LuaLS Check`). Fix every `need-check-nil` (real latent bug) and undefined-field warning.
Also run luacheck for style/global leaks: `.\Tools\luacheck.exe Source/`. Fix all warnings before proceeding.

## Step 2. Category checklist
For each file from step 1. Point to a specific line, not "yes/no".

**2.1 Declaration order**
- `local function` used by another in-file function declared ABOVE usage? (`local function` doesn't hoist.)
- Function called from a LÖVE callback (`love.load`/`update`/`keypressed`) defined before engine can call it?

**2.2 Nil & init order**
- `local` read before assignment has safe default (`{}`, `0`, explicit nil-check)?
- `require(...)` / data load returns nil or throws mid-way — does module below crash on nil index/call, or handle it?
- `self.parent` read in component — nil-checked before field access (`self.parent.x`, `self.parent.tweens`)?

**2.3 Names & scope**
- Two entities same name in different scopes?
- Variables captured in closures correct?

**2.4 Draw passes**
- Decal/underlay component has `drawBehind = true`?
- Debug-graphics component has `drawOnTop = true`?
- Both flags on same component? (undefined behavior.)

**2.5 Single-writer & events**
- Component doesn't write `parent._state`/`flipX` unless Control? (AGENTS §I.)
- Component doesn't read another component's fields in `update()`? (events only, AGENTS §I.)
- New event subscription priority gap of 5 (5/10/15)? (exception: STATE_CHANGED/FLIPPED 7↔8, 10↔11↔12, AGENTS §X.)
- All event refs are `Events.lua` string constants?

**2.6 Design constants**
- Gameplay/behavior numbers (safe zone, anim speed, collision radius, gravity…) in `Content/Data/`, not hardcoded? (AGENTS §I.)

**2.7 Modding & external data**
- Missing field / wrong type / corrupted mod Lua — clean degradation (mod ignored / error log), not full crash?
- "Field definitely exists" assumption without guard on mod-overridable data?

**2.8 Re-execution side effects**
- Re-`require` (after `package.loaded[...] = nil`) — duplicate subscriptions, duplicate table entries, leaked `Image`/`Quad`?

**2.9 Documentation**
- Non-obvious decision (declaration order, LÖVE workaround) has **why** comment, not bare fact?
- `love.*`/method/enum with non-obvious behavior references specific `.kilo/documentation/` symbol, not generic "see LÖVE docs"?
- Mod-callable exports have LuaDoc (`---@param`, `---@return`)?
- Comments that just restate code? (violates rationale-only rule.)

## Step 3. Pattern compliance
Run weekly or after refactor. Each is a grep — find and fix violations. Allowed exceptions noted.

1. **Component scan** — must use `findComponent`/`getComponents`:
   `grep -rn "for _, comp in ipairs(.*components" Source/ Main.lua` and formatter-split `grep -rn "for _, comp in$" Source/ Main.lua`.
   Exceptions: `Sprite:update()`/`drawComponents()`, `Merge.lua`, `ParticleEmitter.lua:75`.
2. **Sprite instantiation** — `grep -rn "Sprite\.new(" Source/ Main.lua`. Zero outside `Sprite.lua`/`SpriteLoader.lua`.
3. **Component creation** — `grep -rn "ComponentRegistry\.create(" Source/ Main.lua`. Zero outside `SpriteLoader.lua`/`ComponentRegistry.lua`.
4. **_state/flipX writes** — `grep -rn "parent\._state\s*=\|parent\.flipX\s*=" Source/`. Zero outside `Control.lua`.
5. **Cross-component reads in update()** — `grep -rn "parent\.\w" Source/Sprite/Components/ | grep -v "draw()\|_state\|flipX\|tweens\|shader\|shaderData"`. Events only; `tweens`/`shader`/`shaderData` allowed (AGENTS §X).
6. **Hardcoded gameplay values** — `grep -rn "love\.math\.random\|math\.random\|timer\s*=\s*[0-9]" Source/ Main.lua | grep -v "Content/Data/"`. Numbers in `Content/Data/`.
7. **Nil guards on sprite.components** — `grep -rn "\.components\b" Source/ Main.lua | grep -v "or {}\|findComponent\|getComponents\|self\.components\|data\.components\|baseComponents\|overrideComponents"`. Access without `or {}` = potential nil error.
8. **Event string literals** — `grep -rn 'Events\.' Source/ | grep -v "require.*Events\|Events\.lua"`. Use `Events.lua` constants.
9. **ModLoader registration** — `grep -rn "ComponentRegistry\.register" Source/ Mods/`. Mods use `register()`, not `_registry` direct add.
10. **draw() pivot reads** — `grep -rn "parent\.flipX\|parent\._state" Source/Sprite/Components/ | grep -v "draw()"`. Read only inside `draw()` (AGENTS §I).
11. **Pivot awareness (STRICT)** — `grep -rn "\.x\s*[=:]\|\.y\s*[=:]\|parent\.x\|parent\.y\|offsetX\|offsetY\|pivotX\|pivotY" Source/Sprite/Components/ Source/Helpers/ Source/UI/ Main.lua`. For each: is it pivot-aware? `sprite.x/y` = pivot point; `pivotX/Y` (0–1) compute draw origin (`ox = frameWidth*pivotX`); offsets from pivot, not edge. Violations: treating x/y as top-left, draw without pivot origin, edge-based offset, ox/oy without pivotX/Y.
12. **Shared utilities** — `grep -rn "local function scan" Source/`. Zero outside `Path.lua` (use `Path.scanDirectory`).
13. **Restart reset** — before module-level mutable state, ask "reset on restart?" `Reset.all()` only clears exported array fields; module-level `local` tables invisible to it. Asset arrays (e.g. `ShaderLoader.shaders`) must reload in `initGame()`, not only `love.load()`.

## Step 4. Comments
Run `adjust-comments` to verify rationale-only rule. Don't duplicate here.

## Step 5. Report
Per item found: file+line, exact break scenario (specific conditions), minimal fix (code change or missing comment/LuaDoc). Omit clean items. If all clean — one line.

## Step 6. Applying fixes
Apply only after user confirmation. Verification, not rewrite.
