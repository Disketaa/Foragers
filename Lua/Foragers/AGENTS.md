# AGENTS.md

## STATUS: MANDATORY

Every rule in this document is mandatory. Violating any point is an implementation error.

---

## I. Core Principles

**Documentation first.** Before writing/changing code: read existing code, related modules, LÖVE2D docs (`.kilo/documentation/`, `SYMBOLS.md`), and docs for any library used. Never guess at APIs, invent methods, or change architecture you don't understand.

**Check before proposing.** Before proposing a refactor, optimization, or architectural change: check section VIII (Rejected / Settled Questions) below. If the same idea was already considered and rejected, don't re-propose it without new information. If you're unsure whether something in the codebase was already discussed, tried, or reverted, check `CHANGELOG.md` before assuming it's unaddressed — it has the full history that this file only summarizes.

**Simplicity first.** Fewer lines, fewer entities, fewer abstractions, no magic. No premature complexity, no pattern-for-pattern's-sake, no over-engineering.

**Modular architecture.** One module = one responsibility. High cohesion inside a module, low coupling between modules, predictable public interfaces, minimal dependencies. No god objects, no do-everything managers, no circular or hidden dependencies.

**Composition over inheritance.** Inheritance only for genuine "is-a" relationships. No deep inheritance chains, no architecture built around base classes. Justify every new dependency.

**Data-driven design.** Game data (config, balance, items, entities, world, content, mods, sprites/components, GLSL shaders embedded in Lua, tweens/easing curves, tag→animation/tween mappings) lives in Lua data files, not in code. No hardcoded parameters, no duplicated data, no balance values in logic code.

**Modding first.** Data must be overridable, mods can extend or replace content, mod errors must be handled safely (never crash the base game).

**Rationale comments only.** Comment only to explain *why*, document a non-obvious contract, or as LuaDoc type annotations. If code is self-explanatory without it, don't write it. When unsure, don't write it.

**Read before write.** Study the target file, related modules, and existing patterns before editing. No blind rewrites, no introducing a new style into an existing system, no unnecessary architectural breakage.

**Minimal changes.** No surprise refactors, mass renames, project-wide style changes, or unrequested architectural rework. Fix only what the task requires.

**LÖVE2D first.** Check LÖVE2D's built-in capabilities before reaching for a third-party solution. Prefer engine APIs and already-used libraries. Don't duplicate engine functionality or add a dependency for one function.

**Performance aware.** Working implementation → measure → optimize, in that order. No premature micro-optimization or complexity added for hypothetical performance.

---

## II. File Organization

```
Foragers/
├── conf.lua
├── Main.lua
├── Source/
│   ├── Helpers/
│   │   ├── Canvas.lua               # Virtual canvas (inner/outer modes)
│   │   ├── AttackSystem.lua         # Weapon attack loop: target pick, deploy, damage, tween
│   │   ├── ComponentRegistry.lua    # Component factory registry
│   │   ├── DrawOrder.lua            # zKey sort buffer (reusable module-level)
│   │   ├── EventEmitter.lua         # Event bus (on/emit/removeListener, priority-ordered)
│   │   ├── Events.lua               # Event name constants (single source of truth)
│   │   ├── Log.lua                  # Log.error wrapper (extension point for file logging)
│   │   ├── ModLoader.lua            # Mod loader (loadAllMods only, no hot-reload)
│   │   └── ShaderLoader.lua         # Shader loading/rendering
│   ├── Sprite/
│   │   ├── Sprite.lua               # Base sprite + xpcall-safe component dispatch
│   │   ├── SpriteLoader.lua         # File scanning + shared sprite instantiation
│   │   └── Components/
│   │       ├── Collision.lua        # AABB collision, terrain/solid registries
│   │       ├── Control.lua          # Input; sole writer of _state/flipX
│   │       ├── Destructible.lua     # HP, takeDamage, dead-sprite tracking
│   │       ├── Follow.lua           # Follow-target smoothing + deployTo/recall (tools)
│   │       ├── ParticleEmitter.lua  # Particle spawner
│   │       ├── Sound.lua            # Sounds triggered by events
│   │       ├── Spritesheet.lua      # Unified quad animation + spritesheet (merged Animation)
│   │       ├── Tween.lua            # Merged Tween component + data class + easing (was Tweens.lua)
│   │       └── Weapon.lua           # Weapon data container (range, cooldown, damage, swing)
│   └── World/
│       ├── TilePalette.lua          # Adjacency mask → tile index/variant
│       ├── WorldBuilder.lua         # Sprite construction from world data (was in Generator)
│       └── WorldGen.lua             # Pure data generation, no sprite dependencies (was in Generator)
├── Content/
│   ├── Assets/{Shaders,Sprites/{Character,Props,Tiles,Tools,UI},...}
│   └── Data/{Options.lua, World.lua}
└── Mods/<Name>/Mod.lua              # { name }, may call ComponentRegistry.register
```

Rules: one module per file, clear file/module names, no junk directories, every folder has an obvious purpose.

---

## III. Component System

Sprite is a composite entity; behavior is added via components. **Components never read another component's fields in `update()` — cross-component communication is events only.**

### Sprite — Error-safe dispatch

`Sprite:update(dt)` and `Sprite:draw()` wrap every component call in `xpcall(handler, debug.traceback)`. On failure:
1. `Log.error()` prints the error and stack trace (visible when `t.console = true`)
2. `component._broken = true` — component is skipped in all future frames (no error spam)
3. Other components continue unaffected

StaticSprite rendering and `sortY` update are trivial — not wrapped.

### Components

- **Sprite** (`Sprite.lua`): holds `x`, `y`, `components`, `tweens`, `_state`, `flipX`. `:update(dt)` drives components with xpcall; `:draw()` draws `image` directly if `type == "StaticSprite"`, else delegates to components. Three draw passes: `drawBehind = true` (background), normal, then `drawOnTop = true` (debug wireframes). `:addComponent()` sets `component.parent`, calls `component:attach()`. `:on/:emit/:removeListener` proxy to `self._events`.

- **SpriteLoader** (`SpriteLoader.lua`): two responsibilities, kept separate.
  - `instantiate(data, x, y, pngPath)` — **public**, ~30 lines, the single source of truth for turning a data table into a live `Sprite`: `Sprite.new()`, field copy, `ComponentRegistry.create(compData.component, compData)` per entry in `data.components`, PNG load via pcall, `type = "StaticSprite"` if no components. No file-system dependency — takes `pngPath` as a parameter, so it works identically whether `data` came from a `.lua` file or was built programmatically (e.g. by `WorldBuilder`).
  - `loadAll(assetsPath, spawnCallback)` — file scanning only. Recursively finds `.lua` files, `require`s each, derives the matching `.png` path, calls `instantiate()`, then `spawnCallback`.
  - **Rule:** any code that needs to turn a data table into a sprite calls `SpriteLoader.instantiate()`. Never re-implement `Sprite.new()` + `ComponentRegistry.create()` loop elsewhere — that duplication is exactly what caused the old `Generator.lua` to drift out of sync with `SpriteLoader`.

- **Spritesheet** (`Spritesheet.lua`): unified component (merged `Animation.lua`). Subscribes to `state_changed` (priority 5), switches animation. `update()` advances frames, emits `anim_frame`. `draw()` reads `parent.flipX` (render-only) and `parent.tweens.scale_x/y`. Quad generation from `columns`/`rows`; auto-infers from image dimensions if absent, explicit values validated with `assert`.

- **Collision** (`Collision.lua`): AABB collision (`solid`/`detect`/`solid_and_detect`). Two static registries: `terrainColliders` (grounded detection, `registerAsTerrain()`) and `solidColliders` (collision blocking, `registerAsSolid()`). Emits `grounded_changed` on change. Sliding collision resolution (try X, then Y). Never writes `parent._state`/`parent._grounded`.

- **Control** (`Control.lua`): keyboard/mouse input. **Sole writer** of `parent._state` and `parent.flipX`. Writes field, then emits (field-write-before-emit). Subscribes to `grounded_changed` (priority 10), caches into `self._grounded`.

- **Destructible** (`Destructible.lua`): HP, `takeDamage`, dead-sprite tracking. Supports `replaceWith` config — a path to another sprite data file (e.g. `"Content/Assets/Sprites/Props/OakStump"`). When the sprite dies, `replaceWith` is stored on `sprite._replaceWith`; Main.lua reads it during dead cleanup and spawns the replacement at the same position (spritesheet → single random frame, collision registered as solid/slowdown, other components added normally).

- **Follow** (`Follow.lua`): follow-target smoothing with exponential easing; subscribes to `flipped` to cache follow direction (never reads `flipX` in `update()`). `leanAngle` + `leanThreshold` for horizontal-lean on movement. `deployTo(target, offsetX, offsetY)` overrides follow target to a prop (weapon attack); `recall()` restores character follow. Draws `parent.image` with pivot.

- **Tween** (`Tween.lua`): subscribes to `flipped` (10), `state_changed` (10), `prop_hit` (10); drives `parent.tweens` (producer). Supports `loop`, `pingPong`, `Sine` curve (quarter-sine 0→1). Module exports `{Component, Tween, Easing}` — `Tween` data class and `Easing` table are available for non-component consumers (UI, camera) via `require("Source.Sprite.Components.Tween")`.

- **Sound** (`Sound.lua`): subscribes to `grounded_changed` (15), `state_changed` (15), `anim_frame` (15). Uses `base:clone()` on play — pooling rejected as premature optimization (~4 clones/sec, negligible GC pressure; also technically inferior — LÖVE `Source` buffers can't be swapped post-clone, so a shared-tag pool would need N clones *per variant*, not per tag).

- **ParticleEmitter** (`ParticleEmitter.lua`): subscribes to `state_changed` (8), `flipped` (12), `anim_frame` (13). Supports one-shot burst emission via `burstOn` config (`{ [eventName] = true }`) at priority 5 — particles spawn into a module-level `orphanParticles` table that survives parent sprite cleanup. Exports `updateOrphans(dt)` / `drawOrphans()` for Main.lua. `burstCount` (default 1) and `burstRadius` (default 0) control burst quantity and spread. Lazy-requires `ComponentRegistry` inside `_spawn()` to break circular dependency. Spawns particle visuals via `ComponentRegistry.create("spritesheet", data)`, not a direct constructor call.

- **Weapon** (`Weapon.lua`): weapon data container (range, cooldown, damage, swing params). Read-only data, no behavior — pure config consumed by `AttackSystem`.

---

## IV. Event System

**EventEmitter** (`Source/Helpers/EventEmitter.lua`): `.new()`, `on(event, cb, priority=100)` (lower runs first), `emit(event, ...)`, `removeListener`, `clear`. Dispatch is synchronous, ascending priority.

**Events** (`Source/Helpers/Events.lua`) — single source of truth for event name strings:

| Event | Emitter | Listeners (priority) |
|---|---|---|
| `STATE_CHANGED` | Control | Spritesheet(5), Shader(7), ParticleEmitter(8), Tween(10), Sound(15) |
| `FLIPPED` | Control | Tween(10), Shader(11), ParticleEmitter(12) |
| `GROUNDED_CHANGED` | Collision | Control(10), Sound(15) |
| `ANIM_FRAME` | Spritesheet (from `update()`, not `draw()`) | Sound(15), ParticleEmitter(13) |
| `SLOWDOWN_CHANGED` | Collision | Control(10) |
| `SLOWDOWN_ENTER` | Collision (emitted on slowdown zone sprite) | Tween(10) |
| `SLOWDOWN_EXIT` | Collision (emitted on slowdown zone sprite) | Tween(10) |
| `PROP_HIT` | AttackSystem (emitted on damaged target) | Shader(8), Tween(10), Sound(15) |
| `PROP_BROKEN` | Destructible (emitted on death); AttackSystem (relayed to weapon sprite) | Sound(15), Shake(5) |
| `SWING` | AttackSystem (emitted on weapon swing start) | — |

**Rules:**
- Subscriptions happen at construction (`new()`/`attach()`), before the game loop starts — no "first frame" fallback reads needed.
- Priority gaps of 5 (5/10/15) leave room to insert future listeners without renumbering.
- **Priority gaps:** STATE_CHANGED and FLIPPED rows use tight priorities (7↔8, 10↔11↔12) — inserting Shader between existing listeners left no gap of 5 without renumbering existing components, which was deemed higher risk than tight spacing.
- **Field exceptions** (only these four, justify before adding more):
  1. `parent.flipX` / `parent._state` — plain fields, readable **only inside `draw()`** for rendering (sprite flip, debug). Never read in `update()`/logic.
   2. `parent.tweens` — single producer (Tween) / multi-consumer (Spritesheet, Follow, Shader), continuous numeric data; not worth an event per frame.
  3. `parent.alpha` — render-only opacity (0–1), written by ProximityFade in `update()`, read by Sprite/Spritesheet/Follow in `draw()`. Same justification as `parent.flipX`: continuous render parameter, not worth an event per frame.
  4. `parent.shader` / `parent.shaderData` — per-sprite shader reference and uniform data. Shader reference is set once on component attach, read in draw(). shaderData is written by ShaderComponent in update(), read by Sprite in draw(). Same justification as tweens: uniform values are continuous render parameters (brightness) that change every frame; not worth an event per uniform per frame.
- **Field-write-before-emit**: if a signal has both a field and an event (`_state`, `flipX`), write the field first, then emit.
- **Single-writer rule**: `_state` has exactly one writer, Control. If Collision needs to force a state (e.g. "swimming"), it emits `state_changed` and lets Control reconcile the field on its next tick — it never writes `_state` itself.

---

## V. Component Registry

`Source/Helpers/ComponentRegistry.lua`: `.register(name, factory)`, `.create(name, data)` (nil if unknown). Pre-registers the 10 core components on module load — `"collision"`, `"control"`, `"destructible"`, `"follow"`, `"particle_emitter"`, `"shader"`, `"sound"`, `"spritesheet"`, `"tween"`, `"weapon"`. Mods register new types the same way:
```lua
ComponentRegistry.register("my_component", function(data) return MyComponent.new(data) end)
```

---

## VI. World / Shader / Draw / Tween / Mod Systems

- **WorldGen.lua** (`Source/World/WorldGen.lua`): `generate(config)` → pure-data world table. `config` is a single table (`{width, height, seed, scale, density, detail}`) — never positional arguments, to avoid silently swapping same-typed parameters. Uses `love.math.noise` + circular island mask. No sprite/component dependencies. Split from the old Generator.lua.

- **WorldBuilder.lua** (`Source/World/WorldBuilder.lua`): exports **only** `build(tileData, config)`. Internally calls private (non-exported) `buildTerrain()` then `spawnProps()`, in that fixed order — this ordering is enforced by encapsulation, not convention, so it cannot be called out of sequence from outside the module. Both internal steps build sprites via `SpriteLoader.instantiate()` (not manual `Sprite.new()`/`ComponentRegistry.create()` calls) to avoid re-diverging from `SpriteLoader`, and each resets its own collider registry (`Collision.resetTerrain()` / `resetSolids()`) before populating. Props use weighted random + Fisher-Yates shuffle. Split from the old Generator.lua.

- **DrawOrder.lua** (`Source/Helpers/DrawOrder.lua`): `collect(entries)` fills a reusable module-level buffer with `zKey = layer * 1e6 + sortY * 1e3 + x`; `sort(list)` sorts by `zKey`. Called once per frame, single caller. No double-call guard by design — see Stage 6.2 in the history table for why this was audited and left as-is.

- **ShaderLoader.lua** (`Source/Helpers/ShaderLoader.lua`): scans `Content/Assets/Shaders/` recursively; each file returns `{name, applies_to, priority, uniforms, code}`; compiles GLSL via `love.graphics.newShader`; `drawBackground()` / `update(dt)`.

- **Canvas.lua** (`Source/Helpers/Canvas.lua`): virtual canvas, `mode="inner"` (fixed res, centered/bordered) or `"outer"` (fills window). `:draw(drawFunc, clearColor)`, `:resize(w, h)`.

- **TilePalette.lua** (`Source/World/TilePalette.lua`): `resolve(mask, tileMap)`, `resolveVariant(index, variants, seed)`.

- **ModLoader.lua** (`Source/Helpers/ModLoader.lua`): `loadAllMods(path)` scans and loads each `Mod.lua`. All wrapped in `pcall` — a broken mod cannot crash the game. **Hot-reload (`reloadAll()`) was removed** — fragile `package.loaded[nil]` pattern with no real use case.

---

## VII. Error Handling & Debugging

### Error isolation

- `Sprite:update()` and `Sprite:draw()` wrap every `component:update(dt)` / `component:draw()` in `xpcall(component.fn, debug.traceback, component, dt)`.
- On failure: `Log.error("[component_type]" .. msg)` prints the component type and full Lua stack trace.
- `component._broken = true` skips the component on all subsequent frames.
- StaticSprite rendering and `sortY` update are not wrapped (trivial, cannot fail silently).

### Log.lua

`Source/Helpers/Log.lua` — single extension point for all error output. Currently wraps `print("[ERROR] " .. msg)`. Swap the implementation here (e.g., to file I/O) to change where all errors go, without touching callers.

### conf.lua — console = false

`t.console = false` in `conf.lua` is **required** when using the VS Code Lua Debugger (`lua-local`/LuaPanda). Setting `t.console = true` causes a black screen on F5 launch. When running standalone (`.bat`/`.exe` without debugger), you may set `t.console = true` to see `Log.error()` output in a console window, but this breaks the VS Code debugger.

---

## VIII. Rejected / Settled Questions

Read this before proposing a change in these areas — it was already considered and closed. Don't re-litigate without a genuinely new argument or new evidence (e.g. profiling data that didn't exist before).

| Question | Verdict | Why |
|---|---|---|
| Pool `Sound` sources instead of `base:clone()`? | **Rejected** | ~4 clones/sec at current usage — negligible GC pressure, no measured stutter. Also technically inferior: LÖVE `Source` buffers can't be swapped after `clone()`, so a pool would need N clones *per sound variant*, not per tag — more memory than the thing it replaces. Revisit only if profiling shows an actual problem (e.g. many NPCs with footsteps at once). |
| Guard `DrawOrder.collect()` against being called twice per frame? | **Rejected** | Moving the buffer clear to the start of `collect()` doesn't fix anything — data from a first call is still lost either way. It's slightly slower per frame (clears the full buffer instead of just the tail) and there is no double-call site in the codebase, planned or otherwise. The module-level `sortBuffer` remains shared state; if a second caller is ever introduced, solve it by passing an explicit buffer, not by reordering the clear. |
| Add a scene/game-state machine (menu, pause, restart) to Main.lua? | **Deferred, not rejected** | Not needed while there's no menu/pause/restart flow planned. If it becomes needed: keep it to a plain string state variable switched on in `love.update`/`love.draw` — no framework, no scene-graph classes. |
| Add ModLoader integration for mod-provided sprites/tiles/props/world hooks? | **Deferred, not rejected** | `ModLoader` can currently only register new component types — there's no entry point for mod content. Undecided whether mods are a real goal for this project; don't build integration speculatively. |

For the full chronological history of what changed and when (Animation+Spritesheet merge, Tween merge, Generator split, error hardening, etc.), see `CHANGELOG.md` — it's not required reading for a normal task, but check it if you're unsure whether something was already tried, or need to understand why a module looks the way it does.

---

## IX. Completion Criteria

A task is done only if: it works; the architecture is intact; new dependencies are justified; modding is not broken; the code follows every rule above. **When implementation speed conflicts with architectural quality, architecture wins.**
