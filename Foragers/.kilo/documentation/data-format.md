---
description: Exact format for sprite data files (.lua) in Content/Assets/Sprites/.
---

# Data File Format

## Location

`Content/Assets/Sprites/<Category>/<Name>.lua` — PNG must be same path with `.png` extension.

`SpriteLoader.loadAll()` scans recursively, auto-derives PNG from `.lua` path.

## Top-level fields

| Field | Type | Required | Default | Description |
|---|---|---|---|---|---|
| `object` | string | No | — | String identifier, copied to `sprite.object` at instantiation (used e.g. to exclude sprites from debug collision overlay). `"vegetable"` tags a prop as a vegetable — `Source/World/PropPicker.lua` splits props into veg/non-veg by this value and applies the world's vegetable cap + PRD to it |
| `host` | string | No | — | Host-provider type (e.g. `"bush"`). Marks the prop as a host that overlay foods (berries) can attach to. Registered in `HostRegistry` on spawn; unregistered on `PROP_BROKEN` |
| `frameWidth` | number | Yes* | — | Sprite frame width in pixels |
| `frameHeight` | number | Yes* | — | Sprite frame height in pixels |
| `pivotX` | number/string | No | `"center"` | X origin. Pixel number from top-left (e.g. `8` on a 16px frame = center) or keyword `"left"` / `"center"` / `"right"` |
| `pivotY` | number/string | No | `"center"` | Y origin. Pixel number from top-left or keyword `"top"` / `"center"` / `"bottom"` |
| `angle` | number/string | No | — | Visual rotation in degrees. Accepts `"min..max"` range for per-instance random (e.g. `"0..360"`). Resolved to a number at instantiation |
| `sortOffsetY` | number | No | 0 | Y-sort draw offset in pixels |
| `layer` | number | No | 0 | Draw layer (higher = drawn later) |
| `extends` | string | No | — | Base data file path for inheritance |
| `components` | table | No | — | Array of component configs |

*Required when using spritesheet animation.

## Component format

```lua
components = {
    {
        component = "spritesheet",  -- registered name (see ComponentRegistry)
        -- component-specific fields...
    },
}
```

Each component table is passed to `ComponentRegistry.create(name, data)`. See `components.md` for available fields per component.

## Animation format

```lua
animations = {
    idle = { row = 1, frames = 4, speed = 4, loop = true },
    run  = { row = 2, frames = 4, speed = 8, loop = true },
    death = { row = 5, frames = 4, speed = 8, duration = { 1, 1, 1, 4 }, loop = false },
}
```

| Field | Type | Description |
|---|---|---|
| `row` | number | Row in spritesheet (1-indexed) |
| `frames` | number | Number of frames in this animation |
| `speed` | number | Frames per second |
| `duration` | table (optional) | Per-frame hold weights, one entry per frame (default all `1`). Frame `i` holds `duration[i] / speed` seconds; total anim time = `sum(duration) / speed`. Uniform (`{}`/omitted) keeps each frame at `1 / speed` |
| `loop` | boolean | `true` = loop, `false` = play once |

## Tags (animation mapping)

```lua
tags = { idle = "stand", run = "walk" }
```

Maps state names → animation names. If omitted, state name = animation name.

## Inheritance (extends)

```lua
return {
    extends = "Content.Assets.Sprites.Props._Props",
    components = {
        { component = "destructible", hp = 7 },
    },
}
```

`Merge.resolveExtends()` deep-merges the base file into the child. Child fields override base fields. Components are matched by `component` type + occurrence index, then deep-merged, so a base may carry multiple components of the same type (e.g. two `particle_emitter`s) — they no longer collapse into one. A child override of a type merges with the base's first occurrence of that type, leaving later base occurrences intact. Shader `shaders` arrays concatenate (parent first, dedup by name). Base component order is preserved; new override entries are appended at the end.

## World.lua prop item fields

Each entry in `Content/Data/World.lua` `props.items` references a prop data file:

| Field | Type | Default | Description |
|---|---|---|---|
| `data` | string | — | Module path to the prop data file |
| `weight` | number | `1` | Weighted pick probability |
| `host` | string | nil | Host type this overlay food attaches to (e.g. `"bush"`). When set, the prop is spawned as a child on a registered host of that type instead of standalone |
| `offsetX` | number | `0` | Child X offset from the host pivot |
| `offsetY` | number | `0` | Child Y offset from the host pivot |
| `inheritFrame` | boolean | `false` | Start the child on the host's current animation frame |

## Complete example

```lua
return {
    object = "oak",
    frameWidth = 24,
    frameHeight = 32,
    pivotX = 0.5,
    pivotY = 0.95,
    sortOffsetY = 3,
    layer = 0,
    components = {
        {
            component = "spritesheet",
            columns = 3,
            animations = {
                idle = { row = 1, frames = 3, speed = 4, loop = true },
            },
        },
        {
            component = "collision",
            mode = "solid",
            collisionWidth = 6,
            collisionHeight = 6,
        },
        {
            component = "destructible",
            hp = 7,
            replaceWith = "Content/Assets/Sprites/Props/OakStumps",
        },
        {
            component = "drop",
            drops = {
                { sprite = "Content/Assets/Sprites/Drops/MediumCrystal", amount = "0|1" },
                { sprite = "Content/Assets/Sprites/Drops/SmallCrystal", amount = "1..3" },
            },
        },
        {
            component = "tween",
            tags = {
                prop_hit = {
                    { target = "brightness", from = 1, to = 0.5, duration = 0.2, curve = "InBack" },
                    { target = "scale_x", from = 0.8, to = 1, duration = 1.5, curve = "OutBack" },
                },
            },
        },
        {
            component = "sound",
            tags = {
                prop_hit = { "Content/Assets/Sounds/Events/WoodHit.ogg" },
                prop_broken = { "Content/Assets/Sounds/Events/WoodBreak.ogg" },
            },
        },
    },
}
```

## Common mistakes

| Mistake | Correct |
|---|---|
| `spriteSheet = "path/to.png"` at top level | PNG auto-derived from `.lua` path — do NOT specify |
| `frameDuration = 0.2` | Use `speed` (frames per second), not `frameDuration` |
| `frames = { 0, 1, 2, 3 }` | Use `row` + `frames` count, not array of indices |
| Creating new file instead of editing existing | Grep for existing patterns first |
