---
description: Quick reference for all components — purpose, config fields, events.
---

# Component Cheat Sheet

## Core

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **spritesheet** | Quad animation + frame rendering | `columns`, `rows`, `animations`, `tags` | STATE_CHANGED (5) | ANIM_FRAME |
| **control** | Keyboard/mouse input; sole writer of `_state` and `flipX` | `movementSpeed`, `swimmingSpeed`, `keyboardControl`, `mouseControl` | GROUNDED_CHANGED (10), SLOWDOWN_CHANGED (10) | STATE_CHANGED, FLIPPED |
| **collision** | AABB collision, terrain/solid registries, grounded detection. Debug box overlay publishes rects to `Gizmo` gated by the `collisions` group in `Content/Data/Debug.lua` (see *Debug gizmo* below) | `mode`, `collisionWidth`, `collisionHeight`, `offsetX`, `offsetY`, `slowdown` | — | GROUNDED_CHANGED, SLOWDOWN_CHANGED, SLOWDOWN_ENTER, SLOWDOWN_EXIT |
| **follow** | Follow-target smoothing + deployTo/recall (tools) | `offsetX`, `offsetY`, `smoothness`, `smoothnessX`, `smoothnessY`, `followRadius`, `followDelay`, `leanAngle`, `leanThreshold`, `arrivedThreshold` | — | FOLLOW_ARRIVED |
| **scroll_to** | Smooth camera follow (centers camera on target via expSmooth) | `smoothness`, `offsetX`, `offsetY`, `chunkSize` | — | — |
| **spritefont** | Text rendering using parent spritesheet quads | `chars`, `spacing`, `charSpacing`, `color` (set per-instance via Text) | — | — |

## Effects

| Component | Purpose | Config | Subscribes | Emits |
|---|---|---|---|---|
| **tween** | Property animation on events (flip, hit, state, arrival, spawned, pickup, counter tick/wrap) | `tweens`, `tags` (event→tween mappings), `destroyOnComplete` | FLIPPED (10), STATE_CHANGED (10), PROP_HIT (10), FOLLOW_ARRIVED (10), PROP_SPAWNED (10), PICKUP (10), COUNTER_TICK (10), COUNTER_WRAP (10) | TWEEN_COMPLETED |
| **shake** | Screen shake, offsetting the camera/sprite for `duration` then decaying. Event-triggered via `PROP_BROKEN`; `trigger()` starts it directly (used by burst particles — a `shake` component in particle data shakes that particle in place). | `magnitude`, `duration`, `decay` | PROP_BROKEN (5) | — |
| **shader** | Composes shader modules (uv-chain → Texel → color-chain); auto-maps any `parent.tweens.<name>` → uniform `u_<name>` | `shaders` (array; each entry is a string name, `{ name = "X" }`, or compact `{ X = { u_* = ... } }` for per-shader uniform overrides) or `shaderName` (single, legacy) | PROP_HIT (8) | — |
| **shadow** | Texture-free pixel-perfect shadow (3-rect 1px-rounded shape) | `offsetX`, `offsetY`, `width`, `height` | — (data-only; rendered via `Shadow.renderLayer`) | — |
| **silhouette** | Marker for silhouette reveal effect. `mode="silhouette"` (default) — sprites captured to white silhouette canvas. `mode="mask"` — foliage reveals silhouettes where its alpha > 0. Canvas rendered by `Helpers/Mask.lua:renderSilhouette()` which iterates all dynamic objects and draws every sprite with `mode="silhouette"`. Sprites without a `spritesheet` component fall back to drawing `sprite.image` directly with pivot/flip/tweens. `color` (`{0,0,0,0.75}` default, rgba) tints the reveal: each silhouette sprite is drawn to the canvas in its own color+alpha and the Silhouette shader samples `sil.rgb`/`sil.a`, so the dither color is set per sprite file. **Revealer vs target:** `mode="mask"` sprites sample the canvas (must include the `Silhouette` shader module); `mode="silhouette"` sprites are captured to it (must NOT include `Silhouette`, or they silhouette themselves). `__Props` base provides the shader only as `{ "Brightness" }`; `_Trees/_Stumps/_Bushes` add `Silhouette`, `_Vegetables` sets `mode="silhouette"` | `mode` (`"silhouette"` default, `"mask"` for trees), `color` (`{0,0,0,0.75}`) | — | — |
| **particle_emitter** | Particle spawning (burst + continuous + timed). Detaches on parent destroy — existing particles finish in world space. A `shake` component in the particle data shakes that particle in place (created/updated/applied per particle) | `particle`, `stepInterval`, `interval`, `moving`, `offsetX`, `offsetY`, `inheritFlip`, `spawnOn`, `count`, `angle`, `cone`, `radius`, `layer` | STATE_CHANGED (8), FLIPPED (12), ANIM_FRAME (13) | — |
| **emote** | Anchored overlay sprite (bubble, `?`, `!`) that sticks to the parent, plays once, then hides. Drawn as a normal component so it moves with the parent and dies with it. Reads `parent.flipX` in `draw()` for flip inheritance. On trigger it plays the emote data's top-level `tweens` (spawn pop-in, no tag — same as drops on spawn), shows for `duration` seconds, then runs the `tags.hide` tween to scale/fade out before deactivating. Emote data is self-contained via its `tween` component (`tweens` for spawn + `tags.hide` for exit). Supports animated, single-frame spritesheet, or static (no `components`, plain image like Cursor) emote data | `object` (path to emote sprite data), `event` (event string, default `"low_satiety"`), `offsetX`, `offsetY`, `duration` (seconds shown before hide) | the configured `event` (5) | — |

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
| **player_stats** | Player stats container (crit, level, xp, satiety). Low-satiety effects (slow time, desaturate, zoom-in) are driven off `lowSatietyPercent`/`lowSatietyZoom` in `Main.lua`'s VALUE_CHANGED handler. Emits `LOW_SATIETY` once per descending warning threshold (`lowSatietyWarnings` default 3; thresholds at `lowSatietyPercent * (count-i+1)/count`, e.g. 0.33/0.22/0.11; reset when restored above the low threshold). At satiety 0 sets `dead = true` and emits `DEATH`; `dead` makes `consumeSatiety`/`restoreSatiety`/`addExperience` no-op (eating/pickups do nothing after death). `Main.lua` tracks the death sequence via a `state = "game"\|"dying"\|"gameover"` string (AGENTS §XII) — on `DEATH` it plays the player's death anim over the frozen world (`"dying"`), then holds on `"gameover"` with the CircleMask at its satiety-0 radius (no blackout); auto-restart after DEATH_DURATION is currently disabled (`AUTO_RESTART = false`) for debugging | `critChance`, `critMult`, `level`, `experience`, `xpCurve`, `satiety`, `maxSatiety`, `lowSatietyPercent`, `lowSatietyZoom`, `lowSatietyWarnings`, `lowSatietyMaskRadius`, `dead` | — | VALUE_CHANGED, LOW_SATIETY, DEATH |
| **pickup** | Grants XP to player on collection | `xp` (number) | FOLLOW_ARRIVED (5) | — |
| **sound** | Sound triggered by events | `volume`, `pitch`, `pitchRandomness`, `stepInterval`, `tags` | GROUNDED_CHANGED (15), STATE_CHANGED (15), ANIM_FRAME (15), SLOWDOWN_ENTER (15), PROP_HIT (15), PROP_BROKEN (15), TWEEN_COMPLETED (15), PROP_SPAWNED (15), COUNTER_WRAP (15), LOW_SATIETY (15), DEATH (15) | — |

### sound tags (per-tag config)

Each `tags` entry is either a plain array of sound paths (`run = { "a.ogg" }`) or a
config block `{ sounds = { "a.ogg" }, volume, pitch, pitchRandomness, stepInterval }`
for per-sound overrides. Explicit `0` is honored (e.g. `pitchRandomness = 0`, a
muted `volume = 0`). The tag key must be a state name (played via `STATE_CHANGED` /
`ANIM_FRAME`) or an event the component subscribes to (see the Subscribes column).

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

## Debug gizmo (collision overlay)

The per-sprite `visible` collision flag is removed. Box rendering is now global and data-driven via `Content/Data/Debug.lua`:

```lua
gizmo = {
    enabled = true,                    -- master switch for all gizmo overlays
    collisions = {
        enabled = true,
        exclude = { "tiles" },
        priority = 20,                 -- higher = drawn on top
        decor = "diagonal",            -- "none" | "diagonal" | "cross" | "dashed"
        color = { 1, 0.25, 0.25, 1 },  -- rgba, alpha = opacity
    },
    -- ...boundaries, pivots (below)
}
```

- `debug` master switch gates all debug output; `gizmo.enabled` must also be true, then the individual group's `enabled`.
- `exclude` lists `sprite.object` ids to skip (each sprite must declare `object` in its data — `SpriteLoader` copies it to `sprite.object`).
- `color` styles the outline + diagonals; `priority` controls layering across groups (see below).
- `decor` selects the box decoration: `"none"` (plain box outline), `"diagonal"` (outline + one diagonal), `"cross"` (two diagonals forming an X), or `"dashed"` (dashed outline, no diagonals). Default `"diagonal"`. LÖVE has no native dashed primitive, so `"dashed"` draws the outline as dash/gap line segments (dash scaled off line width).
- `backgroundColor` (optional) draws a solid fill underneath the outline.

Mechanics: `Collision:attach()` subscribes to `Debug.onChange` and caches `showDebugBoxes = Debug.enabled("gizmo") and Debug.enabled("gizmo.collisions") and not Debug.excluded("gizmo.collisions", self.parent.object)`. `Collision:draw()` publishes `self:getRect()` to `Gizmo` (world-space buffer, tagged `"collisions"`) instead of drawing directly. `Main.lua` draws the buffered rects in a native-resolution pass after the world canvas — so boxes stay crisp regardless of the low-res world canvas's nearest-filter upscale.

## Debug gizmo (boundary overlay)

`gizmo.boundaries` in `Content/Data/Debug.lua` draws each sprite's pivot-aware frame box (`sprite.x - w*pivotX`, `sprite.y - h*pivotY`, size `frameWidth`×`frameHeight`) as a solid fill (`backgroundColor`) under an outline (`color`):

```lua
boundaries = {
    enabled = true,
    exclude = { "tiles" },
    priority = 10,
    backgroundColor = { 0.2, 0.6, 1, 0.35 },
    color = { 0.2, 0.6, 1, 0.4 },
}
```

Published by `Main.lua` (iterates all `objects`) into `Gizmo.fillRect` + `Gizmo.rect` (both tagged `"boundaries"`). Exclusion + master gating identical to `collisions` (queried as `gizmo.boundaries`).

## Debug gizmo (pivot overlay)

`gizmo.pivots` draws a solid square (`size` px, `color`) centered exactly on each sprite's pivot (`sprite.x`/`sprite.y`):

```lua
pivots = {
    enabled = true,
    exclude = {},
    priority = 30,
    color = { 1, 0.8, 0.2, 1 },
    size = 5,
}
```

Published by `Main.lua` into `Gizmo.point`. Exclusion + master gating identical to `collisions` (queried as `gizmo.pivots`).

## Gizmo layering

`Gizmo.draw` draws each enabled group independently, ordered by ascending `priority` — so `boundaries` (10) render under `collisions` (20), and `pivots` (30) sit on top of everything. Within a group the order is: `backgroundColor` fill, then `color` outline, then `point` markers.

## Debug HUD (top-left text)

`hud` group in `Content/Data/Debug.lua` renders a screen-fixed, top-left readout at native resolution: FPS text, an FPS graph, and the live world object count. Like the other overlay groups, each toggleable item is its own sub-group with an `enabled` flag; global styling (`size`, `padding`, colors) sits at the `hud` level:

```lua
hud = {
    enabled = true,
    size = 4,
    padding = 2,
    gap = 0,
    updateSpeed = 30,
    backgroundColor = { 0, 0, 0, 0.2 },
    labelColor = { 0.8, 0.8, 1, 1 },
    color = { 1, 1, 1, 1 },
    goodColor = { 0, 1, 0, 1 },
    badColor = { 1, 0, 0, 1 },
    font = {
        label = "Content/Assets/Fonts/AzeretMonoMedium.ttf",
        value = "Content/Assets/Fonts/AzeretMonoSemiBold.ttf",
    },

    fps = true,
    fpsGraph = {
        enabled = true,
        tolerance = 5,
        gap = 2,
        width = 25,
        height = 4,
        thickness = 0.5,
    },
    objectCount = true,
    toggles = {
        { label = "Debug", path = "debug", key = "toggleDebug" },
        { label = "Gizmo", path = "gizmo", key = "toggleGizmo" },
        { label = "Profiler", path = "hud.profiler", key = "toggleProfiler" },
    },

    profiler = {
        enabled = true,
        updateSpeed = 10,
        nameMaxChars = 18,
        digits = 1,
        valueMaxChars = 8,
        limit = 20,
    },
}
```

- `enabled` — global switch for the whole HUD (default true). The `debug` master switch (F1) gates the HUD; it renders only while master debug is on. There is no independent runtime HUD toggle anymore.
- `fps` — simple boolean flag, current FPS. Samples are taken `updateSpeed` times per second (Hz).
- `fpsGraph` — inline line graph of recent FPS samples (60-point ring buffer), drawn to the right of the FPS text on the same line, `gap` px after it. The reference line is `Options.maxFps` (the frame cap). Segments are green (`goodColor`) while at/above `maxFps - tolerance`, red (`badColor`) at the samples that dropped below that threshold — `tolerance` (default 0) absorbs reading jitter so a 1–2 fps dip doesn't color a segment bad. `goodColor`/`badColor` live at the `hud` level and are shared with the `toggles` readout. `width`/`height` set the graph box size (clamped to the row) and `thickness` the line weight, all in base px. The FPS value text is right-aligned into a fixed width (from `maxFps` digit count) so the graph never shifts when the reading goes 2→3 digits.
- `objectCount` — simple boolean flag, `#objects` from `Main.lua`.
- `toggles` — readout of the F-key debug toggles (the `Content/Data/Options.lua` keybinds), drawn below a one-row separator after the readout. Each entry shows `KEY | Label` in `labelColor` with `Enabled`/`Disabled` in `goodColor`/`badColor`. `key` names the `Options.keybinds` entry whose first keyboard key becomes the uppercase prefix; `path` is the `Debug.enabled` group to query (`"debug"` is the top-level master boolean). The `HUD` toggle was removed — the master switch now owns HUD visibility.
- `padding` — group offset: shifts the whole readout right/down as one block (the boxes hug their content tightly); `gap` — spacing between rows (defaults to `padding`). Set `gap` to 0 for the tightest spacing between rows.
- `labelColor` — dim color for static labels (`FPS:`, `Objects:`, the `| Label` toggle prefix); `color` — bright color for the numbers and the `KEY |` toggle prefix.
- `font` — optional TTF paths loaded via `love.filesystem`; `label` (bold) and `value` (regular) can differ. Missing/failed loads fall back to LÖVE's default font, cached by path+size.
- `backgroundColor` — optional solid fill drawn behind the readout. Omit to keep it transparent.
- `size` (base px), `padding`, and the graph `width`/`height`/`thickness` all scale with the window upscale factor via the `scale` argument passed to `Debug.draw`.
- `profiler` — auto-instrumenting CPU profiler drawn as a bottom-left table (`Scope`/`Time`/`%`) in the same styling. It needs no imports: it patches `Sprite:addComponent` to time every component's `update`/`draw`, and wraps any module exposing a known per-frame method name (`update`, `updateAll`, `updateBursts`, `updateDetached`, `drawAll`, ...) via a `package.loaded` sweep plus a `require` wrapper, so new system files are timed automatically. `updateSpeed` (Hz) controls the flush cadence; `limit` caps rows (sorted by cost); `nameMaxChars` truncates scope names; `digits` sets time decimal precision and `valueMaxChars` caps the time column width (which is fixed so a digit-boundary change never shifts the `%` column). Scope keys are per component type (`ComponentType.update`). The profiler obeys the `debug` master switch: master off freezes its snapshot and hides the table.
- `snapshot` (top-level `Content/Data/Debug.lua` group, NOT under `hud`) — FPS-dip + ambient diagnostics logger to `Logs/Snapshot.txt`. While the profiler collects, it records each FPS dip below `fpsTarget` (falls back to `hud.fpsGraph.fpsTarget`, then 60), capturing the top `topScopes` profiler scopes plus an ambient line (frame split into update/draw/idle, measured vs unmeasured, GC, drawcalls, window). `rollupFps` (Hz; 0 = off) appends a sparse steady-state ambient line even when FPS never dips. Reads `debugData.snapshot`; implemented in `Source/Helpers/Snapshot.lua`, driven by `Snapshot.captureDraw`/`mark*Start`/`set*End` called from Main/Debug.

Implemented in `Source/Helpers/Debug.lua` (the shared Debug helper, one file): `Debug.update(dt)` samples FPS into a ring buffer and flushes profiler buckets; `Debug.draw(objectCount, scale)` renders the readout using LÖVE's default font (recreated when the scaled `size` changes). `Debug.enabled`/`Debug.settings` resolve dotted group paths, so the graph sub-group is queried as `"hud.fpsGraph"` and the profiler as `"hud.profiler"`.

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
