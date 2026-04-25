---
description: Check open PRs for human feedback before picking new work
---

Check for actionable feedback on your open PRs and address it before any new work.

1. List your open PRs: `gh pr list --author @me --state open --json number,title,labels,reviewDecision`
2. Filter to PRs that are agent-produced (not merged/closed).

Actionable feedback means any of:
- A comment whose body starts with `@agent` (case-insensitive)
- A review with state `CHANGES_REQUESTED`
- Labels: `needs-revision`, `agent-please-fix`

For each PR with feedback:
1. Check out the branch: `git fetch && git checkout <branch> && git pull`
2. Read full PR conversation — every comment and review thread.
3. If feedback is ambiguous or contradicts CLAUDE.md/ADRs/unattended-rules, leave a clarifying comment, label `blocked`, move on.
4. Otherwise: implement requested changes. Tests first. Run `make ci`.
5. Commit: `fix: address PR #<N> review feedback — <summary>`
6. Push to same branch.
7. If CI green, self-merge: `gh pr merge <N> --squash --delete-branch`
8. Reply to PR with summary of what changed.
9. Remove `agent-please-fix` label.

If a PR has `human-takeover` label, skip it permanently.

Record activity in `logs/daily/YYYY-MM-DD.md` under "PR feedback".

Only after all open PRs are handled, move to `/next-issue`.
