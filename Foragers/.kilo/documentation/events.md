---
description: Quick reference for all events — name, emitter, listeners with priorities.
---

# Event System Reference

Source of truth: `Source/Helpers/Events.lua`.

## Event table

| Constant | String | Emitter | Listeners (priority) |
|---|---|---|---|
| `STATE_CHANGED` | `"state_changed"` | Control | Spritesheet(5), ParticleEmitter(8), Tween(10), Sound(15) |
| `FLIPPED` | `"flipped"` | Control | Tween(10), ParticleEmitter(12) |
| `GROUNDED_CHANGED` | `"grounded_changed"` | Collision | Control(10), Sound(15) |
| `ANIM_FRAME` | `"anim_frame"` | Spritesheet | Sound(15), ParticleEmitter(13) |
| `SLOWDOWN_CHANGED` | `"slowdown_changed"` | Collision | Control(10) |
| `SLOWDOWN_ENTER` | `"slowdown_enter"` | Collision | Sound(15) |
| `SLOWDOWN_EXIT` | `"slowdown_exit"` | Collision | Sound(15) |
| `VALUE_CHANGED` | `"value_changed"` | PlayerStats | Counter(5), Main.lua(5) |
| `LOW_SATIETY` | `"low_satiety"` | PlayerStats | Emote(5), Sound(15) |
| `DEATH` | `"death"` | PlayerStats (satiety 0) | Main.lua(5), ParticleEmitter(spawnOn, 5) |
| `PROP_HIT` | `"prop_hit"` | AttackSystem | Shader(8), TextEmitter(5), Tween(10), Sound(15) |
| `PROP_HIT` payload | — | AttackSystem emits `PROP_HIT` with the damage number as the first arg (`emit(PROP_HIT, damage)`). `text_emitter` uses this payload as the display text when its `text` field is nil. | — |
| `PROP_BROKEN` | `"prop_broken"` | Destructible | Drop(3), Shake(5), Sound(15) |
| `PROP_SPAWNED` | `"prop_spawned"` | PropSpawner | Tween(10), Sound(15) |
| `VALUE_CHANGED` payload | — | PlayerStats emits `VALUE_CHANGED` with `{ sourceType, field, value, maxValue, level }` in `addExperience()` when XP changes. Counter uses `field` to filter and `value/maxValue` for frame; `level` drives optional label text. Main.lua listens for `field == "satiety"` to update the saturation shader and global timescale. | — |
| `COUNTER_TICK` | `"counter_tick"` | Counter | Tween(10) |
| `COUNTER_WRAP` | `"counter_wrap"` | Counter | Tween(10), Sound(15) |
| `SWING` | `"swing"` | AttackSystem | — |
| `TARGET_SELECTED` | `"target_selected"` | AttackSystem | ParticleEmitter(5) |
| `FOLLOW_ARRIVED` | `"follow_arrived"` | Follow | Tween(10) |
| `PICKUP` | `"pickup"` | Main.lua (pendingDestroy) | Tween(10) |
| `TWEEN_COMPLETED` | `"tween_completed"` | Tween | Sound(15) |
| `COUNTER_TICK` | `"counter_tick"` | Counter | Tween(10) |
| `COUNTER_WRAP` | `"counter_wrap"` | Counter | Tween(10), Sound(15) |

## Priority conventions

- Lower number = runs first
- Gaps of 5 (5/10/15/20) leave room for future listeners
- STATE_CHANGED and FLIPPED use tighter spacing (7↔8, 10↔11↔12) because of Shader insertion

## Subscription rules

1. Subscribe in `attach()` or `new()` — before game loop starts
2. Use string constants from `Events.lua`, never raw strings
3. Priority gap of 5 when adding new listeners
4. Single-writer rule: only Control writes `parent._state` and `parent.flipX`

## Field exceptions (read in update/draw)

Only these four fields may be read across components without events:

| Field | Justification |
|---|---|
| `parent.flipX` / `parent._state` | Render-only, read in `draw()` only |
| `parent.tweens` | Continuous numeric data, one producer multi-consumer |
| `parent.alpha` | Render-only opacity (0–1) |
| `parent.shader` / `parent.shaderData` | Per-sprite shader reference, continuous render parameter |

## Adding a new event

1. Add constant to `Source/Helpers/Events.lua`
2. Add row to events.md event table
3. Use `sprite:emit(Events.MY_EVENT, ...)` in emitter
4. Subscribe with `sprite:on(Events.MY_EVENT, callback, priority)`
