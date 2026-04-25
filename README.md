# Agent Project Pack

**A drop-in template for running an autonomous coding agent (Claude Code, Gemini CLI, Codex, etc.) 24/7 on your project.**

> **New here? Start with [`GETTING_STARTED.md`](./GETTING_STARTED.md)** — a linear walkthrough from "I have an idea" to "agent is shipping code 24/7." Takes 45–90 minutes the first time.
>
> This README is the project overview and daily workflow reference. Follow `GETTING_STARTED.md` first.

You scope the project, file issues, walk away. The agent branches, plans, writes tests, implements, opens PRs, and self-merges on green CI. You review asynchronously through GitHub — even from your phone — and steer with `@agent` PR comments.

This repo is the infrastructure that makes that work safely: **runtime-agnostic** orchestration (Claude, Gemini, Codex), **language-agnostic** core, container isolation, governance docs, slash commands, GitHub workflow conventions, and a 24/7 launcher loop. **Pick a language stack and feature addons** (FastAPI, Next.js, mobile, desktop, CLI) only when you need them — the core is the same regardless.

---

## Why this exists

Running an LLM agent against your codebase is easy. Running one *unsupervised for hours* without it making a mess is the hard part. The usual failure modes:

- Agent goes off on tangents, scope-creeps PRs into unreviewable diffs
- No clear handoff when you want to redirect it mid-task
- Loses context between sessions, re-litigates settled decisions
- No record of what got built or why
- Pushes broken code, force-pushes, deletes history, runs `rm -rf`
- You can't tell from your phone whether things are going well

This template fixes all of that with three layers of governance:

1. **Always-loaded instructions** (`CLAUDE.md`) the agent reads every session
2. **Binding rules for autonomous mode** (`docs/unattended-rules.md`) covering the work loop, hard limits, and self-audit behaviour
3. **Physical guardrails** — Docker container isolation, Makefile-only command surface, CI gate, async GitHub-mediated communication

Plus the conventions that make it actually pleasant: ADRs for architectural decisions, a plain-English progress log, in-progress labels, a per-module documentation system enforced by CI (`docs/codebase/`), security governance scaffolding (SECURITY.md, CODEOWNERS, threat model), and a `BOOTSTRAP_PROMPT.md` you can paste into any AI chat to scaffold a new project from your phone.

---

## What you get

```
.
├── CLAUDE.md                    # Always-loaded agent context (template)
├── GETTING_STARTED.md           # ⭐ START HERE — linear walkthrough
├── BOOTSTRAP_PROMPT.md          # Paste into AI chat to scaffold a new project
├── REMOTE_SETUP.md              # Phone-only workflow guide
├── STACKS_AND_ADDONS.md         # Catalogue of optional language stacks + feature addons
├── SECURITY.md                  # Vulnerability disclosure policy template
├── Makefile                     # The only command surface (customise per stack)
├── agent.config                 # Runtime + model selection
├── agents/                      # Per-runtime adapters (claude, gemini, codex, custom)
├── docker/                      # Minimal language-agnostic dev container
├── scripts/
│   ├── launch-agent.sh          # The 24/7 launcher loop (runtime-agnostic)
│   └── docs-gate.sh             # CI gate enforcing docs/codebase/ updates per module
├── stacks/                      # OPTIONAL: language toolchains, pick one or more
│   ├── python/
│   ├── node/
│   ├── go/
│   └── rust/
├── addons/                      # OPTIONAL: feature scaffolds, drop in as needed
│   ├── fastapi/                 # Production backend
│   ├── nextjs/                  # Web app
│   ├── mobile-rn/               # React Native cross-platform
│   ├── mobile-native/           # SwiftUI + Kotlin/Compose
│   ├── desktop-tauri/           # Native desktop wrapper
│   ├── cli-tool/                # CLI argument parsing + distribution
│   └── openapi-clients/         # Auto-gen mobile/web clients from API spec
├── .claude/commands/            # Slash commands the agent uses
│   ├── review-prs.md
│   ├── next-issue.md
│   ├── add-adr.md
│   ├── daily-log.md
│   ├── brief-refresh.md
│   ├── phase-status.md
│   └── new-module.md
├── docs/
│   ├── product.md               # Product vision (template)
│   ├── architecture.md          # Technical architecture (template)
│   ├── phases.md                # Build phases (template)
│   ├── unattended-rules.md      # The binding rulebook (runtime-agnostic)
│   ├── codebase.md              # Per-module documentation index
│   ├── codebase/template.md     # Seven-section module doc template
│   ├── decisions/               # ADRs go here
│   └── security/                # Threat model, incident response, supply chain
├── logs/
│   ├── progress.md              # Plain-English changelog (agent maintains)
│   └── daily/                   # Per-session detailed logs
├── plans/                       # Per-deliverable plans (ephemeral)
└── .github/
    ├── CODEOWNERS               # Security-sensitive paths
    ├── workflows/ci.yml         # CI with docs-gate job
    ├── ISSUE_TEMPLATE/
    └── pull_request_template.md
```

---

## Quick start

### Prerequisites

- A Linux/macOS host with Docker and Docker Compose
- [GitHub CLI](https://cli.github.com/) authenticated (`gh auth login`)
- One of the supported agent CLIs installed and authenticated:
  - **Claude Code** — `npm i -g @anthropic-ai/claude-code` then `claude login` (Pro/Max/API)
  - **Gemini CLI** — `npm i -g @google/gemini-cli` then `gemini auth` (free tier available)
  - **Codex CLI** — `npm i -g @openai/codex` then `codex login` (ChatGPT Plus/Pro/API)
  - Or wire your own via `agents/custom.sh`

### Setup

```bash
# 1. Use this template (or clone)
gh repo create my-project --template <user>/agent-project-pack --private --clone
cd my-project

# 2. Personalise the templates
#    Replace {{PROJECT_NAME}} placeholders in CLAUDE.md
#    Fill in docs/product.md, docs/architecture.md, docs/phases.md
#    (or use BOOTSTRAP_PROMPT.md with any AI chat to do this from your phone)

# 3. Create the agent's labels
for l in "ready-for-agent:0e8a16" "agent-produced:1f77b4" "agent-please-fix:d93f0b" \
         "agent-proposed:5319e7" "needs-decision:d93f0b" "in-progress:0075ca" \
         "blocked:b60205" "human-only:000000" "human-takeover:000000" \
         "tracking:fef2c0" "roadmap:fef2c0" \
         "priority:high:b60205" "priority:med:fbca04" "priority:low:c2e0c6"; do
  gh label create "${l%:*}" --color "${l##*:}" --force
done

# 4. Customise Makefile test/lint targets for your stack
#    (Python: ruff/mypy/pytest; Node: eslint/tsc/jest; Go: vet/test; Rust: clippy/test)

# 5. Build the dev container
make build && make ci

# 6. Seed 5 ready-for-agent issues with clear acceptance criteria

# 7. Launch
make agent-start
```

The agent runs until you `make agent-stop`. Walk away.

---

## Knowing what the agent is doing

Three layers of visibility, all readable from the GitHub mobile app:

**1. `logs/progress.md` — plain-English changelog**

The agent appends a human-readable entry here every time it ships something. No jargon, no file paths — written for a non-technical reader. Example:

```markdown
## 2026-04-25 — Photos now get a quality score automatically
**What it does:** When a photo is imported, Frame scores how sharp and well-exposed it is.
**How:** Analyses pixel data mathematically — no AI model needed, runs instantly.
**Why:** Lets users sort by quality and surfaces the keepers automatically.
**Status:** Merged. PR #14.
```

Read it from the GitHub web/mobile UI — it's just a markdown file in the repo.

**2. `in-progress` label — what's happening right now**

When the agent picks up an issue, it adds the `in-progress` label and comments "Starting work. Branch: agent/14-quality-score." `gh issue list --label in-progress` (or filter in the mobile app) shows you exactly what's being worked on at any moment.

**3. `logs/daily/YYYY-MM-DD.md` — detailed session log**

Per-day technical log: every issue picked up, every PR opened, every CI failure. Useful for debugging when something goes wrong or auditing the agent's decisions later.

## Keeping docs honest as code grows

The hardest problem with long-running agent work is **docs drifting from code**. Over weeks the agent ships features faster than its own context can stay accurate; eventually it starts making decisions based on stale assumptions.

This template solves it with a CI gate. Every PR that changes `<source_root>/<module>/**/*.<ext>` must also change `docs/codebase/<module>.md`. The gate runs on every PR; trivial PRs (typo, log string) bypass via the `docs-exempt` label.

Each per-module doc follows a strict seven-section template (What it does / Public API / Data tables / Pipeline steps / Routes / Configuration / Notes), so the agent always knows where to look up a module without re-reading its source. This is the single most impactful piece of this template — without it, agents lose coherence over time.

Customise `scripts/docs-gate.sh` and the `DOCS_GATE_*` env vars in `.github/workflows/ci.yml` for your source layout.

## Daily workflow

```bash
# Day one — start the agent and walk away. It runs continuously.
git checkout main && git pull
make agent-start

# Anytime — check what's happening (works from phone via GitHub mobile app)
cat logs/progress.md            # Plain-English: features shipped, in plain language
gh pr list --state merged       # PRs the agent has shipped
gh issue list --label in-progress  # What it's currently working on
make agent-logs                 # Live tail of today's session

# Steer the agent (works from phone)
# - File issue with `ready-for-agent` label = new task queued
# - Comment "@agent <fix>" + add `agent-please-fix` label = redirect on a PR
# - Add `human-takeover` label = "I'll take this one"

# When you actually want to stop (not at end of day — only when needed)
make agent-stop
```

The agent is designed to run continuously. Leave it going overnight, weekends, while you travel. It loops every 10 minutes; if the queue is empty it runs a self-audit, proposes new features, and waits. You only stop it when:

- You want to update its core docs (`CLAUDE.md`, `unattended-rules.md`)
- You're rebooting the host
- Something has gone wrong and you want to investigate

---

## How it works

### The work loop

Every 10 minutes the agent runs one cycle:

1. Address any open PR with `@agent` comments or `agent-please-fix` label
2. Pick the highest-priority `ready-for-agent` issue
3. Mark it `in-progress`, branch, write a plan
4. Tests first, then implementation
5. Run `make ci` until green
6. Self-merge with squash + delete branch
7. Update `logs/progress.md`
8. Loop

Empty queue triggers a `/brief-refresh` self-audit — agent scans docs and code, files `agent-proposed` issues with feature ideas and refactoring opportunities, then waits 10 min before the next cycle.

### Hard limits

The agent can self-merge, refactor, propose features, and challenge architectural decisions via new ADRs. It cannot:

- Push directly to `main`
- Force-push or rewrite history
- Read paths matching personal data patterns (configurable per project)
- `rm -rf` outside `plans/` and `logs/`
- Commit binary user data
- Touch PRs labelled `human-takeover`

CI is the gate that protects everything else — failing tests block self-merge.

### Steering from anywhere

The agent reads GitHub fresh every cycle, so anything you do via the GitHub web UI or mobile app reaches it within 10 minutes:

| You want to | You do |
|---|---|
| Queue new work | File issue, label `ready-for-agent` + a priority |
| Fix something on a PR | Comment `@agent <instruction>`, label `agent-please-fix` |
| Resolve a blocked decision | Comment your answer, swap `needs-decision` → `ready-for-agent` |
| Take over a PR | Add `human-takeover` label |
| Pause everything | `make agent-stop` |

---

## Phone-only project bootstrapping

The unique twist: you can scaffold a new project entirely from your phone.

1. On phone, GitHub mobile app → "Use this template" → create new repo
2. Open any AI chat (Claude, ChatGPT, etc.)
3. Paste `BOOTSTRAP_PROMPT.md` content
4. Describe your project in plain English; AI asks focused questions
5. AI produces 5 files (`CLAUDE.md`, `docs/product.md`, `docs/architecture.md`, `docs/phases.md`, `docs/decisions/0001-*.md`) plus 5-8 starter issues
6. Commit each via GitHub mobile's edit view, paste the issues
7. Later on a laptop: `make build && make agent-start`

See [`REMOTE_SETUP.md`](./REMOTE_SETUP.md) for the full walkthrough.

---

## Configuration

### Running multiple projects in parallel on one machine

The Makefile and launcher derive a unique compose project name from the repo directory, so you can run multiple agents on the same host without collisions:

```bash
~/code/project-a $ make agent-start    # container: project-a-agent-1
~/code/project-b $ make agent-start    # container: project-b-agent-1
```

Each gets its own image (`project-a-dev:latest`, `project-b-dev:latest`), container, network, and volumes. They share your host's `~/.claude` and `~/.config/gh` for auth — that's intentional and fine.

If you also expose HTTP daemons (the optional `daemon` compose profile), set a different host port per project in each `.env`:

```bash
# project-a/.env
DAEMON_PORT=8765

# project-b/.env
DAEMON_PORT=8766
```

Override the project name explicitly with `PROJECT_NAME=foo make agent-start` if your directory names happen to clash.

### Choosing the agent runtime

Edit `agent.config` (or set env vars):

```bash
AGENT_RUNTIME=claude    # claude | gemini | codex | junie | custom
AGENT_MODEL=default     # see agents/<runtime>.sh for valid values
AGENT_IDLE_SLEEP=600    # seconds between cycles when queue is empty
```

Each runtime has an adapter in `agents/<name>.sh` that handles model selection, CLI flags, and auth checks. The launcher loop is identical regardless of which runtime runs — same prompt, same governance docs, same workflow.

**Switching runtimes is one config change:** `AGENT_RUNTIME=gemini make agent-start`. The Docker image has all CLIs preinstalled (configurable via `INSTALL_AGENTS` build arg if you want a leaner image).

### Model recommendations

| Runtime | Best model | Cheap+fast |
|---|---|---|
| Claude Code | `claude-opus-4-7` (default) | `claude-sonnet-4-6` |
| Gemini CLI | `gemini-2.5-pro` | `gemini-2.5-flash` |
| Codex CLI | `gpt-5-codex` | `gpt-5` |

Override per-launch:
```bash
AGENT_MODEL=sonnet make agent-start          # Claude with Sonnet
AGENT_RUNTIME=gemini AGENT_MODEL=flash make agent-start
```

### Adding a new runtime

1. Copy `agents/custom.sh` to `agents/<your-runtime>.sh`
2. Implement `run_agent_cycle`, `check_agent_installed`, `check_agent_authed`
3. Add CLI install to `docker/Dockerfile.dev` if needed
4. Set `AGENT_RUNTIME=<your-runtime>` in `agent.config`

The contract is small — see `agents/claude.sh` as the reference implementation.

### Adapting to your stack

The core of this template is **language-agnostic** — the launcher, governance docs, slash commands, docs-gate, security suite, and 24/7 loop all work regardless of what language your project uses.

Language toolchains and feature scaffolds are **optional add-ons** in two directories:

- `stacks/` — language toolchains (Python, Node, Go, Rust). Pick one or more.
- `addons/` — feature scaffolds (FastAPI backend, Next.js web, React Native mobile, Tauri desktop, OpenAPI clients, CLI tools). Drop in only what you need.

See [`STACKS_AND_ADDONS.md`](./STACKS_AND_ADDONS.md) for the full catalogue and apply instructions.

Common combinations:

| Project type | Pick |
|---|---|
| Backend + admin UI | `python` + `node` + `fastapi` + `nextjs` |
| Mobile-first SaaS | `python` + `node` + `fastapi` + `mobile-rn` + `openapi-clients` |
| CLI tool | `go` (or `rust`) + `cli-tool` |
| Photo/video app (premium feel) | `python` + `fastapi` + `mobile-native` + `desktop-tauri` + `openapi-clients` |
| Static-typed web service | `rust` only |

You're not locked in — add an addon later when you need it. Remove one by deleting the directory and reverting its CLAUDE.md block.

The four files customised per project regardless of stack:
- `docker/Dockerfile.dev` — language toolchain
- `Makefile` — `test`, `lint`, `format` commands
- `.github/workflows/ci.yml` — CI matching your Makefile
- `pyproject.toml` / `package.json` / equivalent — project manifest

Everything else (slash commands, governance docs, launcher) stays as-is.

---

## What this is *not*

- **Not an AI orchestration framework.** This is configuration + conventions, not code. There's no daemon, no scheduler beyond a bash `while`/`sleep` loop. You can read every file in 30 minutes.
- **Not a Claude wrapper.** It uses the official Claude Code CLI in non-interactive mode. Switching to a different agent runner is a one-file change.
- **Not for production deployment of agents.** This runs *one* agent against *one* repo on *your* machine. It's a developer tool, not a multi-tenant platform.
- **Not magic.** If your acceptance criteria are vague, the agent's PRs will be vague. Garbage in, garbage out applies.

---

## Safety: private vs public project repos

The agent only acts on issues labelled `ready-for-agent`. In a **private repo**, only you can apply that label, so you're safe by default.

In a **public repo**, anyone can open issues. The label is still your gate, but you need a workflow that auto-strips `ready-for-agent` and `agent-please-fix` from any contribution that isn't yours, otherwise external contributors could queue work directly. See [`GETTING_STARTED.md`](./GETTING_STARTED.md#going-public-with-a-project-repo-safety) for the workflow YAML and the full checklist (don't store production secrets in the agent container, monitor logs in week one, etc.).

The template repo itself (this one) is fine to keep public — there's no agent loop running on it; it's just files.

## Cost controls

The agent runs on your subscription or API quota. Three built-in layers protect you from runaway costs:

- **Daily cost cap** — `AGENT_MAX_DAILY_USD=5` in `agent.config`. Launcher pauses for an hour when reached.
- **Daily PR cap** — `AGENT_MAX_PRS_PER_DAY=20` for runaway loops.
- **Per-PR cost comments** — every merged PR gets `Cost: $0.42 (approx)` posted automatically.

Plus `make agent-cost` shows today's spend at a glance. See [`GETTING_STARTED.md`](./GETTING_STARTED.md#cost-controls-optional-but-recommended) for recommended values per subscription type and how to inspect spend.

The agent also can't auto-merge changes to its own controls (Makefile, launcher, agent.config, unattended-rules.md, workflows). It labels those PRs `human-only-merge` and leaves them for you to review.

---

## Keeping projects in sync with the template

Template gets infrastructure updates over time. From any project repo created from it:

```bash
make sync-template
```

Safe files overwrite cleanly. Files with project-specific customisation (Makefile, agent.config, etc.) get a 3-way merge — clean merges land directly, conflicts surface with standard `<<<<<<<` markers for manual resolution. Project-only files (CLAUDE.md, README.md, docs/product.md) are never touched. See [`GETTING_STARTED.md`](./GETTING_STARTED.md#keeping-in-sync-with-template-updates) for details.

---

## Comparison

| | This template | Devin / similar SaaS | Plain agent CLI |
|---|---|---|---|
| Runs locally | Yes | No | Yes |
| Self-hosted, your data | Yes | No | Yes |
| 24/7 unattended | Yes | Yes | No (manual) |
| Container isolation | Yes | Yes | No by default |
| Phone-driven steering | Yes (via GitHub) | Limited | No |
| Self-audit + feature proposals | Yes | Varies | No |
| Customisable rules | Yes (just markdown) | No | Manually each session |
| **Swap underlying model/agent** | **Yes — config change** | No | No |
| Cost | Your subscription | $$$ subscription | Your subscription |
| Lock-in | None | High | Tied to one vendor |

---

## Roadmap

This is a personal template I use myself, but I'll merge useful PRs. Things that would help:

- Pre-built `Dockerfile.dev` variants for common stacks (Rust, Go, Elixir)
- A second launcher mode that wakes only on GitHub webhook (cheaper than the 10-min loop)
- A `make doctor` that diagnoses common setup issues
- Translations of `unattended-rules.md` if non-English-language agents become useful

---

## Contributing

PRs welcome. Keep additions minimal and generic — anything project-specific belongs in your fork, not here.

Hard rule: don't add anything that requires a paid third-party service to use the template. The point is something you can run with just Docker, GitHub, and a Claude subscription.

---

## License

MIT. See [`LICENSE`](./LICENSE).

---

## Credits

Built while using Claude Code to build something else, then extracted as a template once it became clear the *workflow itself* was the more valuable artefact. The unattended rules and slash commands are the result of repeated iteration against a real project — not theoretical.

If you build something interesting with this, open an issue and tell me. I want to know what works and what doesn't.
