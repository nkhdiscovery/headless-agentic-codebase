#!/usr/bin/env bash
# scripts/launch-agent.sh
#
# Runtime-agnostic agent launcher. Reads agent.config to decide which
# runtime adapter to use (Claude / Gemini / Codex / custom).

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# Project-scoped compose name so multiple repos can run agents in parallel
# without colliding on container/image/network names.
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-$(basename "$REPO_ROOT")}"
COMPOSE="docker compose -f docker/docker-compose.yml -p $COMPOSE_PROJECT_NAME"

# --- Load config -----------------------------------------------------------

if [ -f agent.config ]; then
    # shellcheck disable=SC1091
    source agent.config
else
    echo "ERROR: agent.config not found in $REPO_ROOT"
    exit 1
fi

ADAPTER="agents/${AGENT_RUNTIME}.sh"
if [ ! -f "$ADAPTER" ]; then
    echo "ERROR: no adapter for AGENT_RUNTIME=$AGENT_RUNTIME"
    echo "Available: $(ls agents/*.sh 2>/dev/null | xargs -n1 basename | sed 's/\.sh$//' | tr '\n' ' ')"
    exit 1
fi

# --- Safety checks ---------------------------------------------------------

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    echo "ERROR: you are on branch '$CURRENT_BRANCH', not main."
    echo "Switch to main: git checkout main"
    exit 1
fi

if ! git diff --quiet HEAD; then
    echo "ERROR: uncommitted changes. Commit or stash first:"
    git status --short
    exit 1
fi

# --- Place the unattended marker ------------------------------------------

mkdir -p .claude logs/daily
touch .claude/unattended

# --- Boot the agent container ---------------------------------------------

echo "Starting agent container (project: $COMPOSE_PROJECT_NAME)..."
$COMPOSE up -d agent
sleep 2

LOG_FILE="logs/daily/$(date +%Y-%m-%d).md"
{
    echo ""
    echo "## Session $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    echo "- Runtime: $AGENT_RUNTIME"
    echo "- Model: ${AGENT_MODEL:-default}"
    echo ""
} >> "$LOG_FILE"

# --- Run the loop inside the container ------------------------------------

echo "Launching agent (runtime: $AGENT_RUNTIME, model: ${AGENT_MODEL:-default})"
echo "Live log: tail -f $LOG_FILE"
echo "Stop anytime: make agent-stop"
echo ""

$COMPOSE exec -T agent bash -lc "
    set -euo pipefail
    cd /workspace
    source agent.config
    source agents/\${AGENT_RUNTIME}.sh

    check_agent_installed
    check_agent_authed

    has_work() {
        # Returns 0 if there's ready-for-agent work or PRs needing fixes.
        local ready_count fix_count
        ready_count=\$(gh issue list --label ready-for-agent --state open --json number 2>/dev/null | jq 'length' || echo 0)
        fix_count=\$(gh pr list --label agent-please-fix --state open --json number 2>/dev/null | jq 'length' || echo 0)
        [ \"\$ready_count\" -gt 0 ] || [ \"\$fix_count\" -gt 0 ]
    }

    while true; do
        git checkout main && git pull --rebase 2>&1 | tail -3 || true
        run_agent_cycle || echo '[launcher] cycle returned non-zero, continuing loop'

        if has_work; then
            echo \"[launcher] cycle complete — work pending, starting next cycle immediately\"
        else
            echo \"[launcher] cycle complete — queue empty, sleeping \${AGENT_IDLE_SLEEP}s\"
            sleep \"\${AGENT_IDLE_SLEEP}\"
        fi
    done
" 2>&1 | tee -a "$LOG_FILE"

# --- Post-session cleanup --------------------------------------------------

echo "" >> "$LOG_FILE"
echo "Session ended: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$LOG_FILE"

rm -f .claude/unattended
$COMPOSE stop agent

echo "Agent stopped. See $LOG_FILE."
