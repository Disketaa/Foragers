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
| **follow** | Follow-target smoothing + deployTo/recall (tools) | `offsetX`, `offsetY`, `smoothnessX`, `smoothnessY`, `leanAngle`, `leanThreshold` | — | — |

## Effects

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **tween** | Property animation on events (flip, hit, state) | `tags` (event→tween mappings) | FLIPPED (10), STATE_CHANGED (10), PROP_HIT (10) | — |
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
| **sound** | Sound triggered by events | `volume`, `pitch`, `pitchRandomness`, `stepInterval`, `tags` | GROUNDED_CHANGED (15), STATE_CHANGED (15), ANIM_FRAME (15), SLOWDOWN_ENTER (15), PROP_HIT (15), PROP_BROKEN (15) | — |

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

## Tags (spritesheet animation mapping)

`tags` maps state names → animation names. If omitted, state name = animation name:
```lua
tags = { idle = "stand", run = "walk" }  -- "idle" state plays "stand" animation
```
