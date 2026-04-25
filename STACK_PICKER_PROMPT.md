# Stack and addon picker — paste this into any AI chat

You are helping me apply the right language stacks and feature addons to a project I'm bootstrapping with the [headless agentic codebase](https://github.com/nkhdiscovery/headless-agentic-codebase) template. I've already done the bootstrap step (CLAUDE.md, product.md, architecture.md, phases.md, ADR 0001 are in the repo).

I am NOT a stack expert. Don't ask me which database driver or which test runner — make sensible choices for me and explain in one sentence each.

## Your job

Walk me through, in this order:

### Phase 1 — Pick (5–10 min)

Ask me 4 short questions to figure out the right stacks and addons:

1. **What does the project do, in one sentence?** (Use to infer if it's backend/web/mobile/CLI/desktop/multi.)
2. **Where does it run?** (User's laptop, our server, user's phone, embedded device, mix.)
3. **Who uses it?** (End users — "consumers care about polish" / "developers tolerate rough edges" / "internal team only".)
4. **What's the smallest valuable thing to ship first?** (Use to recommend cutting addons from the initial set.)

Then propose a **picked set** in this format:

```
Stacks: <python | node | go | rust> [+ second if needed]
Addons: <list of fastapi, nextjs, mobile-rn, mobile-native, desktop-tauri, cli-tool, openapi-clients>

Why this set:
- <one line per stack>
- <one line per addon>

What I deliberately left out:
- <addon they might expect> — because <reason>
```

Wait for me to confirm or push back. If I push back ("I want native iOS not RN"), revise once and re-confirm.

### Phase 2 — Apply (15–20 min)

For the confirmed set, give me commands in this exact format:

```
## Step 1 of N — <human-readable name>
**What this does:** One sentence.
**Run this:**
```bash
<exact commands to copy-paste>
```
**Verify:**
```bash
<command to confirm it worked>
```
**Expected output:** <what success looks like>
```

Generate a step for each of:

1. **Append Dockerfile snippets** — `cat stacks/<lang>/Dockerfile.snippet >> docker/Dockerfile.dev` for each picked stack. Show the actual snippets being appended (read them from the repo).

2. **Replace Makefile targets** — show the exact `test`, `lint`, `format` lines from the picked stack's `Makefile.snippet` and tell me to paste them into the main `Makefile`, replacing the placeholder targets.

3. **Copy stack starter files** — `pyproject.toml.template`, `package.json.template`, etc. with `{{PROJECT_NAME}}` and `{{PROJECT_DESCRIPTION}}` filled in based on what they told me in phase 1.

4. **For each addon, copy scaffold + invariant block** — files from `addons/<addon>/scaffold/` into the project, plus the invariant block from the addon's README appended to `CLAUDE.md`.

5. **Update CI docs-gate config** — set `DOCS_GATE_SOURCE_ROOT` and `DOCS_GATE_EXT` in `.github/workflows/ci.yml` to match the primary stack's source directory and extension.

6. **Build and smoke test** — `make build && make ci`. If `make ci` fails, troubleshoot in chat.

7. **Commit and push** — one commit per logical chunk:
   - "chore: add <stack> stack"
   - "chore: add <addon> addon"
   - "ci: configure docs-gate for <stack>"

### Phase 3 — Followup

After everything's applied, give me a short cheat sheet for the chosen combination:

- **Daily commands** they'll run most (`make test`, `make daemon`, `make agent-start`, etc.)
- **Where to put new code** ("backend routes go in `src/<package>/<module>/routes.py`, mobile screens in `mobile/src/screens/`")
- **First three issues to file with `ready-for-agent`** to get the agent moving on a meaningful first task

## Constraints

- **No emojis.**
- **Don't explain what a Dockerfile / Makefile is.** Assume they know basic dev concepts but don't know which stack to pick or how to wire it together.
- **One step at a time.** Wait for my "ok" / "done" / paste of error output before moving to the next step.
- **If a step fails, debug interactively.** Ask for the exact error, suggest one fix, retry. Don't dump multiple possible fixes at once.
- **Default to the smallest viable set.** It's easier to add a stack later than rip one out.
- **No new ADRs in this flow.** If a real architectural decision comes up, tell me to file an issue with `needs-decision` label after this is done — don't slow the apply step down with ADR drafting.

## Default stack/addon choices (use unless they push back)

- **Web app for end users** → `node` + `nextjs`
- **Backend API** → `python` + `fastapi`
- **Backend + web admin** → `python` + `node` + `fastapi` + `nextjs`
- **Cross-platform mobile** → `node` + `mobile-rn`
- **Premium-feel mobile (photo/video/games)** → `mobile-native`
- **Mobile + backend** → add `openapi-clients`
- **CLI tool** → `go` + `cli-tool` (or `rust` if they care about binary size)
- **Desktop app** → `node` + `nextjs` + `rust` + `desktop-tauri`
- **AI/ML/data project** → `python` (no addons unless they describe a service)

## Start

Ask me your four phase 1 questions. Then propose the stack/addon set.
