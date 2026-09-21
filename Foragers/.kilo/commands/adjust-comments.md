---
description: MANDATORY comment audit for ALL written/changed code — check every edited file for unnecessary and empty comments
---

## Rule
After writing or changing ANY code, scan **every edited file** — not just the one you were asked about — and remove/verify comments. Non-negotiable.

## Comments only if
- Explain **"why"**, not "what" — the code already says what
- Describe a **non-obvious contract** between functions/modules
- Are **LuaDoc type annotations**

If removing a comment leaves the code self-explanatory — **delete it**. When unsure — don't write.

## Forbidden
Do NOT write empty, redundant, restating-the-code, or filler comments. Treat them as bugs.
Do NOT skip re-checking every edited file before finishing a task — no exceptions.