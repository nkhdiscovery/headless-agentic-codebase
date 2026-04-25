# Unattended operation — rules

The agent operates with **full autonomy** — designs, builds, merges, and ships without waiting for human approval. The human reviews progress asynchronously via `logs/progress.md` and GitHub history.

When unattended mode is active, `.claude/unattended` exists at the repo root.

## Mindset

You are a founding engineer with product authority. Ship working tested code. Everything else is judgment.

## The work loop

**One cycle = one work package.** Each `claude -p` invocation handles exactly one PR or one issue end-to-end, then exits. The launcher restarts you immediately if there's more work, or sleeps if the queue is idle. This keeps each cycle's context small, makes the cost-per-PR figure meaningful, and isolates failures.

0. **First-cycle bootstrap.** If `docs/stack.md` exists at the repo root, this is a freshly bootstrapped project and the human has decided which stacks and addons to use but hasn't applied them yet. Read `docs/stack.md` in full, follow its "Apply instructions for the agent" section, run `make ci` until green, move the file to `docs/stack-applied.md`. Then check the repo's `README.md` — if it still contains template boilerplate (e.g. "Agent Project Pack", "drop-in template", "headless agentic codebase"), replace it with a project-specific README based on `CLAUDE.md`, `docs/product.md`, `docs/architecture.md`, and `docs/stack-applied.md`. Sections: one-line pitch, what it does (2 paragraphs), tech stack, quick start (clone + install + run), how the agent works on this project (link to GETTING_STARTED.md and CLAUDE.md), license. No marketing fluff, no emojis, 200-400 words. Commit everything as `chore: apply stack, addons, and project README per docs/stack.md`, self-merge. This counts as your one work package — exit after.

### Pick exactly one of (A), (B), or (C) per cycle

**(A) PR feedback** — if any open PR has the `agent-please-fix` label, an `@agent` comment, or a `CHANGES_REQUESTED` review:

1. Pick the oldest such PR.
2. Address the feedback on the existing branch.
3. Push, get CI green (max 5 runs total, see CI failure handling below).
4. Self-merge if appropriate, or hand off via `human-only-merge` / `needs-decision` if blocked.
5. Post cycle cost comment per "Cost transparency on PRs" section below.
6. Log progress, exit.

**(B) New work** — otherwise, if there are `ready-for-agent` issues open:

1. Pick the highest-priority issue (`priority:high` → `med` → `low` → unlabelled; lowest issue number wins ties).
2. Add `in-progress` label, comment "Starting work. Branch: agent/<n>-<slug>."
3. Branch: `git checkout main && git pull && git checkout -b agent/<n>-<slug>`.
4. Plan: write `plans/<n>-<slug>.md` with problem, approach, files, risks.
5. Tests first: failing tests before implementation.
6. Implement, run `make ci`.
7. Push, open PR, address CI failures (max 5 runs total).
8. Self-merge: `gh pr merge <N> --squash --delete-branch` after CI green.
9. Post cycle cost comment per "Cost transparency on PRs" section below.
10. Append plain-English entry to `logs/progress.md`.
11. Append technical entry to `logs/daily/YYYY-MM-DD.md`.
12. Exit.

**(C) Self-audit** — otherwise (queue empty, no PR feedback):

1. Briefly review recent merges, the issue list, and `logs/progress.md`.
2. If you spot a real gap (missing tests, broken-window code, undocumented module), file at most ONE issue with `agent-proposed` label and exit.
3. Otherwise just exit.

### Hard rule: do not chain work packages

Even if (A) finishes quickly and (B) has work waiting, do not start (B) in the same cycle. Exit. The launcher will start a fresh cycle for the next work package within seconds when the queue is non-empty (burst mode). Chaining bloats context and muddles cost attribution.

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

## Cost transparency on PRs

After each cycle that pushed commits to a PR (either iterating on feedback or opening a new one), post a comment with that cycle's spend so the human can see incremental cost. Use the helper script:

```bash
CYCLE=$(bash scripts/agent-cost.sh pr-cost)
TOTAL=$(bash scripts/agent-cost.sh pr-total <PR_NUMBER>)
gh pr comment <PR_NUMBER> --body "Cycle cost: \$${CYCLE}. Total on this PR: \$${TOTAL}."
```

`pr-cost` reports this cycle's spend. `pr-total` reads existing `Cycle cost:` comments on the PR and adds this cycle, returning a running total.

**High-cost warning.** After posting the cycle cost, check the threshold:

```bash
THRESHOLD=$(bash scripts/agent-cost.sh pr-warn-threshold)
```

If `THRESHOLD` is non-zero AND `TOTAL >= THRESHOLD` AND the PR doesn't already have the `high-cost` label:

1. Add the `high-cost` label: `gh pr edit <PR_NUMBER> --add-label high-cost`.
2. Post a one-time warning comment:

```
⚠️ This PR has accumulated $<TOTAL> in agent work, exceeding the AGENT_PR_COST_WARN_USD threshold of $<THRESHOLD>.

Options to control this PR:
- **Let it continue** — no action needed, agent keeps trying
- **Take over** — add `human-takeover` label, agent stops on this PR
- **Abandon** — close the PR; the related issue stays open and unlabelled until you re-queue it
- **Re-scope** — comment `@agent <new direction>` and add `agent-please-fix`
- **Pause all agent work** — `make agent-stop` on the host

Continuing without action.
```

3. Do NOT post this warning more than once per PR — the `high-cost` label is the gate.
4. Continue working on the PR — the warning is informational only. The agent does not stop on its own; the human decides.

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
