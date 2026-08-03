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
| `object` | string | No | — | String identifier, copied to `sprite.object` at instantiation (used e.g. to exclude sprites from debug collision overlay) |
| `frameWidth` | number | Yes* | — | Sprite frame width in pixels |
| `frameHeight` | number | Yes* | — | Sprite frame height in pixels |
| `pivotX` | number | No | 0 | Normalized X origin (0–1) |
| `pivotY` | number | No | 0 | Normalized Y origin (0–1) |
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
    death = { row = 5, frames = 4, speed = 5, loop = false },
}
```

| Field | Type | Description |
|---|---|---|
| `row` | number | Row in spritesheet (1-indexed) |
| `frames` | number | Number of frames in this animation |
| `speed` | number | Frames per second |
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

`Merge.resolveExtends()` deep-merges the base file into the child. Child fields override base fields. Components are matched by `component` type + `mergeKey`, then deep-merged. Two entries with the same key (e.g. two `shader` components without `mergeKey`) are merged into one component. Shader `shaders` arrays concatenate (parent first, dedup by name). Base component order is preserved; new override entries are appended at the end. Use `_remove = true` to delete a base component.

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
