---
description: Report progress against the current phase in docs/phases.md
---

Report the current state of the build:

1. Read `docs/phases.md` to see the phases and deliverables.
2. List source modules to see which exist.
3. List `docs/decisions/` to count accepted ADRs.
4. List `plans/` for active plans without a merged PR.

Output format:

```
Current phase: <N>
Completed deliverables: <list>
In progress: <list>
Not started: <list>

Blockers / open questions:
- <assumptions flagged in active plans>
- <open decisions from docs/product.md>

ADRs accepted: <count>
Active plans: <count>
```

Be concise. This is a status report, not a design document.
