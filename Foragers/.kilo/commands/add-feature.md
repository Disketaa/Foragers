---
description: Guide for adding a new feature to Foragers
---

## Before you start

1. Read `.kilo/AGENTS.md` — architecture rules, component system, event system, error handling
2. Study the nearest existing implementation of a similar feature
3. Check `.kilo/documentation/` for LÖVE2D API docs

## Adding a new feature

### 1. Data first

New game content (items, entities, world config, sprites, animations) goes in `Content/Data/` or `Content/Assets/Sprites/` as Lua data tables. No hardcoded values in logic code.

### 2. Choose the right module

- **New sprite type** — add data file in `Content/Assets/Sprites/<Category>/<Name>.lua`; `SpriteLoader.loadAll()` picks it up automatically
- **New component** — register via `ComponentRegistry.register("name", factoryFn)` in the data file or from a mod's `Mod.lua`; place the module in `Source/Sprite/Components/`
- **New world generation logic** — pure data goes in `Source/World/WorldGen.lua`, sprite construction in `Source/World/WorldBuilder.lua`
- **New helper/system** — place in `Source/Helpers/`; one module = one responsibility

### 3. Component communication

Components communicate via events, not field reads. If a new component needs data from another:
- Subscribe to an existing event from `Events.lua`
- If no existing event fits the signal, add it to `Events.lua` and add its row to `events.md` with documented emitters and priorities
- Never read another component's fields in `update()` (four field exceptions documented in AGENTS.md §X)
- Use priority gaps of 5 when subscribing (AGENTS.md §X)

### 4. Error handling

- Component `update()` and `draw()` are already wrapped in `xpcall` by `Sprite.lua`
- On error: `Log.error()` prints the stack trace, `component._broken = true` disables the component
- If your code runs outside `update()`/`draw()` (e.g. `attach()`), wrap in your own `xpcall` or `pcall`
- Log errors through `Log.error()` — swap implementation in `Log.lua` when file logging is needed

### 5. Data files for sprites

PNG image path is **auto-derived** from the `.lua` file path (same name, `.png` extension) — do NOT specify it in the data file. The `spriteSheet` field is injected internally by `SpriteLoader.instantiate()`.

```lua
return {
	object = "myEntity",          -- string identifier (optional)
	frameWidth = 16,              -- sprite frame dimensions (required for spritesheet animation)
	frameHeight = 16,
	pivotX = 0.5,                 -- draw pivot (0-1), default 0
	pivotY = 0.75,
	sortOffsetY = 2,              -- Y-sort draw offset in pixels
	layer = 0,                    -- draw layer (higher = drawn later)
	components = {
		{
			component = "spritesheet",
			columns = 4,          -- auto-inferred from image if omitted
			rows = 5,            -- auto-inferred from image if omitted
			animations = {
				idle = { row = 1, frames = 4, speed = 4, loop = true },
				run  = { row = 2, frames = 4, speed = 8, loop = true },
			},
		},
		-- additional components: collision, tween, sound, etc.
	},
}
```

Reference existing files: `Content/Assets/Sprites/Character/Character.lua`, `Content/Assets/Sprites/Props/Rocks.lua`.

### 6. Mod support

If the feature should be overridable by mods:
- Keep data in Lua tables, register components via `ComponentRegistry`
- Mods load their `Mod.lua` which can call `ComponentRegistry.register()` to add or override
- All mod operations are wrapped in `pcall` — a broken mod must never crash the base game

## Debugging

### If the feature doesn't work

1. **Enable console** — temporarily set `t.console = true` in `conf.lua` (revert before commit; VS Code debugger requires `false`)
2. **Check for `[ERROR]` messages** — component errors are logged via `Log.error` with component type and traceback
3. **Check `_broken` flag** — if a component crashed once, it's silently skipped on all subsequent frames
4. **Verify event wiring** — ensure events are emitted by the right module, subscribed with correct priority, and that event names match `Events.lua` constants
5. **Check image paths** — `SpriteLoader` loads `.png` matching the data file path via `pcall`; if the image is missing, the sprite loads silently without an image
6. **Check `assert` in Spritesheet** — if `columns`/`rows` are explicitly set, Spritesheet validates them against actual image dimensions at load time
7. **Console-only logging** — add temporary `print()` calls if `Log.error` doesn't provide enough context (wrap in `if t.console then ... end` to avoid debugger conflict)

### Common issues

| Symptom | Likely cause |
|---|---|
| Sprite not visible | Image missing at computed path (PNG must match `.lua` filename in same directory) |
| Component not responding | `_broken = true` after earlier error; check console |
| State never changes | Control is sole writer of `_state` — emit `state_changed` instead of writing directly |
| Event not received | Wrong priority, wrong event string, or subscription happens too late (must be in `attach()`) |
| Tween not animating | Tween subscribes to `state_changed` and `flipped` — trigger one of these, or check the tween data syntax |

## Pre-flight to-do check

Before finishing, verify each:

- [ ] All gameplay values in `Content/Data/` or `Content/Assets/Sprites/`, not hardcoded (AGENTS.md §I)
- [ ] Components communicate via events only — no field reads across components in `update()` (§I, §X)
- [ ] `parent._state` never written outside Control — emit `state_changed` instead (§I)
- [ ] Priority gaps of 5 on all event subscriptions (§X)
- [ ] No manual `Sprite.new()` / `ComponentRegistry.create()` — used `SpriteLoader.instantiate()` (§I)
- [ ] Every new event constant in `Events.lua` has a row in `events.md` (§II)
- [ ] Mod errors won't crash base game — all mod code wrapped in `pcall` (§V)
- [ ] All changed docs cross-referenced: `components.md`, `events.md`, `data-format.md` if applicable (§II)
- [ ] Rationale comments only — no "what" comments that just restate code (§V)
- [ ] Stale section references in docs updated to match current AGENTS.md chapter numbers (§II)

## Reference

- `.kilo/AGENTS.md` — full architecture, component rules, event system, error handling
- `.kilo/documentation/components.md` — component config fields, subscribed/emitted events
- `.kilo/documentation/events.md` — all events, emitters, listener priorities
- `.kilo/documentation/data-format.md` — sprite data file format
- `Source/Sprite/Sprite.lua` — base sprite, xpcall dispatch
- `Source/Helpers/Events.lua` — all event constants
- `Source/Helpers/ComponentRegistry.lua` — component registration
- `Source/Helpers/EventEmitter.lua` — event bus API
- `Source/Sprite/Components/Spritesheet.lua` — quad generation, animation switching
- `Source/Sprite/Components/Tween.lua` — tween data class, easing curves
- `Source/World/WorldGen.lua` — pure data generation
- `Source/World/WorldBuilder.lua` — sprite construction from world data
