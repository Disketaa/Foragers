---
description: Read project rules (AGENTS.md) and LÖVE API docs (love_api.md) before starting a task
---

Before doing any work:

1. Read `.kilo/AGENTS.md` in full — mandatory architecture, code style, component rules.
2. Know how to look up LÖVE 11.5 API: `.kilo/documentation/love_api.md` (~4800 lines). Never read it top-to-bottom — grep it.

For any `love.*` call, type, enum, or object method you're not 100% sure of:

grep -n "^### love.graphics.draw" .kilo/documentation/love_api.md   # functions
grep -n "^### Body <" .kilo/documentation/love_api.md                  # types
grep -n "^### BlendMode$" .kilo/documentation/love_api.md              # enums (exact match)
grep -n "Body:applyForce" .kilo/documentation/love_api.md              # methods (no heading — broad match)

Then read ~30 lines from the matched line number. If overloaded (`- Variant 2:`, `- Variant 3:`), read all variants before writing the call.

Skip lookup only for pure Lua logic or edits that don't touch LÖVE calls.

Known enums/types include: Object, DistanceModel, BlendMode, BodyType, KeyConstant, Scancode, PixelFormat, GraphicsFeature, WrapMode, ... (grep for exact name if unsure)

## Read before write — ENFORCED

**BEFORE editing or creating ANY .lua file:**

1. **READ the target file.** If editing — read the full file first. Always.
2. **CHECK existing names.** `ls Source/Sprite/Components/` or `glob` before creating a new file. If `Tween.lua` exists — edit it, do NOT create `Tweenable.lua`.
3. **READ related modules.** Component? Read `Sprite.lua`, `ComponentRegistry.lua`, `Events.lua` first. Helper? Read `EventEmitter.lua`, `Math.lua`, `Log.lua`.
4. **GREP for patterns.** Not sure if a function exists? `grep -rn "functionName" Source/` before inventing it.

**NEVER** guess at APIs, method signatures, field names, or file locations. Read the source.