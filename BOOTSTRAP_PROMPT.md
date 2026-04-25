# Remote project bootstrap — paste this into any AI chat

You are helping me bootstrap a new project that will be built by an autonomous Claude Code agent. I'm on my phone. I have:

- The GitHub mobile app (can create repos, edit files, manage issues)
- This chat (you)
- A base agent infrastructure repo I'll fork/template from

I do NOT have a laptop right now. We are filling in **only the project-specific files** — the generic infrastructure (Docker, Makefile, CI, slash commands, unattended rules) is already in the base repo and stays as-is.

## Your job

Walk me through filling in **5 files**, in this order. After each, give me the file path and the full content I can copy-paste into the GitHub mobile app's edit view. Keep each file short and sharp — no padding.

For each file, ask me **at most 3 focused questions** before drafting. If my answers leave gaps, make sensible defaults and flag them so I can correct later.

### File 1 — `CLAUDE.md` (repo root)

Contains:
- Project name + one-paragraph description
- 3-8 architecture invariants (the things that mustn't change without an ADR)
- Coding conventions for the chosen stack
- Hard limits (what the agent must never do)

Ask me: project name, what it does in plain English, who it's for, what tech stack.

### File 2 — `docs/product.md`

Contains:
- One-line pitch
- 2-3 paragraph vision
- Problems it solves (3-5 bullets)
- Target users (specific)
- Business model (free/paid/subscription/etc)
- Open decisions (things I haven't decided yet)
- Out of scope (what we're explicitly NOT building)

Ask me: business model, who pays, what's intentionally NOT in scope.

### File 3 — `docs/architecture.md`

Contains:
- The single most important architectural decision (the abstraction everything hangs off)
- Stack table (language/framework/database/etc with ADR refs)
- Module structure (top-level packages and what each owns)
- Data flow (where data enters, processes, exits)
- Security model (auth, secrets, isolation)
- Deployment (where it runs, how it updates)

Ask me: any non-obvious technical constraints, where it deploys, what the central abstraction is.

### File 4 — `docs/phases.md`

Contains:
- 4-6 build phases, 2-4 weeks each for solo+agent
- Each phase has clear "Done when" criteria
- Sequencing rule (the one thing that must land first)

Ask me: what's the smallest valuable thing to ship first, what comes next, what's the MVP boundary.

### File 5 — `docs/decisions/0001-<slug>.md`

The first ADR — usually about the central architectural abstraction from File 3.

Format:
```
# ADR 0001 — <title>

**Status:** Accepted
**Date:** <today>

## Context
## Decision
## Consequences
**Positive:**
**Negative:**
## Alternatives considered
## Enforcement
```

## Output format

For each file, give me:

1. **File path** (so I know where to paste it in GitHub mobile)
2. **Commit message** to use
3. **The full file content** in a single code block, ready to copy

After all 5 files are drafted, give me a final block with:

- 5-8 starter GitHub issues with `ready-for-agent` label and clear acceptance criteria, in this format:
  ```
  Title: <one line>
  Labels: ready-for-agent, priority:high|med|low
  Body:
  <multi-line spec>
  ```
- A list of any open questions I still need to resolve before launching the agent

## Constraints

- No emojis anywhere in the files.
- No marketing fluff. Direct, technical writing.
- If I describe something that's outside the agent's capabilities (e.g. needs hardware design, legal review, real-world contracts), call it out and put it in the "Open decisions" section, not the build queue.
- Default coding conventions to: type hints/strict typing, formatter+linter in CI, tests required, conventional commits, no secrets in code.
- The infrastructure repo I'm forking already has Docker, Makefile, CI workflow, slash commands, unattended-rules.md, PR template, issue template — don't regenerate any of these.

## Start

Ask me your first round of questions about the project. After my answers, draft File 1.
