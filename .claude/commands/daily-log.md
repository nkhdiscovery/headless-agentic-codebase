---
description: Append entry to today's daily log
---

Append to `logs/daily/$(date +%Y-%m-%d).md` for the task you finished.

Format:
```
- **#<issue>** <title>
  - Branch: agent/<n>-<slug>
  - PR: <url or "blocked by <reason>">
  - CI: pass / fail (<N> retries)
  - Time: <minutes>
  - Notes: <ADRs proposed, scope surprises, etc>
```

Create `logs/daily/` and the file if needed. Append in chronological order.
