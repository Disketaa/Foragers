---
description: Hard-won lessons from past work — read before coding in these areas
---

# ABSTRACTIONS — lessons for future agents

Short, brutal notes on mistakes already made so you don't repeat them. Read the
relevant section before touching that subsystem.

## Shader modules (Source/Helpers/ShaderLoader.lua, Source/Sprite/Components/Shader.lua)

- **Module files MUST be `.lua`, never `.glslinc`.** LÖVE `require` only loads
  `.lua`; `ShaderLoader` scans only `%.lua$`. A `.glslinc` module is silently
  never loaded → `compose` returns nil → shader not applied, no error.
- **In `effect()`, `color` is already a parameter.** Never write
  `vec4 color = Texel(...)`. That is a GLSL redefinition error
  (`'color' : redefinition`). Assign into it: `vec4 sampled = Texel(...); color = sampled;`
- **Never put a Lua comment string into the generated GLSL.** A Lua string
  `"	-- effect() ..."` concatenated into the shader source becomes GLSL `--`
  (decrement operator) → `'--' : l-value required`. Write rationale as a Lua
  comment OUTSIDE the string concatenation, not inside the GLSL code string.
- **Exactly one `Texel` call.** Pipeline is uv-chain → single `Texel` →
  color-chain. A module that re-`Texel`s overwrites the earlier sample (last
  wins), so stacking color modules via separate `Texel` calls does not compose.
- **`compose(names)` is cached by joined name.** Repeat calls with the same
  module set return the cached program — do not expect a fresh shader.
- **Module types:** `type = "uv"` exposes `Name_uv(vec2 uv, vec2 screen_coords)`
  and returns modified `uv`; `type = "color"` exposes `Name_color(vec4 color)`
  and returns modified `color`. Both are `module = true`.
- **Shader component reads `shaders` (array) or legacy `shaderName` (string).**
  Data uses `shaders = { "Brightness", "Wind" }`. Merge collapses by key
  `"shader:"`, so a child's `shaders` overrides the base into ONE shader component.
- **LÖVE does NOT auto-declare uniforms.** Every uniform must be an `extern` in
  the GLSL source or `shader:send` silently does nothing. `ShaderLoader` injects
  `extern` declarations automatically from each module's `uniforms` table.
- **Compile errors are swallowed by `pcall` in `compose`.** If a composed shader
  shows no effect, the cause is almost always a GLSL compile failure returning
  nil. Temporarily print the `pcall` error (or write the generated source) to see it.

## LÖVE filesystem / paths (PowerShell tooling note)

- The `filesystem_*` tools are bound to a different root than the project
  (`C:\Projects\Pixel-Portfolio`), so they deny access to
  `C:\Projects\Foragers\...`. Use `bash` (PowerShell) for file moves/creates
  instead.
- PowerShell 5.1 `New-Item`/`Move-Item` here do NOT accept `-LiteralPath` for
  `New-Item` (parameter binding error). Use `-Path`. A failed `New-Item` aborts
  the whole `;` chain, so create directories BEFORE moving files, and verify
  files still exist after a botched move — a partial move can lose files that
  must be recreated from known content.
- `Path.lua` converts `Content/Assets/Shaders/Sprite/Color/X.lua` →
  `Content.Assets.Shaders.Sprite.Color.X` for `require`. Recursive
  `ShaderLoader.loadAll` finds modules at any nesting depth, so restructuring
  shader folders needs NO code change — only the file moves.

## Debug flags

- `_G.SHADER_DEBUG` was used temporarily for console prints / file dumps. It is
  removed from `conf.lua` when done. Do not leave debug prints or
  `love.filesystem.write` of generated shaders in shipped code.
