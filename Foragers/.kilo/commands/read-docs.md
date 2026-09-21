---
description: MANDATORY — read project rules (AGENTS.md) and LÖVE API docs (love_api.md) before starting ANY task
---

**You MUST complete every step below before doing any work. No exceptions.**

## 1. Read project rules in full
Read `.kilo/AGENTS.md` completely — mandatory architecture, code style, component rules. Do NOT skim, do NOT skip sections.

## 2. Know how to look up the LÖVE 11.5 API
Reference: `.kilo/documentation/love_api.md` (~4800 lines). **NEVER read it top-to-bottom — always grep it.**
For any `love.*` call, type, enum, or object method you're not 100% sure of, you MUST grep before writing:

```sh
grep -n "^### love.graphics.draw" .kilo/documentation/love_api.md   # functions
grep -n "^### Body <" .kilo/documentation/love_api.md               # types
grep -n "^### BlendMode$" .kilo/documentation/love_api.md           # enums (exact match)
grep -n "Body:applyForce" .kilo/documentation/love_api.md           # methods (no heading — broad match)
```

Then read ~30 lines from the matched line number. **If overloaded (`- Variant 2:`, `- Variant 3:`), you MUST read all variants before writing the call.**

## 3. Skip lookup only when
Pure Lua logic, or edits that don't touch LÖVE calls.

## Known enums/types
Object, DistanceModel, BlendMode, BodyType, KeyConstant, Scancode, PixelFormat, GraphicsFeature, WrapMode, ... — **grep for the exact name if unsure. Do NOT guess.**