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