## ⚠️ GitHub Actions billing warning

**GitHub Actions can charge you even on a "free" account.** The free tier
ships a limited monthly allowance of runner minutes (private repos only —
public repos are free). Once you exceed it, GitHub bills the credit card on
file. Misconfigured workflows (matrix builds, runaway loops, frequent crons,
self-hosted-runner mistakes) have produced four-figure bills for hobbyists.

For this reason, **CI on GitHub Actions is OPT-IN and HUMAN-ONLY in this
template**. The agent never enables it, never re-enables it, never adds new
workflow files, and treats `.github/workflows/**` as a self-control file
(see `docs/unattended-rules.md` hard limit 8).

## Default workflow (no GitHub Actions)

The default merge gate is **local** test runs:

1. Agent runs `make ci` inside its container.
2. Agent captures the output and posts it as a PR comment, naming each test
   suite that ran and the pass/fail result.
3. Agent self-merges **only if local `make ci` exited 0**.

This costs you nothing on GitHub's side. The cost is reflected in the agent's
own token spend, which is already tracked per-PR by `scripts/agent-cost.sh`.

## Files in this directory

- `ci.yml.optional` — **DISABLED.** Template for the lint/test/docs-gate
  workflow. Rename to `ci.yml` to enable. Read the warning above first.
- `status-update.yml` — **ACTIVE.** Cron that fires every 12h to file a
  `status-update` issue for the agent. Uses ~30s of runner time per run
  (~30 minutes/month). Cheap, but still uses minutes — disable it by
  renaming to `.optional` if you want zero Actions usage.

## Enabling CI (human only)

If you understand the billing risk and want GitHub-side CI:

```bash
# Read the billing warning above first.
mv .github/workflows/ci.yml.optional .github/workflows/ci.yml
# Customise the lint/test commands for your stack, commit, push.
```

Recommended safety steps before enabling:

1. Set a **spending limit of $0** on your GitHub account
   (Settings → Billing → Spending limits → Actions). This caps overage at
   the free allowance instead of billing your card.
2. Add `concurrency` with `cancel-in-progress: true` (the template already
   does this) so re-pushes cancel stale runs.
3. Avoid matrix builds and scheduled workflows unless you've calculated the
   monthly minute cost.
4. Watch your usage at Settings → Billing → Plans and usage → Actions.

## Why the agent doesn't manage this

`.github/workflows/**` is listed under hard limit 8 in
`docs/unattended-rules.md`. The agent will not self-merge changes to any
workflow file — those PRs get the `human-only-merge` label and wait for you.
This protects you from an agent accidentally re-enabling CI or writing an
expensive workflow.
