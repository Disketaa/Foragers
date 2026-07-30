---
description: Verify codebase pattern compliance — detect regressions before they accumulate
---

# Verify Patterns Workflow

Run weekly or after any refactor. Each check is a TODO — find and fix violations.

## 1. Component scanning — must use findComponent/getComponents

The auto-formatter splits `for _, comp in ipairs(...) do` across lines when the
`ipairs(...)` argument is multi-line. Both forms must be checked.

**Compact form:**
```
grep -rn "for _, comp in ipairs(.*components" Source/ Main.lua
```

**Formatter-split form** (for _, comp in on its own line):
```
grep -rn "for _, comp in$" Source/ Main.lua
```

Allowed exceptions: `Sprite:update()`/`drawComponents()` (core dispatch), `Merge.lua` (pre-extracted data), `ParticleEmitter.lua` line 75 (`data.components`). Every other hit must use `findComponent`/`getComponents`.

## 2. Sprite instantiation — must use SpriteLoader.instantiate()

```
grep -rn "Sprite\.new(" Source/ Main.lua
```
Zero hits outside `Sprite.lua` (definition) and `SpriteLoader.lua` (internal call).

## 3. Component creation — must use ComponentRegistry.create()

```
grep -rn "ComponentRegistry\.create(" Source/ Main.lua
```
Zero hits outside `SpriteLoader.lua` (internal call) and `ComponentRegistry.lua` (definition).

## 4. _state / flipX writes — Control only

```
grep -rn "parent\._state\s*=" Source/
grep -rn "parent\.flipX\s*=" Source/
```
Zero hits outside `Control.lua`. Control is the single writer (AGENTS.md §I).

## 5. Cross-component field reads in update()

```
grep -rn "parent\.\w" Source/Sprite/Components/ | grep -v "draw()" | grep -v "_state" | grep -v "flipX" | grep -v "tweens" | grep -v "shader" | grep -v "shaderData"
```
Events only. Allowed exceptions (`tweens`, `shader`/`shaderData`) in AGENTS.md §X.

## 6. Hardcoded gameplay values

```
grep -rn "love\.math\.random\|math\.random\|timer\s*=\s*[0-9]" Source/ Main.lua | grep -v "Content/Data/"
```
Gameplay numbers (cooldowns, speeds, sizes, weights, spawn rates) must live in `Content/Data/`.

## 7. Missing nil guards on sprite.components

```
grep -rn "\.components\b" Source/ Main.lua | grep -v "or {}" | grep -v "findComponent" | grep -v "getComponents" | grep -v "self\.components" | grep -v "data\.components" | grep -v "baseComponents" | grep -v "overrideComponents"
```
Any `sprite.components` access without `or {}` guard (outside findComponent/getComponents internals) is a potential nil error.

## 8. Event string literals

```
grep -rn 'Events\.' Source/ | grep -v "require.*Events" | grep -v "Events\.lua"
```
All event references must use `Events.lua` constants, not raw strings.

## 9. ModLoader registration

```
grep -rn "ComponentRegistry\.register" Source/ Mods/
```
Mods must register via `ComponentRegistry.register()`, not by directly adding to `_registry`.

## 10. draw() — parent.flipX / parent._state reads

```
grep -rn "parent\.flipX\|parent\._state" Source/Sprite/Components/ | grep -v "draw()"
```
May only be read inside `draw()` for rendering (AGENTS.md §I field exceptions).

## 11. Coordinate pivot awareness — STRICT

**Rule:** `sprite.x` / `sprite.y` is the sprite's **pivot point** in world space. `pivotX`/`pivotY` (0–1) define where the image origin sits relative to that point. All coordinate computation MUST be pivot-aware.

```
grep -rn "\.x\s*[=:]\|\.y\s*[=:]\|parent\.x\|parent\.y\|offsetX\|offsetY\|pivotX\|pivotY" Source/Sprite/Components/ Source/Helpers/ Source/UI/ Main.lua
```

For **every** result, ask: **"Is this controlled/affected by sprite pivot?"**

- `parent.x` / `parent.y` writes → YES, moves the pivot point
- `parent.x` / `parent.y` reads for positioning → YES, uses the pivot position
- `offsetX` / `offsetY` → YES, must be offset FROM the pivot, not from the sprite edge
- `pivotX` / `pivotY` → YES, must be used to compute draw origin (`ox = frameWidth * pivotX`, `oy = frameHeight * pivotY`)
- `love.graphics.draw` for a sprite → YES, must pass pivot-based origin offsets

**Violations:**
1. Treating `sprite.x`/`sprite.y` as top-left corner instead of pivot point
2. `love.graphics.draw` without pivot-based origin (`ox`, `oy`)
3. Offset computed from sprite edge instead of from pivot
4. `ox`/`oy` computed without multiplying by `pivotX`/`pivotY`

## 12. Shared utilities — no duplicated directory scanning

```
grep -rn "local function scan" Source/
```
Any hit outside `Path.lua` means a file has its own directory-walking loop instead of using `Path.scanDirectory`. Extract to the shared utility.
