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

## Step 4 — Decide your stacks and addons (AI writes the decision doc)

**Where:** AI chat. No commands to run.

**What:** Paste [`STACK_PICKER_PROMPT.md`](./STACK_PICKER_PROMPT.md) into an AI chat. It asks 4 questions about your project, proposes a stack + addon set, and on confirm writes one file: `docs/stack.md`.

That's it. You commit `docs/stack.md` to your repo. The agent reads it on its first cycle and applies everything itself — Dockerfile snippets, Makefile targets, scaffold copies, CI config, build, smoke test. You never see the apply commands.

The decision file also includes:
- Daily commands cheat sheet for your picked combination
- First three `ready-for-agent` issues to file (the agent will pick these up after applying the stack)

This step needs no laptop. You can do it entirely from your phone.

**Common combinations** (picker will recommend something close to one of these):

| Project type | Stacks + addons |
|---|---|
| Backend + admin web | `python` + `node` + `fastapi` + `nextjs` |
| Mobile-first SaaS | `python` + `node` + `fastapi` + `mobile-rn` + `openapi-clients` |
| Premium photo/video app | `python` + `fastapi` + `mobile-native` + `desktop-tauri` |
| CLI tool | `go` + `cli-tool` |
| AI/ML project | `python` only |

If you'd rather pick manually without the AI, [`STACKS_AND_ADDONS.md`](./STACKS_AND_ADDONS.md) has the full catalogue. Write your own `docs/stack.md` following the format the prompt would have produced.

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

The agent will replace the generic template README with a project-specific one during its first cycle (alongside applying the stack), so you don't need to write one yourself.

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

make build              # build the dev container (minimal — just the agent CLIs)
make agent-start        # first cycle will apply your docs/stack.md
```

In another terminal:
```bash
tail -f logs/daily/$(date +%Y-%m-%d).md
```

**The first cycle is special.** The agent sees `docs/stack.md`, applies it (Dockerfile snippets, Makefile targets, scaffold files, CI config), runs `make build && make ci` until green, moves the file to `docs/stack-applied.md`, commits, self-merges. This typically takes 5–15 minutes depending on which addons you picked.

**Subsequent cycles** are normal: agent picks the highest-priority `ready-for-agent` issue (the picker prompt seeded 3 of these for you), branches, plans, tests, implements, self-merges.

If the first cycle fails to apply the stack, the agent files an issue with `needs-decision` label and leaves `docs/stack.md` in place for you to fix manually. Most common failure: a stack/addon name in `docs/stack.md` doesn't match what's in the template repo (typo).

When you've watched one full normal cycle complete cleanly:

```bash
make agent-stop
```

If something looks wrong, close the PR with a comment, tighten acceptance criteria, fix anything obvious in the docs, then trial again.

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
