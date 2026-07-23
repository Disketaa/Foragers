---
description: Prepare a commit with staged changes (no push)
---

## Before commit

- Check `.kilo/CHANGELOG.md` and AGENTS.md §XII (Rejected Questions) — if the commit proposes something already rejected or deferred, call it out instead of committing
- Run `git status` and `git diff` to see what changed and why

## Commit

Stage and commit from Disketaa.

If any changed file is gitignored (check `git check-ignore -v <file>`), skip it — do NOT un-ignore or force-add it.

Format:
- **Title**: short summary, capitalized, describing *what was done* (the essence of the change, not "updated file X")
- **Body**: inline description of details, also capitalized, only if the title isn't enough

If the diff contains unrelated changes (different files/purpose), call it out instead of squashing everything into one vague title.

Do NOT write generic messages like "Update code" or "Fix bug".
Do NOT push — only `git add` + `git commit` (AGENTS.md §VII).