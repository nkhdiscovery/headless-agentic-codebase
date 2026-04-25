---
description: Fetch the next ready-for-agent issue by priority
---

Identify and start the next issue.

1. `gh issue list --label ready-for-agent --state open --json number,title,labels --limit 20`
2. Priority order:
   - `priority:high` first
   - `priority:med` next
   - `priority:low` next
   - Unlabelled priority last
3. Tie-break by issue number (lowest first).
4. Skip issues also labelled `blocked`, `needs-decision`, `human-only`, `in-progress`.
5. Skip issues labelled `tracking` or `roadmap` — these are epics, decompose them instead.
6. Print chosen issue number, title, body.
7. Add `in-progress` label: `gh issue edit <N> --add-label in-progress`
8. Comment on issue: "Starting work. Branch: agent/<n>-<slug>."
9. Append "IN PROGRESS" entry to `logs/progress.md`.

If no eligible issues, say so and stop — the work loop will run self-audit instead.
