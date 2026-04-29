# Project status

High-level, non-technical view of what's shipped, what's in flight, and what's next. Updated automatically by the agent every 12 hours and after every merge.

**Last updated:** _pending first update_
**Updated by:** _agent / human_

## Current focus

> Independent work packages run in parallel. Two collision checks gate new work: **conceptual** (same feature, different approach — needs human pick) and **mechanical** (same code area, real rebase). Files don't have to overlap to collide. The agent never stops the unattended loop; it defers or hands off when collisions show up.

**Active work packages:** 0
- _none_

**Deferred — mechanical overlap:** 0
- _none_

**Deferred — conceptual overlap (`needs-decision`):** 0
- _none_

**Blocked — other `needs-decision`:** 0
- _none_

**Agent-proposed backlog:** 0 ideas filed, 0 started
- _none_

## Feature status

| Feature | Status | Last updated | User-testable? | Notes |
|---------|--------|--------------|----------------|-------|
| _example: photo upload_ | 📋 planned | — | no | seed row — replace once real features land |

**Status legend**

- ✅ shipped — merged to main, available to users
- 🚧 in progress — open PR, work active
- 📋 planned — issue filed and ready
- ⏸ blocked — needs human decision
- ❌ abandoned — dropped after consideration

## How this page is maintained

The agent regenerates this file:

1. **After every merge** to `main` — updates the affected feature row.
2. **Every 12 hours** via the `status-update` cron workflow — re-reads merged PRs, open PRs, and labelled issues, then rewrites the table.

The agent never edits this file by hand outside those triggers. If a row looks stale, check whether the cron ran (`.github/workflows/status-update.yml`) or open an issue with the `status-update` label to force a refresh.

## What goes here

- One row per **user-facing feature**, not per module or per PR.
- Plain language. No file paths, no internal class names.
- "User-testable?" answers: can the human go click around and try this right now? If yes, link to the entry point (route, command, screen).
