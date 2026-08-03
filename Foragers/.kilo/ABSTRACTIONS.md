---
description: Hard-won lessons from past work — read before coding in these areas
---

# ABSTRACTIONS — lessons for future agents

Short, brutal notes on mistakes already made so you don't repeat them. Read the
relevant section before touching that subsystem.

## Shader modules (Source/Helpers/ShaderLoader.lua, Source/Sprite/Components/Shader.lua)

- **Module files MUST be `.lua`, never `.glslinc`.** LÖVE `require` only loads
  `.lua`; `ShaderLoader` scans only `%.lua$`. A `.glslinc` module is silently
  never loaded → `compose` returns nil → shader not applied, no error.
- **In `effect()`, `color` is already a parameter.** Never write
  `vec4 color = Texel(...)`. That is a GLSL redefinition error
  (`'color' : redefinition`). Assign into it: `vec4 sampled = Texel(...); color = sampled;`
- **Never put a Lua comment string into the generated GLSL.** A Lua string
  `"	-- effect() ..."` concatenated into the shader source becomes GLSL `--`
  (decrement operator) → `'--' : l-value required`. Write rationale as a Lua
  comment OUTSIDE the string concatenation, not inside the GLSL code string.
- **Exactly one `Texel` call.** Pipeline is uv-chain → single `Texel` →
  color-chain. A module that re-`Texel`s overwrites the earlier sample (last
  wins), so stacking color modules via separate `Texel` calls does not compose.
- **`compose(names)` is cached by joined name.** Repeat calls with the same
  module set return the cached SHADER OBJECT — do not expect a fresh shader.
- **Cached shader → shared GPU state.** All sprites with the same shader
  composition (e.g. `{ "Brightness" }`) get the SAME shader object.
  `shader:send()` writes to the shared GPU uniform. If you skip re-sending
  defaults every frame, one sprite's tweened uniform leaks to all others during
  draw (last `send` wins). The ShaderComponent must re-send EVERY whitelisted
  uniform every frame in `update()`, regardless of whether a tween is active.
  Removing the per-frame fallback (e.g. the old `elseif self.brightness` path)
  breaks every sprite without an active tween.
- **Module types:** `type = "uv"` exposes `Name_uv(vec2 uv, vec2 screen_coords)`
  and returns modified `uv`; `type = "color"` exposes `Name_color(vec4 color, vec2 screen_coords)`
  and returns modified `color`. Both are `module = true`. The `screen_coords` param
  matches the `effect()` function — needed by modules that sample a separate canvas
  (e.g. Silhouette reads `u_silhouetteTexture` at the current pixel's screen position).
- **Shader component reads `shaders` (array) or legacy `shaderName` (string).**
  Data uses `shaders = { "Brightness", "Skew" }`. Each entry may be a string
  name, `{ name = "X" }`, or compact `{ X = { u_* = ... } }` for per-shader
  uniform overrides. Merge collapses by key `"shader:"` and concatenates the
  `shaders` arrays (parent first, dedup by name), preserving spec params.
- **LÖVE does NOT auto-declare uniforms.** Every uniform must be an `extern` in
  the GLSL source or `shader:send` silently does nothing. `ShaderLoader` injects
  `extern` declarations automatically from each module's `uniforms` table.
  **Exception: Image-type uniforms** (`extern Image u_*`) cannot be declared from
  the `uniforms` table (only `float`, `vec2-4`, `bool`, `mat4`). Declare them
  directly in the module's `code` string, before any function definitions. The
  `ShaderLoader` concatenates the raw code into file scope, so `extern Image`
  at the top of the module string resolves correctly.
- **Compile errors are swallowed by `pcall` in `compose`.** If a composed shader
  shows no effect, the cause is almost always a GLSL compile failure returning
  nil. Temporarily print the `pcall` error (or write the generated source) to see it.

## Silhouette reveal (tree → silhouette canvas)

- **Tree reads silhouette canvas, not the reverse.** Every sprite with
  `component = "silhouette"` and `mode ~= "mask"` is pre-rendered as a white
  silhouette onto a separate canvas (same size as world canvas). Trees with
  `"Silhouette"` shader module sample `u_silhouetteTexture` at
  `screen_coords / love_ScreenSize.xy`. Where silhouette alpha > threshold,
  the tree's fragment is replaced with white. This avoids Y-sort filtering: if
  a silhouette sprite sorts in front of a tree, it draws later and covers the
  tree entirely. If tree sorts in front, tree draws later and its shader reveals
  the silhouette behind it. No `sortY` comparison needed.
- **Non-spritesheet sprites in silhouette canvas.** `Mask.renderSilhouette()`
  handles sprites with no `spritesheet` component (e.g. Pickaxe — single-frame
  auto-detected from filename match). It draws `sprite.image` directly with
  pivot, flipX, tween scale/angle, and static `sprite.angle`. This mirrors the
  `Sprite:draw()` StaticSprite path. Without this fallback, such sprites would
  be invisible in the silhouette — they have `sprite.image` but no spritesheet
  component to provide `drawCurrentFrame`.

## In-process restart (Source/Helpers/Reset.lua, Main.lua initGame/resetGame)

- **NEVER re-run `love.load()` to reset the game.** It calls `love.window.setMode()`, which on Windows recreates the native window (visual "window reopens" — blink, focus loss) even though it's the same process. Split into one-time engine setup (`love.load`: window, default filter, shader/saturation assets, `ModLoader.loadAllMods`) and re-runnable `initGame()` (world, sprites, UI, player). `resetGame()` (R key) sets `_needsRestart`, consumed at the top of `love.update`, then calls `Reset.all()` + `initGame()`.
- **`Reset.all()` wipes every array-valued field in `Source.`/`Mods.` modules.** This is the point: clears module-owned pools (particles, floating text, dead/pending/detached sets, attacker refs). But it also nukes arrays that are NOT runtime pools — e.g. `ShaderLoader.shaders`. If such asset lists are only loaded in `love.load()`, a restart leaves them empty → the asset silently disappears. Fix pattern: re-run the loader inside `initGame()` (`ShaderLoader.loadAll("Content/Assets/Shaders")`), not `love.load()`. Shader recompilation does not recreate the window.
- **`Reset.all()` skips dict-valued fields** (factories, caches like `ComponentRegistry.factories`, `TextEmitter.fontCache`) and `__`-prefixed metamethod keys (`__index`). Only sequential-integer-keyed arrays are cleared. Do not "fix" it to clear all tables — that wipes registries and crashes sprites.

## LÖVE filesystem / paths (PowerShell tooling note)

- The `filesystem_*` tools are bound to a different root than the project
  (`C:\Projects\Pixel-Portfolio`), so they deny access to
  `C:\Projects\Foragers\...`. Use `bash` (PowerShell) for file moves/creates
  instead.
- PowerShell 5.1 `New-Item`/`Move-Item` here do NOT accept `-LiteralPath` for
  `New-Item` (parameter binding error). Use `-Path`. A failed `New-Item` aborts
  the whole `;` chain, so create directories BEFORE moving files, and verify
  files still exist after a botched move — a partial move can lose files that
  must be recreated from known content.
- `Path.lua` converts `Content/Assets/Shaders/Sprite/Color/X.lua` →
  `Content.Assets.Shaders.Sprite.Color.X` for `require`. Recursive
  `ShaderLoader.loadAll` finds modules at any nesting depth, so restructuring
  shader folders needs NO code change — only the file moves.

## Debug flags

- `_G.SHADER_DEBUG` was used temporarily for console prints / file dumps. It is
  removed from `conf.lua` when done. Do not leave debug prints or
  `love.filesystem.write` of generated shaders in shipped code.
- **Debug overlays draw in a native-resolution pass, never into the low-res world
  canvas.** The world canvas (480×270) is upscaled with nearest filter, so any
  1px debug line drawn inside it becomes a blocky `scale`-px square (the "aliasing"
  that reads as blurry). `Collision` publishes rects to `Source/Helpers/Gizmo.lua`
  (world-space buffer) and `Main.lua` draws them after the world canvas with a
  `worldToScreen` transform that mirrors `Canvas:draw`'s placement math — including
  using `shakeOffsetX/Y` as the view offset (NOT `camPixelX`, which is applied once
  inside the world translate). `Gizmo.clear()` runs every frame; its rect buffer is
  a module `local`, so it survives `Reset.all()` but is drained per frame.
- **`Content/Data/Debug.lua` is a group-based settings table, not flat booleans.**
  Each debug overlay is a group (e.g. `collisions = { enabled, exclude, color,
  backgroundColor, priority }`). The `Debug` helper (`Source/Helpers/Debug.lua`) exposes group accessors
  (`enabled`, `excluded`, `settings`, `isEnabled`, `onChange`) and never knows which
  component consumes them — consumers subscribe via `Debug.onChange`, keeping the
  dependency one-directional. `Gizmo.rect`/`Gizmo.fillRect`/`Gizmo.point` tag each entry with its
  group name and `Gizmo.draw` resolves styles per group — fill (`backgroundColor`),
  outline (`color` + `decor`) and point markers — ordering groups by ascending `priority` so
  e.g. `collisions` layer over `boundaries` and `pivots` stay on top.

## SpriteFont / Text / TextEmitter (Source/Sprite/Components/SpriteFont.lua, Source/UI/Text.lua, Source/UI/Components/TextEmitter.lua)

- **`utf8Next` MUST index glyphs by VISUAL char, not byte.** The `chars` table
  mixes Latin (1 byte) and Cyrillic/digits (2+ bytes). Old code used the byte
  offset as the cell index, so a 2-byte char (e.g. digit `'1'`) landed on the
  wrong quad (byte 185 → cell 185, but the real cell was 119). Build
  `_charIndex`/`_charWidth` by incrementing a counter per decoded char, never by
  `i = i + #char`. This is shared by `Text.lua` and `TextEmitter`, so a wrong
  index corrupts ALL text rendering, not just one component.
- **LuaJIT is Lua 5.1 — no `utf8` module, no `goto`.** Decode multi-byte manually
  by leading byte: `>=0xC0` → len 2, `>=0xE0` → len 3, `>=0xF0` → len 4; a stray
  continuation byte → len 1 (treat as unknown glyph). Do not reach for the Lua 5.3
  `utf8` library or `goto` — neither exists here.
- **TextEmitter lives in `Source/UI/Components/`, NOT `Source/Sprite/Components/`.**
  It is a floating-damage-number emitter, not a sprite behavior. It is registered
  in `ComponentRegistry` as `text_emitter` but is driven by global
  `TextEmitter.updateAll(dt)` / `TextEmitter.drawAll()` called from `Main.lua`
  (NOT via the per-sprite component loop). Do not move it into the sprite
  component folder or wire it into `Sprite:update`.
- **`drawAll` must disable the active shader then restore it.** Sprites may have a
  shader bound; text drawn inside the world canvas must not inherit it. Save
  `love.graphics.getShader()`, `setShader(nil)`, draw, then restore.
- **Parse random params PER EMIT, not in `new`.** `moveX/moveY/gravity/duration/
  offsetX/offsetY` accept `"a|b"` choice and `"min..max"` range via
  `ValueParser.call`. If you parse them once in `new`, every hit shows the
  same value. Re-roll inside the `PROP_HIT` handler so each hit varies.
- **Keep `curve` a SEPARATE field from `destroy`.** Do not combine into one string
  like `"scale,InCubic"`. `destroy` (`"fade"|"scale"|"instant"`) controls the
  animated property; `curve` (default `"Linear"`) is the easing name applied via
  `Tween.Easing[t.curve](p)`. Matches the Tween component's separate-field
  convention.
- **Animated property always goes 1→0.** `fade` → alpha, `scale` → scale,
  `instant` → stays 1. Do not add `startAlpha/endAlpha/startScale/endScale`
  knobs — the prop always animates to zero.
- **TextEmitter requires `Tween` ONLY for its `Easing` table.** No circular dep:
  `require("Source/Sprite/Components/Tween")` for `Tween.Easing` only. Do not pull
  in the whole Tween component lifecycle.

## ValueParser (Source/Helpers/ValueParser.lua) — __raw contract

- **`ValueParser.table(tbl)` resolves all strings in place.** Any field whose
  resolved value differs from the original gets stored in `tbl.__raw[field]`. This
  is how per-event re-rolling works: components call `ValueParser.call(tbl, field)`
  which re-resolves from `__raw` if present. Without `__raw`, `call` returns the
  already-resolved number — no re-roll.
- **`SpriteLoader.instantiate()` copies `compData.__raw` to the component instance**
  after `ComponentRegistry.create()`. If a component constructor creates a new table
  (Drop.new entry, TextEmitter new()), `__raw` is NOT on the new table — the
  SpriteLoader copy only applies to the top-level component instance. Drop fixes
  this by manually copying `d.__raw` to each new entry. Any future component that
  builds nested tables from resolved data must do the same.
- **Particle data loaded via `require` in `ParticleEmitter.new()` bypasses
  `SpriteLoader.instantiate()`** — must call `ValueParser.table(particleData)`
  explicitly after loading, or `speed = "4..8"` stays a string and crashes in
  `_createParticle`.

## Particle detach pattern (Source/Sprite/Components/ParticleEmitter.lua)

- **Components that outlive their parent belong in a global pool, not kept alive via invisible corpse sprites.** `ParticleEmitter.detachAll(sprite)` is called from `Main.lua` before dead-sprite cleanup. It sets `parent = nil`, stops spawning, and moves the component to `detachedEmitters`. Global `updateDetached(dt)`/`drawDetached()`/`drawDetachedBehind()` loop until `#_particles == 0` then self-clean.
- **`_burst` and `_spawn` must guard `self.parent` before accessing parent fields.** Event listeners subscribed before detach could theoretically fire after parent=nil — guard defensively even if no caller emits on dead sprites.
- **Particle aging loop runs unconditionally (attached and detached).** The `_detached` early-return goes between aging and spawning — aging must always run so particles expire and cleanup triggers.

## Pain points from migration (Math.parseRandomValue → ValueParser)

- **Don't blacklist fields by name for per-event re-roll.** Early approach used
  `_perEvent = { tags = true, tweens = true, moveX = true, ... }` in
  `ValueParser.table()` to skip resolving those fields. Every new component with
  per-event fields needed an entry. Replaced by `__raw` + `ValueParser.call()`
  approach: resolve everything, store raw copies, let components opt in per field.
- **Triple-dot range typo (`"4...6"`) silently fails.** The range parser matches
  exactly `%.%.` (two dots). `"4...6"` has three dots → no match → `tonumber`
  returns nil → string stays as-is → crashes later. Every data file had this bug.
  Write range strings as `"min..max"`, never `"min...max"`.
- **`__raw` must be copied manually when constructor creates new tables.**
  `Drop.new` iterates `data.drops` and builds fresh entry tables. The entries
  lose `d.__raw`. `ValueParser.call(entry, "amount")` falls through to the
  resolved number. Fix: copy `d.__raw` to each new entry. Any future component
  pattern that copies fields instead of storing the reference must do the same.

## ValueParser verification checklist

`ValueParser.table(data)` resolves every `"min..max"` / `"a|b|c"` string in the
entire data tree. These fields are safe to randomize:

| Field | Works? | Constraint |
|---|---|---|
| Top-level: `frameWidth`, `frameHeight`, `pivotX`, `pivotY`, `layer`, `sortOffsetY` | **Yes** | frameWidth/Height must match PNG columns/rows at runtime |
| `spritesheet` speed | **Yes** | — |
| `follow` smoothness, smoothnessX/Y, followDelay | **Yes** | — |
| `scroll_to` smoothness | **Yes** | — |
| `tween` from, to, duration (base + tags) | **Yes** (re-rolled per event via `ValueParser.call`) | — |
| `drop` amount | **Yes** (re-rolled per break via `ValueParser.call`) | — |
| `text_emitter` moveX/Y, gravity, duration, offsetX/Y | **Yes** (re-rolled per emit via `ValueParser.call`) | — |
| `particle_emitter` count, angle | **Yes** (re-rolled per burst via `ValueParser.callRange`) | — |
| `collision` offsetX/Y, collisionWidth/Height, slowdown | **Yes** | — |
| `shadow` offsetX/Y, width, height | **Yes** | — |
| `sound` volume, pitch, pitchRandomness | **Yes** | — |
| `shake` magnitude, duration, decay | **Yes** | — |
| Any numeric field in any component | **Yes** | — |

**Fields that MUST stay fixed (random breaks the system):**
| Field | Why |
|---|---|
| `component` (string like `"spritesheet"`) | Not random — stays string, passes through |
| `event`, `mode`, `destroy`, `curve`, `hAlign`, `vAlign` | Enum strings — pass through |
| `object`, `extends` | Identifiers — pass through |
| `chars`, `spacing`, `tags` (spritesheet animation names) | Structural data — pass through |
| `shaders` (array of strings) | Shader names — pass through |
| `font` (module path) | Must resolve to a valid require — pass through |
| `sprite` (particle/drop asset path) | Must resolve to a valid require — pass through |
