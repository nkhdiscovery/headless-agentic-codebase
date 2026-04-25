# Getting started

The complete workflow from "I have an idea" to "agent is shipping code 24/7", in order. Follow the steps.

This walkthrough should take **45–90 minutes** the first time. Most of that is the bootstrap chat in step 2 and the supervised trial in step 6. After your first project, subsequent projects take 30 minutes.

You can do steps 1–5 entirely from your phone. Steps 6–7 need a Linux/macOS laptop with Docker.

---

## Step 1 — Create your project repo from the template

**Where:** GitHub mobile app or web.

**What:** Make a new private repo from this template.

```
GitHub → this template repo → "Use this template" → "Create new repository"
```

Name it whatever your project is. Set private (you can flip to public later).

**Why:** The template ships the agent infrastructure, slash commands, governance docs, Docker setup, and CI. You're going to fill in the project-specific files in step 2.

---

## Step 2 — Generate the project-specific files via an AI chat

**Where:** Claude.ai (or any AI chat that can hold context).

**What:** Paste the contents of [`BOOTSTRAP_PROMPT.md`](./BOOTSTRAP_PROMPT.md) as your first message. Then describe your project in plain English. The AI asks focused questions and produces 5 files.

**The 5 files you get back:**

| File | What it is |
|---|---|
| `CLAUDE.md` | The agent's always-loaded context — invariants, conventions, hard limits |
| `docs/product.md` | Product vision, target users, business model, open decisions, out-of-scope |
| `docs/architecture.md` | Stack choice, central abstractions, data flow, security model |
| `docs/phases.md` | 4–6 build phases with "done when" criteria |
| `docs/decisions/0001-<slug>.md` | First ADR — usually about the central architectural abstraction |

Plus 5–8 starter GitHub issues, ready to paste.

**Tip:** When the AI proposes 12 phases, push back: *"compress to 5, what's the MVP?"* Bootstrap chats over-scope.

---

## Step 3 — Commit the 5 files to your repo

**Where:** GitHub mobile app's edit view, or your laptop.

**What:** For each file the AI produced:
1. Navigate to the file path in your new repo (creates the file if it doesn't exist)
2. Tap edit, paste the content, commit

Each file replaces a template stub or creates a new ADR. Use the commit message the AI suggested.

---

## Step 4 — Pick and apply your stacks and addons (AI-assisted)

**Where:** AI chat (Claude.ai or similar). Then your laptop for the apply commands.

**What:** This step requires picking the right language toolchain and feature scaffolds, plus some Docker/Makefile/CI plumbing. Rather than learn it all yourself, paste [`STACK_PICKER_PROMPT.md`](./STACK_PICKER_PROMPT.md) into an AI chat and let it walk you through.

The prompt will:

1. **Phase 1 — Pick (5 min):** Ask 4 quick questions about your project, then propose a stack + addon set with one-line justifications. You confirm or push back.
2. **Phase 2 — Apply (15 min):** Give you copy-paste commands for each step (append Dockerfile snippets, replace Makefile targets, copy scaffold files, update CI). One step at a time, with verification commands. If something fails, debug interactively.
3. **Phase 3 — Cheat sheet:** Daily commands, where to put new code, first three `ready-for-agent` issues to file.

If you'd rather pick manually, [`STACKS_AND_ADDONS.md`](./STACKS_AND_ADDONS.md) has the catalogue and common combinations.

**Common combinations** (picker will recommend something close to one of these):

| Project type | Stacks + addons |
|---|---|
| Backend + admin web | `python` + `node` + `fastapi` + `nextjs` |
| Mobile-first SaaS | `python` + `node` + `fastapi` + `mobile-rn` + `openapi-clients` |
| Premium photo/video app | `python` + `fastapi` + `mobile-native` + `desktop-tauri` |
| CLI tool | `go` + `cli-tool` |
| AI/ML project | `python` only |

This step needs a laptop with Docker. Not designed for phone.

---

## Step 5 — Create labels and seed the issue queue

**Where:** GitHub mobile app or `gh` CLI on laptop.

**What:**

```bash
# Labels (the agent uses these to know what to work on)
for l in "ready-for-agent:0e8a16" "agent-produced:1f77b4" "agent-please-fix:d93f0b" \
         "agent-proposed:5319e7" "needs-decision:d93f0b" "in-progress:0075ca" \
         "blocked:b60205" "human-only:000000" "human-takeover:000000" \
         "tracking:fef2c0" "roadmap:fef2c0" "docs-exempt:c5def5" \
         "priority:high:b60205" "priority:med:fbca04" "priority:low:c2e0c6"; do
  gh label create "${l%:*}" --color "${l##*:}" --force
done
```

Then file the 5–8 starter issues from step 2. Each gets `ready-for-agent` + a `priority:*` label.

**Set spending limit to $0** in GitHub Settings → Billing → Spending limits → Actions, so CI minutes can never bill you.

---

## Step 6 — Build the dev container and supervised trial

**Where:** Your laptop. Requires Docker, GitHub CLI authenticated, an agent CLI installed and authenticated (Claude Code / Gemini CLI / Codex CLI).

**What:**

```bash
git clone <your-new-repo>
cd <your-new-repo>

# Set the agent runtime if not Claude (the default)
# Edit agent.config or:
# AGENT_RUNTIME=gemini

make build              # build the dev container
make ci                 # smoke test — should pass on a fresh template

# Supervised trial — watch the first cycle
make agent-start
```

In another terminal:
```bash
tail -f logs/daily/$(date +%Y-%m-%d).md
```

Watch one full cycle: agent picks an issue → branches → plans → tests → implements → CI green → self-merges. If the merged PR looks reasonable:

```bash
make agent-stop
```

If it looks wrong, close the PR with a comment, tighten the issue's acceptance criteria, fix anything obviously broken in the docs, then trial again.

---

## Step 7 — Run for real and walk away

```bash
git checkout main && git pull
make agent-start
```

Close the laptop. The agent loops every 10 minutes, picking up new work and addressing PR feedback. It runs 24/7 until you `make agent-stop`.

While you're away, from your phone:

| You want to | You do |
|---|---|
| Add new work | File issue → label `ready-for-agent` + priority |
| Redirect on a PR | Comment `@agent <fix>` + label `agent-please-fix` |
| Resolve a blocker | Comment your decision → label `needs-decision` → `ready-for-agent` |
| Take over a PR | Add `human-takeover` label |
| See what's happening | Open `logs/progress.md` in GitHub mobile |
| See what's in flight | Filter issues by `in-progress` label |

The agent reads GitHub fresh every cycle, so anything you change reaches it within 10 minutes.

---

## Where things live (for when you need to find them)

| Doc | Read it when |
|---|---|
| [`README.md`](./README.md) | You want a project overview + daily workflow reference |
| `GETTING_STARTED.md` (this) | You're starting a new project — follow it linearly |
| [`BOOTSTRAP_PROMPT.md`](./BOOTSTRAP_PROMPT.md) | Step 2 — paste into an AI chat to generate project files |
| [`STACK_PICKER_PROMPT.md`](./STACK_PICKER_PROMPT.md) | Step 4 — paste into an AI chat to pick + apply stacks and addons |
| [`REMOTE_SETUP.md`](./REMOTE_SETUP.md) | You want the phone-only flow with no laptop |
| [`STACKS_AND_ADDONS.md`](./STACKS_AND_ADDONS.md) | Step 4 — manual reference if not using the picker prompt |
| [`docs/unattended-rules.md`](./docs/unattended-rules.md) | The agent's binding rulebook — don't edit casually |
| [`SECURITY.md`](./SECURITY.md) | Vulnerability disclosure policy template |

---

## When something goes wrong

**Agent opened a terrible PR**
Close it, comment why, remove `ready-for-agent` from the issue. Agent will skip it.

**Agent keeps tripping the same stop condition**
The issue is under-specified. Rewrite the acceptance criteria to be unambiguous.

**CI keeps failing on agent PRs**
Check if main has drifted. Rebase the branch, or fix the underlying issue in main first.

**Agent doesn't pick up your `@agent` comment**
The label `agent-please-fix` isn't applied, or the agent stopped. Check `docker ps | grep agent` — if it's not running, `make agent-start` again.

**Agent stops with "queue empty"**
Add more `ready-for-agent` issues. The 24/7 loop will pick them up automatically; no need to restart.

**You stopped the agent mid-task**
It left an orphan branch. `git branch -D agent/<n>-<slug>` locally. The agent ignores stale branches without an open PR.

---

## What to do next

1. Run your first project all the way through to step 7
2. After a few days, run the `/brief-refresh` slash command and review the audit it produces
3. Read `logs/progress.md` weekly to see what shipped
4. When patterns emerge in your PR feedback, update `CLAUDE.md` so the agent learns once instead of being corrected every PR

Good luck.
