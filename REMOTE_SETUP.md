# Remote-only project bootstrap

How to spin up a new agent-driven project from your phone, then run the agent locally later.

## Prerequisites

- GitHub mobile app installed and logged in
- Access to an AI chat (Claude/ChatGPT/whatever) on your phone
- This base repo (the agent infrastructure pack) on your GitHub as a **template repo**

## One-time setup (do this on a laptop once)

1. Push this base repo to GitHub.
2. GitHub web → Settings → check **Template repository**.
3. Now you can spawn new projects from it on mobile.

## Spinning up a new project (phone-only, ~30 min)

### Step 1 — Create the repo from the template

In GitHub mobile app:
1. Go to your base repo
2. Tap "Use this template" → "Create a new repository"
3. Name it, set private, create.

### Step 2 — Open an AI chat

Paste the contents of `BOOTSTRAP_PROMPT.md` (in this repo) as your first message.

Then describe the project you want to build in plain English. The AI will ask you focused questions and produce 5 files for you to commit.

### Step 3 — Commit the 5 files

For each file the AI produces:

1. In GitHub mobile, navigate to the file path
2. Tap the file (creates new if doesn't exist)
3. Tap edit (pencil icon)
4. Paste content
5. Commit with the suggested message

Files to commit (in order):
1. `CLAUDE.md` (replace existing template)
2. `docs/product.md` (replace template)
3. `docs/architecture.md` (replace template)
4. `docs/phases.md` (replace template)
5. `docs/decisions/0001-<slug>.md` (new file)

### Step 4 — Set up labels and seed issues

In GitHub mobile app:

**Labels** — go to repo → Labels tab → Create:
- `ready-for-agent` (green)
- `agent-produced` (blue)
- `agent-please-fix` (red)
- `agent-proposed` (purple)
- `needs-decision` (red)
- `in-progress` (blue)
- `human-takeover` (black)
- `tracking` (yellow)
- `roadmap` (yellow)
- `priority:high` (red)
- `priority:med` (yellow)
- `priority:low` (light green)

**Issues** — paste the starter issues the AI gave you. For each:
1. Issues tab → New issue
2. Title, body, labels (`ready-for-agent` + a priority label)
3. Submit

### Step 5 — When you get to a laptop, run the agent

```bash
git clone <your-new-repo>
cd <your-new-repo>
cp .env.example .env   # if your project needs one
make build
make agent-start
```

Walk away.

## What stays generic vs gets customised

**Generic — don't touch in the bootstrap chat:**
- `Makefile`
- `docker/Dockerfile.dev`
- `docker/docker-compose.yml`
- `scripts/launch-agent.sh`
- `.claude/commands/*`
- `docs/unattended-rules.md`
- `.github/workflows/ci.yml.optional` (disabled by default — opt in only after reading `.github/workflows/README.md`; agent runs `make ci` locally instead)
- `.github/ISSUE_TEMPLATE/agent-ready.md`
- `.github/pull_request_template.md`

**Project-specific — fill in via the bootstrap chat:**
- `CLAUDE.md`
- `docs/product.md`
- `docs/architecture.md`
- `docs/phases.md`
- `docs/decisions/0001-*.md` (and onwards)
- Initial GitHub issues

## Phone-only workflow after the agent is running

Even with the agent running locally on your laptop and you out, you can still:

- **Add work to the queue** — file new issues with `ready-for-agent` label
- **Redirect mid-PR** — add `agent-please-fix` label + comment `@agent <instruction>`
- **Resolve blocked decisions** — comment + flip `needs-decision` → `ready-for-agent`
- **Take over a PR** — add `human-takeover` label
- **Review progress** — read `logs/progress.md` directly in GitHub mobile

The agent picks up everything on its next 10-minute cycle.

## Tips

- **Bootstrap chat tends to over-scope.** When the AI proposes 12 phases, push back: "compress to 5, what's MVP."
- **First ADR matters most.** It locks in the central abstraction. Get it right or you'll be rewriting in two weeks.
- **Keep the issue queue short at first** — 5-8 well-specified issues is enough to start. Over-loading the queue with vague tasks wastes agent cycles.
- **Don't commit secrets via mobile.** `.env` is gitignored; fill it in on the laptop only.
- **If you forget something** — the agent's self-audit will catch most omissions and file `agent-proposed` issues. You're not locked in.
