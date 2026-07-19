---
description: Quick reference for all 13 components — purpose, config fields, events.
---

# Component Cheat Sheet

## Core

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **spritesheet** | Quad animation + frame rendering | `columns`, `rows`, `animations`, `tags` | STATE_CHANGED (5) | ANIM_FRAME |
| **control** | Keyboard/mouse input; sole writer of `_state` and `flipX` | `movementSpeed`, `swimmingSpeed`, `keyboardControl`, `mouseControl` | GROUNDED_CHANGED (10), SLOWDOWN_CHANGED (10) | STATE_CHANGED, FLIPPED |
| **collision** | AABB collision, terrain/solid registries, grounded detection | `mode`, `collisionWidth`, `collisionHeight`, `offsetX`, `offsetY`, `visible`, `slowdown` | — | GROUNDED_CHANGED, SLOWDOWN_CHANGED, SLOWDOWN_ENTER, SLOWDOWN_EXIT |
| **follow** | Follow-target smoothing + deployTo/recall (tools) | `offsetX`, `offsetY`, `smoothness`, `smoothnessX`, `smoothnessY`, `followRadius`, `followDelay`, `leanAngle`, `leanThreshold`, `arrivedThreshold` | — | FOLLOW_ARRIVED |

## Effects

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **tween** | Property animation on events (flip, hit, state, arrival, spawned) | `tweens`, `tags` (event→tween mappings), `destroyOnComplete` | FLIPPED (10), STATE_CHANGED (10), PROP_HIT (10), FOLLOW_ARRIVED (10), PROP_SPAWNED (10) | TWEEN_COMPLETED |
| **shake** | Screen shake on death | `magnitude`, `duration`, `decay` | PROP_BROKEN (5) | — |
| **shader** | Shader uniform management (brightness) | `shaderName`, `brightness` | PROP_HIT (8) | — |
| **proximity_fade** | Fade alpha based on player distance | `radius`, `fadeAlpha`, `smoothness` | — | — |
| **particle_emitter** | Particle spawning (burst + continuous) | `particle`, `stepInterval`, `offsetX`, `offsetY`, `inheritFlip`, `spawnOn`, `count`, `angle`, `cone`, `radius`, `layer` | STATE_CHANGED (8), FLIPPED (12), ANIM_FRAME (13) | — |

## Gameplay

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **destructible** | HP, takeDamage, dead-sprite tracking | `hp`, `replaceWith` | — | PROP_BROKEN |
| **drop** | Spawn drops on PROP_BROKEN | `drops` (array of `{sprite, amount}`) | PROP_BROKEN (3) | — |
| **weapon** | Weapon data container (range, cooldown, damage, swing) | `range`, `cooldown`, `damage`, `swing` | — | — |
| **sound** | Sound triggered by events | `volume`, `pitch`, `pitchRandomness`, `stepInterval`, `tags` | GROUNDED_CHANGED (15), STATE_CHANGED (15), ANIM_FRAME (15), SLOWDOWN_ENTER (15), PROP_HIT (15), PROP_BROKEN (15), TWEEN_COMPLETED (15), PROP_SPAWNED (15) | — |

## Mode field (collision)

| Mode | Behavior |
|---|---|
| `"solid"` | Blocks movement, no detection (terrain) |
| `"detect"` | Detection only, no blocking |
| `"solid_and_detect"` | Blocks movement + grounded detection (player) |
| `"slowdown"` | Speed multiplier zone (bushes) |

## spawnOn field (particle_emitter)

Two trigger types:
- **Event names** (e.g. `{ prop_broken = true }`) — burst once per event
- **State names** (e.g. `{ run = true }`) — continuous emission while in that state, driven by ANIM_FRAME + stepInterval

## drop amount syntax

| Format | Meaning |
|---|---|
| `"1"` | Always 1 |
| `"2...4"` | Random 2–4 |
| `"0\|1"` | 50% chance of 0 or 1 |

## Config value parsing

All numeric config fields that accept user/mod data (speed, smoothness, delay, radius, etc.) MUST be passed through `Math.parseRandomValue()` in the component constructor. Same `min...max` and `a|b|c` syntax as drop amounts (above). Otherwise `"0.3...0.5"` passes as raw string and breaks math operations.

## Tags (spritesheet animation mapping)

`tags` maps state names → animation names. If omitted, state name = animation name:
```lua
tags = { idle = "stand", run = "walk" }  -- "idle" state plays "stand" animation
```

## destroyOnComplete (tween)

When all `destroyOnComplete` tweens finish, Tween emits `TWEEN_COMPLETED` (Sound subscribes) then removes the parent sprite from the game. Supports two levels:

**Per-tween** — only that specific tween triggers destruction on finish:
```lua
{ target = "scale_x", from = 0, to = 1, duration = 0.5, destroyOnComplete = true },
```

**Tag-level** — applies to all tweens in the tag set (any can trigger, idempotent):
```lua
tags = {
    arrived = {
        destroyOnComplete = true,
        { target = "scale_x", from = 1, to = 0, duration = 0.5 },
        { target = "scale_y", from = 1, to = 2, duration = 0.5 },
    },
},
```
