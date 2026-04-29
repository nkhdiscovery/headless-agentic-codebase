---
name: Agent-ready task
about: Well-scoped task the unattended agent can implement end-to-end
title: "[task] "
labels: ["ready-for-agent"]
---

<!--
SCOPE GUIDE — read before filing.

✅ Good scope (one PR, ≤5 files):
  - "Add GET /photos/:id endpoint with auth check"
  - "Implement retry logic in upload service"
  - "Cache thumbnail URLs in the photo list view"

❌ Too broad — split before filing:
  - "Implement photo upload with thumbnails, metadata, and search"
       → split into upload, thumbnails, metadata, search
  - "Refactor auth + add new permissions system"
       → split refactor from new feature
  - "Modernise the API"
       → not a task, that's an epic; file as `tracking` instead

If your task feels like the right column, stop and split it. The agent
will refuse anything touching >5 files and bounce it back as
`needs-decision`.
-->

## What needs to happen
<!-- One clear sentence. Too big = split it. -->

## Why
<!-- Link to phase, ADR, or feature this supports. -->

## Acceptance criteria
- [ ]
- [ ]
- [ ]

## Files likely to change
<!-- Aim for ≤5. If you can't list them, the task isn't scoped yet. -->
-

## Out of scope
<!-- Related improvements you are NOT asking for in this PR. -->
-

## Priority
<!-- Add priority:high, priority:med, or priority:low after creating. -->
