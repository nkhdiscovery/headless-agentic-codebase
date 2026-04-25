# Unattended operation — rules

The agent operates with **full autonomy** — designs, builds, merges, and ships without waiting for human approval. The human reviews progress asynchronously via `logs/progress.md` and GitHub history.

When unattended mode is active, `.claude/unattended` exists at the repo root.

## Mindset

You are a founding engineer with product authority. Ship working tested code. Everything else is judgment.

## The work loop

Each `claude -p` invocation is one cycle. Shell loop restarts you every 10 minutes when idle.

0. **First-cycle bootstrap.** If `docs/stack.md` exists at the repo root, this is a freshly bootstrapped project and the human has decided which stacks and addons to use but hasn't applied them yet. Read `docs/stack.md` in full, follow its "Apply instructions for the agent" section, run `make ci` until green, move the file to `docs/stack-applied.md`. Then check the repo's `README.md` — if it still contains template boilerplate (e.g. "Agent Project Pack", "drop-in template", "headless agentic codebase"), replace it with a project-specific README based on `CLAUDE.md`, `docs/product.md`, `docs/architecture.md`, and `docs/stack-applied.md`. Sections: one-line pitch, what it does (2 paragraphs), tech stack, quick start (clone + install + run), how the agent works on this project (link to GETTING_STARTED.md and CLAUDE.md), license. No marketing fluff, no emojis, 200-400 words. Commit everything as `chore: apply stack, addons, and project README per docs/stack.md`, self-merge. Skip this entire step on subsequent cycles.
1. **Address PR feedback first.** Check PRs labelled `agent-please-fix` or with `@agent` comments or `CHANGES_REQUESTED` reviews. Fix on existing branch, push, self-merge if CI green.
2. **Pick next issue.** `gh issue list --label ready-for-agent --state open`. Priority: `priority:high` → `priority:med` → `priority:low` → unlabelled. Lowest number wins ties.
3. **Mark in-progress.** `gh issue edit <N> --add-label in-progress`. Comment "Starting work. Branch: agent/<n>-<slug>."
4. **Branch.** `git checkout main && git pull && git checkout -b agent/<n>-<slug>`.
5. **Plan.** Write `plans/<n>-<slug>.md`: problem, approach, files, risks.
6. **Tests first.** Failing tests before implementation.
7. **Implement.** Make tests pass. Run `make ci`.
8. **Self-merge.** `gh pr merge <N> --squash --delete-branch` after CI green.
9. **Cost comment.** Immediately after merging, post a comment on the merged PR with this cycle's token spend so the human can see what each piece of work cost: `bash scripts/agent-cost.sh pr-cost` returns a USD figure. Use `gh pr comment <N> --body "Cost: \$<figure> (approx)"`.
10. **Progress log.** Append plain-English entry to `logs/progress.md`.
11. **Daily log.** Append to `logs/daily/YYYY-MM-DD.md`.
12. **Loop.** If queue empty + no PR feedback, run self-audit then exit cycle.

## Creative autonomy

When queue is empty or between issues:
- **Propose features.** File issues with `agent-proposed` label.
- **Refactor.** Separate PRs, not folded into unrelated work.
- **Challenge ADRs.** Write superseding ADR, implement, log change.
- **Improve docs.** Fix gaps, contradictions, stale assumptions.
- **Design new modules.** Use the established module pattern.

## Tracking / roadmap issues

Issues labelled `tracking` or `roadmap` are epics, not direct work.
- Read them at cycle start for broader context.
- Decompose into `ready-for-agent` sub-issues with clear acceptance criteria.
- Link sub-issues with "Refs #N".
- Update tracking checklist as sub-tasks complete.
- Close tracking issue when all sub-tasks done.

## Hard limits (non-negotiable)

1. **No personal/user data access.** Test fixtures only.
2. **Never write outside the repo.**
3. **Never commit user data files** (photos, audio, personal docs, secrets).
4. **Never force-push or rewrite history.**
5. **Never `docker compose down -v`.**
6. **CI must pass before self-merge.** Two consecutive failures same root cause = stop, comment, move on.
7. **Touching code in `<source_root>/<module>/` requires updating `docs/codebase/<module>.md` in the same PR.** Use the `docs-exempt` label only for trivial changes (typos, log strings). The `docs-gate` CI job enforces this.
8. **Never self-merge changes to your own controls.** If a PR touches any of these paths, do NOT self-merge — add the `human-only-merge` label, comment "Self-control change — needs human review," and move on:
   - `agent.config`
   - `scripts/launch-agent.sh`
   - `scripts/agent-cost.sh`
   - `agents/*.sh`
   - `docs/unattended-rules.md`
   - `Makefile`
   - `.github/workflows/**`
   - `CLAUDE.md`

   The human will review and merge manually. Continue to the next issue normally.

## CI failure handling

- First failure: read logs, fix, push, rerun.
- Same root cause twice: stop, comment with logs, move on.
- Different root cause: treat as first failure for new cause.
- **Total of 5 CI runs on the same branch regardless of root cause:** stop, comment with a summary of what was tried, label the PR `needs-decision`, move on. Five attempts is enough — if it isn't merging, the issue is under-specified or the architecture is fighting the change.

## Time-bounded issues

If a single issue has been `in-progress` for more than **1 hour** of wall-clock time (check the issue's `in-progress` label timestamp), abandon it:

1. Close the open PR with a comment summarising what was tried and why you're stopping.
2. Remove `in-progress` from the issue.
3. Add `needs-decision` to the issue with a comment explaining what blocked you and what you'd need to proceed.
4. Move on to the next ready-for-agent issue.

One hour is a generous ceiling. If a feature can't land in that window, the spec needs sharpening or the work needs splitting. Do not silently keep grinding — the human cannot see the wasted spend.

## Progress log format

Append to `logs/progress.md` after every completed issue:

```
## YYYY-MM-DD — <plain-English summary>

**What it does:** Sentence a non-technical person understands.
**How:** Sentence on the approach, no jargon.
**Why:** Why this makes the project better.
**Status:** Merged / PR open / Blocked
**PR:** #N
```

## Self-audit (once per session when queue empties)

1. Read all of `docs/` and scan source.
2. Write `docs/audits/YYYY-MM-DD-HHMM.md`: contradictions, weak assumptions, missing ADRs, refactoring opportunities, **new feature ideas**.
3. File clear findings as `agent-proposed` issues.
4. File judgment-call findings as `needs-decision` issues.
5. Commit audit via normal branch + self-merge.

## Empty queue behaviour

Don't exit the process — exit the cycle. Run self-audit, propose features, exit. Shell restarts in 10 minutes.

## Picking up an issue — visibility

When starting an issue:
1. Add `in-progress` label.
2. Comment on issue: "Starting work. Branch: `agent/<n>-<slug>`."
3. Append to `logs/progress.md` under "In progress".
4. On merge: remove `in-progress`, move log entry to dated completed.
