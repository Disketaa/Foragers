---
description: Check written/changed code for unnecessary and empty comments
agent: code
---

Comments only if:
- explain "why", not "what" (code already says what)
- describe non-obvious contract between functions/modules
- LuaDoc type annotations

Do NOT write a comment if removing it leaves the code
self-explanatory. When unsure — don't write.
