---
description: Prepare a commit with staged changes (no push)
---

1. Run `git status` and `git diff` to see what changed and why.
2. Stage and commit from Disketaa.

Format:
- Title: short summary, capitalized, describing what was done (the essence of the change, not "updated file X")
- Body: inline description of details, also capitalized, only if the title isn't enough

If the diff contains unrelated changes (different files/purpose), call it out instead of squashing everything into one vague title.

Do NOT write generic messages like "Update code" or "Fix bug".
Do NOT push — only git add + git commit.