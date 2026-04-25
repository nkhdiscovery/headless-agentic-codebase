---
description: Audit docs for staleness and contradictions, propose new features
---

Audit the project docs and current state.

1. Read every file in `docs/` including ADRs.
2. Scan source code for actual current state.
3. Write `docs/audits/$(date +%Y-%m-%d-%H%M).md` with sections:

**Contradictions** — file:line, what doc says, what code shows.

**Stale assumptions** — claims that were true but aren't now.

**Quietly resolved open decisions** — items in product.md that have been decided in code but not written down.

**Doc gaps** — patterns that recur in code but aren't documented. Candidates for new ADRs.

**Refactoring opportunities** — worth >1hr saved future work.

**New feature ideas** — what would make the project meaningfully better.

For each finding:
- Clear-cut → file GitHub issue with `agent-proposed` + `priority:low`.
- Judgment-call → file with `needs-decision`.

Commit audit file via branch + self-merge.
