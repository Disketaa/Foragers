---
description: Quick reference for all components — purpose, config fields, events.
---

# Component Cheat Sheet

## Core

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **spritesheet** | Quad animation + frame rendering | `columns`, `rows`, `animations`, `tags` | STATE_CHANGED (5) | ANIM_FRAME |
| **control** | Keyboard/mouse input; sole writer of `_state` and `flipX` | `movementSpeed`, `swimmingSpeed`, `keyboardControl`, `mouseControl` | GROUNDED_CHANGED (10), SLOWDOWN_CHANGED (10) | STATE_CHANGED, FLIPPED |
| **collision** | AABB collision, terrain/solid registries, grounded detection | `mode`, `collisionWidth`, `collisionHeight`, `offsetX`, `offsetY`, `visible`, `slowdown` | — | GROUNDED_CHANGED, SLOWDOWN_CHANGED, SLOWDOWN_ENTER, SLOWDOWN_EXIT |
| **follow** | Follow-target smoothing + deployTo/recall (tools) | `offsetX`, `offsetY`, `smoothness`, `smoothnessX`, `smoothnessY`, `followRadius`, `followDelay`, `leanAngle`, `leanThreshold`, `arrivedThreshold` | — | FOLLOW_ARRIVED |
| **scroll_to** | Smooth camera follow (centers camera on target via expSmooth) | `smoothness`, `offsetX`, `offsetY`, `chunkSize` | — | — |
| **spritefont** | Text rendering using parent spritesheet quads | `chars`, `spacing`, `charSpacing`, `color` (set per-instance via Text) | — | — |

## Effects

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **tween** | Property animation on events (flip, hit, state, arrival, spawned, pickup, counter tick/wrap) | `tweens`, `tags` (event→tween mappings), `destroyOnComplete` | FLIPPED (10), STATE_CHANGED (10), PROP_HIT (10), FOLLOW_ARRIVED (10), PROP_SPAWNED (10), PICKUP (10), COUNTER_TICK (10), COUNTER_WRAP (10) | TWEEN_COMPLETED |
| **shake** | Screen shake on death | `magnitude`, `duration`, `decay` | PROP_BROKEN (5) | — |
| **shader** | Composes shader modules (uv-chain → Texel → color-chain); auto-maps any `parent.tweens.<name>` → uniform `u_<name>` | `shaders` (array; each entry is a string name, `{ name = "X" }`, or compact `{ X = { u_* = ... } }` for per-shader uniform overrides) or `shaderName` (single, legacy) | PROP_HIT (8) | — || **proximity_fade** | Fade alpha based on player distance | `radius`, `fadeAlpha`, `smoothness` | — | — |
| **shadow** | Texture-free pixel-perfect shadow (3-rect 1px-rounded shape) | `offsetX`, `offsetY`, `width`, `height` | — (data-only; rendered via `Shadow.renderLayer`) | — |
| **particle_emitter** | Particle spawning (burst + continuous + timed). Detaches on parent destroy — existing particles finish in world space | `particle`, `stepInterval`, `interval`, `moving`, `offsetX`, `offsetY`, `inheritFlip`, `spawnOn`, `count`, `angle`, `cone`, `radius`, `layer` | STATE_CHANGED (8), FLIPPED (12), ANIM_FRAME (13) | — |

## Shader inheritance

`shaders` arrays concatenate on `extends`: the child inherits the parent's shader
list and appends its own (parent first, no duplicates). So a base `_Props` with
`shaders = { "Brightness" }` and a child with `shaders = { "Skew" }` yields
`{ "Brightness", "Skew" }` for the child, while the base keeps only
`{ "Brightness" }`. This differs from `tags` (a map, deep-merged by key) — `shaders`
is an array, which `Merge.merge` would otherwise replace entirely, dropping the
inherited shaders.

Per-shader uniform overrides use the compact spec form:
`shaders = { { Skew = { u_amount = 0.05 } } }`. The override `u_*` keys are pulled
onto the component and sent to the shader at attach. If `u_seed` is not set, the
Shader component derives it from the sprite position so multiple props of the same
type sway out of phase.

## Gameplay

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **destructible** | HP, takeDamage, dead-sprite tracking | `hp`, `replaceWith` | — | PROP_BROKEN |
| **drop** | Spawn drops on PROP_BROKEN | `drops` (array of `{sprite, amount}`) | PROP_BROKEN (3) | — |
| **weapon** | Weapon data container (range, cooldown, damage, swing) | `range`, `cooldown`, `damage`, `swing` | — | — |
| **player_stats** | Player stats container (crit, level, xp, hunger) | `critChance`, `critMult`, `level`, `experience`, `xpCurve`, `hunger`, `maxHunger` | — | VALUE_CHANGED |
| **pickup** | Grants XP to player on collection | `xp` (number) | FOLLOW_ARRIVED (5) | — |
| **sound** | Sound triggered by events | `volume`, `pitch`, `pitchRandomness`, `stepInterval`, `tags` | GROUNDED_CHANGED (15), STATE_CHANGED (15), ANIM_FRAME (15), SLOWDOWN_ENTER (15), PROP_HIT (15), PROP_BROKEN (15), TWEEN_COMPLETED (15), PROP_SPAWNED (15), COUNTER_WRAP (15) | — |

## UI / HUD

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **text_emitter** | Floating text on events (e.g. damage numbers). Registered in `ComponentRegistry` but driven by global `TextEmitter.updateAll(dt)` / `TextEmitter.drawAll()` from `Main.lua` — NOT via the per-sprite component loop (its `update`/`draw` are no-ops). | `font`, `text`, `event`, `color`, `moveX`, `moveY`, `gravity`, `duration`, `offsetX`, `offsetY`, `destroy`, `destroyCurve` | PROP_HIT (5) | — |
| **counter** | Maps a value from a source component (e.g. `player_stats`) to a spritesheet frame. Event-driven — subscribes to `VALUE_CHANGED` on the source sprite via `setPlayerSprite()`. `update()` drives smooth tween animation. Optional `label` overlays text (level). Emits `COUNTER_TICK` on parent sprite on every value change and `COUNTER_WRAP` when the source level changes (bar wraps around). | `mode` (`"fraction"`/`"progress"`), `field`, `maxField`, `sourceType`, `frames`, `smoothness`, `curve`, `label` | VALUE_CHANGED (5) on source sprite | COUNTER_TICK, COUNTER_WRAP |
| **ui** | Data-only screen-positioning. No `update`/`draw` — positioned by Main using `UI.calculate()`. Any sprite in `Content/Assets/Sprites/UI/` with this component is drawn after the world canvas `pop()`. | `horizontal` (`"left"`/`"center"`/`"right"`), `vertical` (`"top"`/`"center"`/`"bottom"`), `offsetX`, `offsetY` | — | — |

### text_emitter config

| Field | Type | Default | Meaning |
|---|---|---|---|
| `font` | string | `Content.Assets.Sprites.UI.Fonts.Tinylorder` | Module path to a font data file (spritesheet + spritefont) |
| `text` | string | nil | Fixed text. If nil, the emitted event payload (e.g. damage number) is used as the text |
| `event` | string | `"prop_hit"` | Event the emitter listens to |
| `color` | table | `{1,1,1}` | RGB tint (0–1) |
| `moveX` | number/`"a|b"`/`"min..max"` | `0` | Horizontal drift speed (px/s); re-rolled per emit |
| `moveY` | number/range/choice | `-120` | Vertical drift speed (px/s, negative = up); re-rolled per emit |
| `gravity` | number/range/choice | `400` | Downward accel (px/s²); re-rolled per emit |
| `duration` | number/range/choice | `0.8` | Lifetime seconds; re-rolled per emit |
| `offsetX` | number/range/choice | `0` | Spawn X offset from parent pivot; re-rolled per emit |
| `offsetY` | number/range/choice | `-8` | Spawn Y offset from parent pivot; re-rolled per emit |
| `destroy` | `"fade"`/`"scale"`/`"instant"` | `"fade"` | Animated property: `fade`→alpha 1→0, `scale`→scale 1→0, `instant`→stays 1 |
| `destroyCurve` | string | `"Linear"` | Easing name from `Tween.Easing` shaping the destroy animation |

Spawn base = `parent.x + offsetX, parent.y + offsetY` (parent pivot point). Text is drawn with the **font's** pivot as the glyph origin (Tinylorder uses `pivotX=0, pivotY=0`, so text is top-left anchored at the base). Random fields (`moveX/moveY/gravity/duration/offsetX/offsetY`) are resolved via `ValueParser.call(self, "field")` **inside the event handler**, not in `new`, so each emit re-rolls choice/range strings. `drawAll` saves/restores the active shader so text is never tinted by a sprite shader.

### counter config

| Field | Type | Default | Meaning |
|---|---|---|---|
| `mode` | `"fraction"`/`"progress"` | `"fraction"` | `"fraction"`: `value / maxField`. `"progress"`: XP progress within current level (uses `xpForNextLevel()` on source). |
| `field` | string | `"experience"` | Field name on the source component to read as current value. |
| `maxField` | string | nil | For `"fraction"` mode — field name on the source component to read as maximum value. |
| `sourceType` | string | `"player_stats"` | Component type to find on the watched sprite. |
| `frames` | number | spritesheet columns | Total frames in the animation (frame 1 = 0%, frame N = 100%). |
| `smoothness` | number | `0` | Tween duration in seconds. `0` = instant jump. `>0` = smooth animation between old and new frame. |
| `curve` | string | `"OutBack"` | Easing curve name from `Tween.Easing` (e.g. `"OutBack"`, `"Linear"`, `"InCubic"`). Ignored when `smoothness = 0`. |
| `label` | table | nil | Optional text overlay config block (see below). |

### label config (inside counter)

| Field | Type | Default | Meaning |
|---|---|---|---|
| `font` | string | `"Content.Assets.Sprites.UI.Fonts.Tinylorder"` | Font data module path for the text spritesheet. |
| `charSpacing` | number | font's charSpacing | Pixel spacing between characters. Overrides the font data default. |
| `color` | table | `{1,1,1}` | RGBA tint (0–1). |
| `offsetX` | number | `0` | X offset from parent's draw origin (top-left of sprite). |
| `offsetY` | number | `0` | Y offset from parent's draw origin. |
| `hAlign` | `"left"`/`"center"`/`"right"` | `"center"` | Horizontal text alignment relative to offsetX. |
| `vAlign` | `"top"`/`"center"`/`"bottom"` | `"center"` | Vertical text alignment relative to offsetY. |

The label text content is `tostring(data.level)` from the `VALUE_CHANGED` payload. The font spritesheet is loaded once in `attach()`. Drawn in `draw()` over the parent sprite.

Connected via `Main.lua`: `counter:setPlayerSprite(playerSprite)` subscribes to `VALUE_CHANGED` on the player and syncs initial value. `update()` drives the smoothing tween.

### ui config

| Field | Type | Default | Meaning |
|---|---|---|---|
| `horizontal` | `"left"`/`"center"`/`"right"` | `"left"` | Horizontal anchor. `"left"`: `x = offsetX`. `"center"`: centered + offsetX. `"right"`: `x = containerW - elemW - offsetX`. |
| `vertical` | `"top"`/`"center"`/`"bottom"` | `"top"` | Vertical anchor. `"top"`: `y = offsetY`. `"center"`: centered + offsetY. `"bottom"`: `y = containerH - elemH - offsetY`. |
| `offsetX` | number | `0` | Pixel offset added after anchor calculation |
| `offsetY` | number | `0` | Pixel offset added after anchor calculation |

Positioned by `Main.lua` at load and on every `love.resize()` — `UI.calculate(comp, canvasW, canvasH, elemW, elemH)` returns the final `x, y` in canvas-space. Drawn after `love.graphics.pop()` so UI is fixed on screen regardless of camera.

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

## interval field (particle_emitter)

Timer-driven emission independent of state. `interval = 0.6` spawns one particle every 0.6 seconds. No state change required — works on any sprite regardless of control component.

## moving field (particle_emitter)

When `moving = true`, the interval timer only accumulates while the parent sprite's position changes between frames. Combine with `interval` for movement-only particles (e.g. trail while following, not while idle). `moving = false` (default) spawns regardless of movement.

## detach behavior (particle_emitter)

Particle emitters are automatically detached from the parent sprite when the sprite is destroyed. This happens in two paths in `Main.lua`:

- **Destructible death:** `Destructible.getDead()` → `ParticleEmitter.detachAll(sprite)` → sprite cleanup
- **Tween destroyOnComplete:** `TweenComponent.getPendingDestroy()` → `ParticleEmitter.detachAll(sprite)` → sprite cleanup

`detachAll` iterates the sprite's components, finds all `particle_emitter` entries, sets `parent = nil` and `_emitting = false`, then moves them into a global `detachedEmitters` pool.

After detachment:
- **No new particles are spawned** — interval/step/event/spawnOn triggers are dead without a parent
- **Existing particles continue animating** — age, animation frame, and draw all proceed normally
- **Auto-cleanup** — `ParticleEmitter.updateDetached(dt)` (called from `Main.lua` each frame) removes the emitter from `detachedEmitters` once `#_particles == 0`

Detached emitters are drawn in world space at the same layering as live emitters (behind sprites if `layer = "below"`, in front otherwise), via `ParticleEmitter.drawDetachedBehind()` and `ParticleEmitter.drawDetached()` in the `love.draw` canvas callback.

## drop amount syntax

| Format | Meaning |
|---|---|
| `"1"` | Always 1 |
| `"2..4"` | Random 2–4 |
| `"0\|1"` | 50% chance of 0 or 1 |

## Config value parsing

All numeric config fields that accept user/mod data (speed, smoothness, delay, radius, etc.) MUST be passed through `ValueParser.value()` in the component constructor, or use `ValueParser.call(self, "field")` for per-event re-rolling. Same `min..max` and `a|b|c` syntax as drop amounts (above). Otherwise `"0.3..0.5"` passes as raw string and breaks math operations.

The `ValueParser.table(data)` call in `SpriteLoader.instantiate()` auto-resolves all strings at load time and stores originals in `tbl.__raw` — components that need per-event re-rolling call `ValueParser.call(tbl, field)`.

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

## chars field (spritefont)

The `chars` string defines the character set. Each **visual character's** position in the string maps 1:1 to the spritesheet quad index (1‑based). The index is built by iterating UTF-8 by visual char (not byte), so multi-byte glyphs (Cyrillic, etc.) land on the correct cell — a 2-byte char does NOT consume two cells. Only characters present in `chars` can be rendered; unknown chars are skipped with a gap of `frameWidth + charSpacing`.

## spacing field (spritefont)

Per‑character width overrides, specified as an array of `{ width, chars }` pairs:
```lua
{ { 9, "Mmw" }, { 7, "+>" }, { 5, ".li-" } }
```
Characters not listed use `frameWidth` as their advance width. Spaces always advance by `frameWidth + charSpacing`.

## color field (spritefont)

Color is **per-instance**, not baked into font data. Set it via `Text.new({ color = {r,g,b,a} })` or `text:setColor(color)`. Default in component constructor is `{0,0,0,1}` (black) — the component always receives a color; font data files should omit this field to avoid confusing a font default with a text instance override.

## Text object (Source/UI/Text.lua)

`Text` creates a Sprite with `spritesheet` + `spritefont` components via `SpriteLoader.instantiate()` and provides a simple API:

- `Text.new(opts)` / `Text.new(text, x, y, fontPath)` — constructs a text sprite
- `text:setText(str)`
- `text:setColor({r,g,b,a})`
- `text:setPosition(x, y)`
- `text:draw()` — delegates to the internal sprite draw

Default font path: `Content.Assets.Sprites.UI.Fonts.Tinylorder` (8×8, 16 columns). The font PNG must have white characters on transparent background so `setColor` tints correctly.
