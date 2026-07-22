# AGENTS.md — MANDATORY FOR ALL TASKS

**BEFORE EVERY TASK: Read this file, then read `.kilo/ABSTRACTIONS.md`. If the task touches LÖVE2D APIs, grep `.kilo/documentation/love_api.md`. If it touches components, read `.kilo/documentation/components.md`. If it touches events, read `.kilo/documentation/events.md`. If unsure whether a doc applies, read it. Non-negotiable. No exceptions.**

Every rule in this document is mandatory. Violating any point is an implementation error. "I didn't know" is not valid — the docs were available and you were told to read them.

**When implementation speed conflicts with architectural quality, architecture wins.**

---

## I. Critical Constraints

These rules are NEVER optional. Violating any is an implementation error.

- **NEVER guess at APIs.** Read existing code, related modules, and LÖVE2D docs before writing. If you don't understand the architecture, you MUST NOT change it.
- **NEVER read another component's fields in `update()`.** Cross-component communication is events only.
- **NEVER hardcode gameplay values.** Data goes in `Content/Data/` or `Content/Assets/Sprites/`, logic in `Source/`.
- **NEVER instantiate sprites manually** with `Sprite.new()` / `ComponentRegistry.create()`. MUST use `SpriteLoader.instantiate()`.
- **NEVER propose a refactor** without first checking Section XII (Rejected Questions) and `.kilo/CHANGELOG.md`.
- **NEVER write code before reading** the target file, related modules, and existing patterns.
- **MUST keep changes minimal.** No surprise refactors, mass renames, project-wide style changes, or unrequested architectural rework.
- **MUST justify every new dependency.** Prefer engine APIs and already-used libraries. Don't duplicate engine functionality.
- **Control is the SOLE writer** of `parent._state` and `parent.flipX`. If another component needs to force a state, it MUST emit `state_changed` and let Control reconcile — it NEVER writes `_state` itself.

---

## II. Documentation

Grep, don't read top-to-bottom. If unsure whether a doc applies, read it.

| Document | Purpose |
|---|---|
| `.kilo/documentation/love_api.md` | LÖVE2D API reference (grep, ~4800 lines) |
| `.kilo/documentation/components.md` | Component cheat sheet — purpose, config, events |
| `.kilo/documentation/data-format.md` | Sprite data file format specification |
| `.kilo/documentation/events.md` | Event system reference — all events, emitters, priorities |
| `.kilo/ABSTRACTIONS.md` | Hard-won lessons — read relevant section before coding in that subsystem |
| `.kilo/CHANGELOG.md` | Full history of architecture changes (check before proposing refactors) |

---

## III. Commands

```bash
# Lint single file
.\Tools\luacheck.exe Source/Sprite/Components/MyComponent.lua

# Lint all source
.\Tools\luacheck.exe Source/

# Format (run from project root)
python "Tools/Lua Formatter/formatter.py"

# Run game (standalone)
"C:\Path\To\love.exe" .

# Run game — VS Code F5 (debugger)
# conf.lua must have t.console = false
```

---

## IV. Good and Bad Examples

- GOOD: `Source/Sprite/Components/Pickup.lua` — minimal, data-driven, one responsibility
- GOOD: event subscription in `attach()` with priority gap of 5
- GOOD: data in `Content/Data/` or `Content/Assets/Sprites/`, logic in `Source/`
- BAD: any component reading `parent._state` in `update()` — violates single-writer rule
- BAD: reading another component's fields in `update()` — use events
- BAD: hardcoded gameplay values — use data files
- BAD: manual `Sprite.new()` / `ComponentRegistry.create()` — use `SpriteLoader.instantiate()`

---

## V. Core Principles

- **Simplicity first.** Fewer lines, fewer entities, fewer abstractions, no magic. No premature complexity.
- **Modular architecture.** One module = one responsibility. High cohesion, low coupling, no god objects.
- **Composition over inheritance.** Inheritance only for genuine "is-a" relationships.
- **Data-driven design.** Game data lives in Lua data files, not in code. No hardcoded parameters.
- **Modding first.** Data MUST be overridable. Mod errors MUST NEVER crash the base game.
- **Rationale comments only.** Comment only to explain *why* or document a non-obvious contract.
- **LÖVE2D first.** Check LÖVE2D's built-in capabilities before reaching for a third-party solution.
- **Performance aware.** Working implementation → measure → optimize. No premature micro-optimization.

---

## VI. File Organization

```
Foragers/
├── conf.lua
├── Main.lua
├── Source/
│   ├── Helpers/          # EventEmitter, Events, ComponentRegistry, DrawOrder, Log, Math, Merge, ModLoader, Path, ShaderLoader, Canvas, AttackSystem
│   ├── Sprite/
│   │   ├── Sprite.lua
│   │   ├── SpriteLoader.lua
│   │   └── Components/   # collision, control, spritesheet, tween, sound, particle_emitter, follow, destructible, weapon, shake, proximity_fade, shader, drop, scroll_to, shadow, spritefont, ui, player_stats, pickup
│   ├── UI/
│   │   ├── Components/   # TextEmitter, UI
│   │   └── Text.lua
│   └── World/            # TilePalette, WorldBuilder, WorldGen, PropSpawner
├── Content/
│   ├── Assets/{Shaders,Sprites/{Character,Props,Tiles,Tools,UI},...}
│   └── Data/{Options.lua, World.lua}
└── Mods/<Name>/Mod.lua   # { name }, may call ComponentRegistry.register
```

Rules: one module per file, clear file/module names, no junk directories.

---

## VII. Git Workflow

- Commit format: short summary, capitalized, describing what was done (not "updated file X")
- See `.kilo/commands/commit.md` for full workflow
- MUST NOT push unless explicitly asked

---

## VIII. When Stuck

- Read the relevant docs in `.kilo/documentation/` for the subsystem you're working on
- Check `.kilo/CHANGELOG.md` if unsure whether something was already tried
- Check Section XII (Rejected Questions) before proposing a change
- Propose a short plan — do NOT guess

---

## IX. Component System

Sprite is a composite entity; behavior is added via components.

Full component reference: `.kilo/documentation/components.md`

### Key constraints

All Critical Constraints in Section I apply here.

### Error-safe dispatch

`Sprite:update(dt)` and `Sprite:draw()` wrap every component call in `xpcall`. On failure: `component._broken = true` — skipped on all future frames. Other components continue.

### Component list

19 core: `collision`, `control`, `spritesheet`, `tween`, `sound`, `particle_emitter`, `follow`, `destructible`, `weapon`, `shake`, `proximity_fade`, `shader`, `drop`, `scroll_to`, `shadow`, `spritefont`, `ui`, `player_stats`, `pickup`.

---

## X. Event System

Full event table: `.kilo/documentation/events.md`

- Subscriptions happen at construction (`new()`/`attach()`), before the game loop starts.
- Priority gaps of 5 (5/10/15) leave room for future listeners.
  - **EXCEPTION:** STATE_CHANGED and FLIPPED use tight priorities (7↔8, 10↔11↔12) — renumbering existing components was deemed higher risk than tight spacing.
- **Field exceptions** (ONLY these four, justify before adding more):
  1. `parent.flipX` / `parent._state` — readable ONLY inside `draw()` for rendering. NEVER read in `update()`/logic.
  2. `parent.tweens` — single producer (Tween) / multi-consumer, continuous numeric data.
  3. `parent.alpha` — render-only opacity (0–1), written by ProximityFade in `update()`, read in `draw()`.
  4. `parent.shader` / `parent.shaderData` — set once on attach, read in draw(). shaderData written in update(), read in draw().
- **Field-write-before-emit:** if a signal has both a field and an event, write the field first, then emit.
- **Single-writer rule:** `_state` has exactly one writer, Control. NEVER write `_state` from another component.

---

## XI. Component Registry

`Source/Helpers/ComponentRegistry.lua`: `.register(name, factory)`, `.create(name, data)`. Pre-registers 19 core components. Mods register new types:
```lua
ComponentRegistry.register("my_component", function(data) return MyComponent.new(data) end)
```

---

## XII. Rejected / Settled Questions

Read this before proposing a change in these areas — already considered and closed.

| Question | Verdict | Why |
|---|---|---|
| Pool `Sound` sources instead of `base:clone()`? | **Rejected** | ~4 clones/sec — negligible GC. Pooling needs N clones per variant, more memory. Revisit only with profiling. |
| Guard `DrawOrder.collect()` against double-call? | **Rejected** | No double-call site exists. Buffer clear doesn't fix it either way. |
| Scene/game-state machine (menu, pause, restart)? | **Deferred** | Not needed yet. If needed: plain string state variable, no framework. |
| ModLoader integration for mod content? | **Deferred** | Currently only registers component types. No entry point for mod content yet. |

Full history: `.kilo/CHANGELOG.md`

---

## XIII. Output-Time Self-Check

Before generating an implementation, verify internally:

- [ ] Which files MUST be read?
- [ ] Which existing pattern is closest?
- [ ] Which AGENTS.md rules apply?
- [ ] Am I changing architecture or only implementing the requested task?
- [ ] Am I introducing a duplicate system?
- [ ] Am I violating single-writer or cross-component rules?
- [ ] Am I hardcoding values that belong in data files?

---

## XIV. Completion Criteria

A task is done ONLY if: it works; the architecture is intact; new dependencies are justified; modding is not broken; the code follows every rule above.
