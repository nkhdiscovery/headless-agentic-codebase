# Stack and addon picker — paste this into any AI chat

You are helping me decide which language stacks and feature addons to use for a project I'm bootstrapping with the [headless agentic codebase](https://github.com/nkhdiscovery/headless-agentic-codebase) template.

I've already done the bootstrap step (CLAUDE.md, product.md, architecture.md, phases.md, ADR 0001 are filled in). Your job is to **decide** the stack — not to apply it. The agent will apply it on its first run.

I am NOT a stack expert. Don't ask me about database drivers or test runners — make sensible choices and explain in one line each.

## Your job (two phases)

### Phase 1 — Decide (5 minutes)

Ask me 4 short questions:

1. **What does the project do, in one sentence?**
2. **Where does it run?** (User's laptop, our server, user's phone, embedded device, mix.)
3. **Who uses it?** (Consumers — care about polish / Developers — tolerate rough edges / Internal team only.)
4. **What's the smallest valuable thing to ship first?**

Then propose a **picked set** in this format:

```
Stacks: <python | node | go | rust>[, <second if needed>]
Addons: <comma-separated from: fastapi, nextjs, mobile-rn, mobile-native, desktop-tauri, cli-tool, openapi-clients>

Why this set:
- <one line per stack>
- <one line per addon>

Deliberately left out:
- <addon they might expect> — because <reason>
```

Wait for me to confirm or push back. If I push back, revise once and re-confirm.

### Phase 2 — Write the decision doc

Once I confirm, produce **one file**: the contents of `docs/stack.md`.

Format:

```markdown
# Stack and addons — apply on first agent run

This file is read by the agent on its first cycle. After successful application,
the agent will move this to `docs/stack-applied.md` so it doesn't re-run.

## Decided

**Stacks:** <list>
**Addons:** <list>

## Rationale

<one line per stack>
<one line per addon>
<one line per deliberately-omitted addon>

## Project metadata for templates

These values fill in `{{PLACEHOLDERS}}` in the scaffold files:

- PROJECT_NAME: <kebab-case name from the user>
- PROJECT_DESCRIPTION: <one-line description>
- PROJECT_PACKAGE: <python_package_name in snake_case, used as src/<package>/>
- PROJECT_BUNDLE_ID: <reverse-domain bundle id for mobile, e.g. com.example.app>
- SOURCE_ROOT: <root dir for code: src for most, frame for python projects, web for next.js, etc>
- PRIMARY_EXT: <main file extension: py, ts, go, rs>

## Apply instructions for the agent

When you (the agent) see this file at the repo root on a cycle:

1. Verify all stacks and addons listed exist in the repo's `stacks/` and `addons/` directories.
2. For each picked stack:
   a. Append `stacks/<n>/Dockerfile.snippet` to `docker/Dockerfile.dev`
   b. Read `stacks/<n>/Makefile.snippet` and replace the placeholder `test`, `lint`, `format` targets in the root `Makefile` with its content
   c. Copy `stacks/<n>/<manifest>.template` to repo root (e.g. `pyproject.toml.template` -> `pyproject.toml`), filling in placeholders
3. For each picked addon:
   a. Read `addons/<n>/README.md` for any addon-specific apply notes
   b. Copy `addons/<n>/scaffold/` contents into the project at the location the README specifies
   c. Append the addon's CLAUDE.md invariant block (from its README) to the project's `CLAUDE.md`
   d. If the addon adds dependencies, merge them into `pyproject.toml` / `package.json` / `Cargo.toml` as appropriate
4. Update `.github/workflows/ci.yml`:
   - Set `DOCS_GATE_SOURCE_ROOT: <SOURCE_ROOT from above>`
   - Set `DOCS_GATE_EXT: <PRIMARY_EXT from above>`
   - Add stack-specific lint/test jobs if the stack provides a `ci.yml.snippet`
5. Run `make build` then `make ci`. If anything fails, fix until green.
6. Move this file to `docs/stack-applied.md` so subsequent cycles skip the apply.
7. Commit as: `chore: apply stack (<stacks>) and addons (<addons>) per docs/stack.md`
8. Open and self-merge the PR per the standard work loop.

If any step fails:
- Open an issue with `needs-decision` label describing the failure
- Do NOT delete or modify `docs/stack.md` — leave it for human review
- Move on to the next ready-for-agent issue

## Daily commands cheat sheet (post-application)

For the picked combination, the user will mostly run:

<list 3-5 commands they'll use daily — `make daemon`, `make test`, `make agent-start`, etc>

## First three issues to file

Three concrete `ready-for-agent` issues sized for the picked stack:

<3 issues with title, labels, body that get the agent moving on real work>
```

## Constraints

- **No emojis.**
- **One file output. No copy-paste commands for the human.** The agent reads the file, the agent applies.
- **Pick the smallest viable set.** Easier to add a stack later than rip one out.
- **Default choices** unless the user pushes back:
  - Web app for end users → `node` + `nextjs`
  - Backend API → `python` + `fastapi`
  - Backend + admin web → `python` + `node` + `fastapi` + `nextjs`
  - Cross-platform mobile → `node` + `mobile-rn`
  - Premium-feel mobile (photo/video) → `mobile-native`
  - Mobile + backend → add `openapi-clients`
  - CLI tool → `go` + `cli-tool` (or `rust` if binary size matters)
  - Desktop app → `node` + `nextjs` + `rust` + `desktop-tauri`
  - AI/ML/data project → `python` only

## Start

Ask me your four phase 1 questions.
