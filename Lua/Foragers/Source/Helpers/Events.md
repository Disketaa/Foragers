# Event Contract

## Events

| Event | Payload | Emitter | Listeners (priority) |
|-------|---------|---------|----------------------|
| `state_changed` | `newState: string, oldState: string\|nil` | `Control:update()` — field-then-emit for moving/idle/swimming | `Animation` (5) — switches animation; `Tween` (10) — splash detection; `Sound` (15) — state sound |
| `flipped` | `flipX: boolean` | `Control:update()` | `Tween` (10) — flip tween |
| `grounded_changed` | `isGrounded: boolean` | `Collision:update()` — only on actual change | `Control` (10) — caches for swimming speed; `Sound` (15) — water_in/water_out |
| `anim_frame` | `frameIndex: number` (1-based) | `Animation:update()` — on frame index change | `Sound` (15) — step sounds |

## Field Exceptions

### `parent._state`, `parent.flipX`
- **Writers**: `Control` only (single-writer rule)
- **Readers (render-only)**: `Animation:draw()` reads `flipX` for `sx` negation and `_state` is not read directly (animation is driven by `state_changed` event)
- **Why**: Renderer needs to know current visual state. These are read during `draw()` only, never in `update()` logic.

### `parent.tweens`
- **Writer**: `Tween` writes scale_x/scale_y via `update()` tween advancement
- **Reader**: `Animation:draw()` reads tweens for scale transforms
- **Why**: Continuous numeric data updated every frame; wrapping in events would mean firing an event every frame for a pure data handoff. Single producer/single consumer.

## Priority Convention

Priorities are spaced by 5 to allow future components to slot in:

- 5: Animation switching (`Animation`)
- 10: Tween triggers (`Tween`), grounded caching (`Control`)
- 15: Sound triggers (`Sound`)

## Field-Write-Before-Emit Rule

When a signal has both a field and an event (`_state`, `flipX`), the component writes the field first, then emits. This guarantees handlers see the current field value if they read it for debug/logging.

## Mod Extension

A mod registers a new component type:

```lua
-- Mods/MyMod/Mod.lua
local ComponentRegistry = require("Source.ComponentRegistry")

local MyComponent = {}
-- ... implementation ...

ComponentRegistry.register("my_component", function(data)
  return MyComponent.new(data)
end)

return {
  name = "MyMod",
}
```