---
description: Check and update project documentation after code changes
---

## Before start

Read all changed files first — know what signatures, events, config fields, and behaviors changed.

## Step 1. Enumerate changed concepts

For each modified file, list every public API, event constant, config field, or component behavior that was added, removed, or changed.

## Step 2. Check existing docs

Open each `.md` in `.kilo/documentation/` (except `love_api.md`) and grep for anything from step 1:

| File | Check |
|---|---|
| `components.md` | Component purpose, config fields, subscribed events, emitted events |
| `events.md` | Event name, emitter, listener priorities |
| `data-format.md` | Sprite data format if a new field was added |

Also check `AGENTS.md` — if AGENTS.md has a prose section or table that references what changed, update it.

## Step 3. Update or add docs

- Add new event rows to `events.md`
- Update component rows in `components.md`: config fields, subscribes, emits
- If `data-format.md` documents a config field that changed, update it
- Write rationale comments only — no prose "how-to" that code already explains

## Step 4. Verify cross-references

After editing, check that:

- Every new event constant in `Events.lua` has a row in `events.md`
- Every new event listener/subscriber is listed in `components.md`
- Priority numbers in docs match actual code
- No dangling references to removed events or fields

## Step 5. Final check

Re-read the changed documentation files. If a reader only had the docs (not the code), would they know the correct event names, priorities, and config fields? If not, add the missing info.
