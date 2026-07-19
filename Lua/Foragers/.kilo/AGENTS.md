# AGENTS.md

## STATUS: MANDATORY

Every rule in this document is mandatory. Violating any point is an implementation error.

## Documentation

| Document | Purpose |
|---|---|
| `AGENTS.md` | This file — mandatory rules, architecture, principles |
| `CHANGELOG.md` | Full history of architecture changes (check before proposing refactors) |
| `.kilo/documentation/love_api.md` | LÖVE2D API reference (grep, never read top-to-bottom) |
| `.kilo/documentation/components.md` | Component cheat sheet — purpose, config, events |
| `.kilo/documentation/data-format.md` | Sprite data file format specification |
| `.kilo/documentation/events.md` | Event system reference — all events, emitters, priorities |

---

## I. Core Principles

**Documentation first.** Before writing/changing code: read existing code, related modules, LÖVE2D docs (`.kilo/documentation/love_api.md`), and docs for any library used. Never guess at APIs, invent methods, or change architecture you don't understand.

**Check before proposing.** Before proposing a refactor, optimization, or architectural change: check section VIII (Rejected / Settled Questions) below. If the same idea was already considered and rejected, don't re-propose it without new information. If you're unsure whether something in the codebase was already discussed, tried, or reverted, check `.kilo/CHANGELOG.md` before assuming it's unaddressed — it has the full history that this file only summarizes.

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
│   │   ├── Math.lua                 # Math utilities (expSmooth, parseRandomValue, parseRange)
│   │   ├── Merge.lua                # Data merge / extends resolution
│   │   ├── ModLoader.lua            # Mod loader (loadAllMods only, no hot-reload)
│   │   ├── Path.lua                 # Path conversion helpers (lua/png/moduleToPath)
│   │   └── ShaderLoader.lua         # Shader loading/rendering
│   ├── Sprite/
│   │   ├── Sprite.lua               # Base sprite + xpcall-safe component dispatch
│   │   ├── SpriteLoader.lua         # File scanning + shared sprite instantiation
│   │   └── Components/
│   │       ├── Collision.lua        # AABB collision, terrain/solid registries
│   │       ├── Control.lua          # Input; sole writer of _state/flipX
│   │       ├── Destructible.lua     # HP, takeDamage, dead-sprite tracking
│   │       ├── Drop.lua             # Drop spawn on PROP_BROKEN (pending queue, scatter tween)
│   │       ├── Follow.lua           # Follow-target smoothing + deployTo/recall (tools)
│   │       ├── ParticleEmitter.lua  # Particle spawner
│   │       ├── ProximityFade.lua    # Fades alpha based on player distance
│   │       ├── ScrollTo.lua         # Smooth camera follow (centers camera on target)
│   │       ├── Shader.lua           # Shader uniform management (brightness)
│   │       ├── Shake.lua            # Screen shake on PROP_BROKEN
│   │       ├── Sound.lua            # Sounds triggered by events
│   │       ├── Spritesheet.lua      # Unified quad animation + spritesheet (merged Animation)
│   │       ├── Tween.lua            # Merged Tween component + data class + easing (was Tweens.lua)
│   │       └── Weapon.lua           # Weapon data container (range, cooldown, damage, swing)
│   └── World/
│       ├── TilePalette.lua          # Adjacency mask → tile index/variant
│       ├── WorldBuilder.lua         # Sprite construction from world data (was in Generator)
│       ├── WorldGen.lua             # Pure data generation, no sprite dependencies (was in Generator)
│       └── PropSpawner.lua          # Periodic prop spawn at unoccupied tiles
├── Content/
│   ├── Assets/{Shaders,Sprites/{Character,Props,Tiles,Tools,UI},...}
│   └── Data/{Options.lua, World.lua}
└── Mods/<Name>/Mod.lua              # { name }, may call ComponentRegistry.register
```

Rules: one module per file, clear file/module names, no junk directories, every folder has an obvious purpose.

---

## III. Component System

Sprite is a composite entity; behavior is added via components. **Components never read another component's fields in `update()` — cross-component communication is events only.**

Full component reference: `.kilo/documentation/components.md`

### Sprite — Error-safe dispatch

`Sprite:update(dt)` and `Sprite:draw()` wrap every component call in `xpcall(handler, debug.traceback)`. On failure:
1. `Log.error()` prints the error and stack trace (visible when `t.console = true`)
2. `component._broken = true` — component is skipped in all future frames (no error spam)
3. Other components continue unaffected

StaticSprite rendering and `sortY` update are trivial — not wrapped.

### Components (summary)

14 core components: `collision`, `control`, `spritesheet`, `tween`, `sound`, `particle_emitter`, `follow`, `destructible`, `weapon`, `shake`, `proximity_fade`, `shader`, `drop`, `scroll_to`.

- **Sprite** (`Sprite.lua`): base entity. `:update()` drives components with xpcall; `:draw()` draws `image` directly if `type == "StaticSprite"`, else delegates. Three draw passes: `drawBehind`, normal, `drawOnTop`.
- **SpriteLoader** (`SpriteLoader.lua`): `instantiate(data, x, y, pngPath)` is the single source of truth for turning data into live sprites. `loadAll()` scans files and calls `instantiate()`.
- **Control** (`Control.lua`): **sole writer** of `parent._state` and `parent.flipX`. Writes field, then emits.
- **Collision** (`Collision.lua`): AABB collision. Two static registries: `terrainColliders` (grounded) and `solidColliders` (blocking). Emits `grounded_changed`.
- **Spritesheet** (`Spritesheet.lua`): quad animation. Subscribes to `state_changed` (5), emits `anim_frame`.
- **Tween** (`Tween.lua`): drives `parent.tweens`. Subscribes to `flipped` (10), `state_changed` (10), `prop_hit` (10), `prop_spawned` (10).
- **Sound** (`Sound.lua`): plays sounds on events. Uses `base:clone()` (~4 clones/sec, negligible GC). Subscribes to `prop_spawned` (15).
- **ParticleEmitter** (`ParticleEmitter.lua`): spawns particles on events or states.
- **Follow** (`Follow.lua`): follow-target smoothing. `deployTo()`/`recall()` for weapon attacks.
- **Destructible** (`Destructible.lua`): HP, `takeDamage`, dead-sprite tracking. Supports `replaceWith`.
- **Drop** (`Drop.lua`): spawns drops on `PROP_BROKEN`. Supports range/choice syntax for count.
- **Weapon** (`Weapon.lua`): data container (range, cooldown, damage, swing). Read-only.
- **Shake** (`Shake.lua`): screen shake on `PROP_BROKEN`.
- **ProximityFade** (`ProximityFade.lua`): fades alpha based on player distance.
- **Shader** (`Shader.lua`): manages shader uniforms (brightness). Subscribes to `prop_hit` (8).

---

## IV. Event System

**EventEmitter** (`Source/Helpers/EventEmitter.lua`): `.new()`, `on(event, cb, priority=100)` (lower runs first), `emit(event, ...)`, `removeListener`, `clear`. Dispatch is synchronous, ascending priority.

**Events** (`Source/Helpers/Events.lua`) — single source of truth for event name strings. Full event table with emitters and listeners: `.kilo/documentation/events.md`

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

`Source/Helpers/ComponentRegistry.lua`: `.register(name, factory)`, `.create(name, data)` (nil if unknown). Pre-registers the 14 core components on module load — `"collision"`, `"control"`, `"destructible"`, `"drop"`, `"follow"`, `"particle_emitter"`, `"proximity_fade"`, `"scroll_to"`, `"shader"`, `"shake"`, `"sound"`, `"spritesheet"`, `"tween"`, `"weapon"`. Mods register new types the same way:
```lua
ComponentRegistry.register("my_component", function(data) return MyComponent.new(data) end)
```

---

## VI. World / Shader / Draw / Tween / Mod Systems

- **WorldGen.lua** (`Source/World/WorldGen.lua`): `generate(config)` → pure-data world table. `config` is a single table (`{width, height, seed, scale, density, detail}`) — never positional arguments, to avoid silently swapping same-typed parameters. Uses `love.math.noise` + circular island mask. No sprite/component dependencies. Split from the old Generator.lua.

- **WorldBuilder.lua** (`Source/World/WorldBuilder.lua`): exports **only** `build(tileData, spawnCallback, playerSprite)`. `playerSprite` (optional) — when provided, excludes the player's tile from initial prop spawn via collision-rect overlap check (replaces old `spawnClearance` config). Internally calls private (non-exported) `buildTerrain()` then `spawnProps()`, in that fixed order — this ordering is enforced by encapsulation, not convention, so it cannot be called out of sequence from outside the module. Both internal steps build sprites via `SpriteLoader.instantiate()` (not manual `Sprite.new()`/`ComponentRegistry.create()` calls) to avoid re-diverging from `SpriteLoader`, and each resets its own collider registry (`Collision.resetTerrain()` / `resetSolids()`) before populating. Props use weighted random + Fisher-Yates shuffle. Consumes `WorldConfig.tileSize`, `WorldConfig.props`, `WorldConfig.propCoverage`. Split from the old Generator.lua.

- **PropSpawner.lua** (`Source/World/PropSpawner.lua`): `init(worldData, worldConfig, opts)` where `opts = {playerSprite}`. `update(dt)` accumulates a timer based on `worldConfig.propSpawnInterval`; when it elapses, collects all active tiles not occupied by any solid/slowdown collider or the player (via point-in-rect using each collider's `.sprite` reference position), picks a random free tile, weighted-random picks a prop from `worldConfig.props`, spawns via `SpriteLoader.instantiate()`, emits `PROP_SPAWNED`, registers collision, and returns the new sprite. The caller (Main.lua) appends it to objects/dynamicObjects.

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

For the full chronological history of what changed and when (Animation+Spritesheet merge, Tween merge, Generator split, error hardening, etc.), see `.kilo/CHANGELOG.md` — it's not required reading for a normal task, but check it if you're unsure whether something was already tried, or need to understand why a module looks the way it does.

---

## IX. Completion Criteria

A task is done only if: it works; the architecture is intact; new dependencies are justified; modding is not broken; the code follows every rule above. **When implementation speed conflicts with architectural quality, architecture wins.**
