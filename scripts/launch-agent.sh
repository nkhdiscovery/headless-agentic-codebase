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

# --- Cleanup runs on any exit (success, error, or signal) -----------------
# Without this, `set -euo pipefail` tripping anywhere below — most easily on
# a SIGPIPE in the stream-json | jq | tee pipeline — would skip cleanup,
# leaving .claude/unattended in place and the agent container running.
cleanup() {
    local rc=$?
    echo "" >> "${LOG_FILE:-/dev/null}" 2>/dev/null || true
    echo "Session ended: $(date -u +%Y-%m-%dT%H:%M:%SZ) (exit=$rc)" >> "${LOG_FILE:-/dev/null}" 2>/dev/null || true
    rm -f .claude/unattended
    $COMPOSE stop agent >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

# --- Boot the agent container ---------------------------------------------

echo "Starting agent container (project: $COMPOSE_PROJECT_NAME)..."
$COMPOSE up -d agent
sleep 2

LOG_FILE="logs/daily/$(date +%Y-%m-%d).md"
RAW_LOG="logs/daily/$(date +%Y-%m-%d).jsonl"
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
echo "Readable log: tail -f $LOG_FILE"
echo "Forensic log (raw stream-json): $RAW_LOG"
echo "Stop anytime: make agent-stop"
echo ""

# Filter stream-json into human-readable lines.
#
# - assistant text   -> "[HH:MM:SS] the line as-is"
# - assistant tool   -> "[HH:MM:SS] → Name(short input)"
# - tool_result      -> "[HH:MM:SS]   result: <truncated>"
# - rate_limit       -> "[HH:MM:SS] [rate limit] <status>"
# - non-JSON lines (launcher messages, git output) pass through verbatim with timestamp
HUMANISE='
  (now | strftime("%Y-%m-%d %H:%M:%S")) as $ts |
  . as $raw |
  (try fromjson catch null) as $j |
  if $j == null then
    "\($ts) \($raw)"
  elif $j.type == "assistant" then
    ($j.message.content[]? |
      if .type == "text" then "\($ts) \(.text)"
      elif .type == "tool_use" then
        "\($ts) → \(.name)(" + ((.input | tostring)[:100]) + ")"
      else empty end)
  elif $j.type == "user" then
    ($j.message.content[]? |
      if .type == "tool_result" then
        "\($ts)   result: " + ((.content | tostring | gsub("\n"; " "))[:200])
      else empty end)
  elif $j.type == "rate_limit_event" then
    "\($ts) [rate limit] " + $j.rate_limit_info.status
  else empty end
'

# The inner loop also writes the raw stream to a file *inside the container*
# (via tee in the loop body — see RAW_LOG_IN_CONTAINER). That way, even if the
# host-side display pipeline (jq | tee) collapses with SIGPIPE, the worker keeps
# running and we still have a forensic record on disk.
RAW_LOG_IN_CONTAINER="/workspace/$RAW_LOG"

# Make the display pipeline non-fatal: if jq dies, fall through to cat so the
# pipeline never breaks. `|| true` on the outer pipe is a final belt-and-suspenders.
set +e
$COMPOSE exec -T agent bash -lc "
    set -uo pipefail
    cd /workspace
    source agent.config
    source agents/\${AGENT_RUNTIME}.sh

    check_agent_installed
    check_agent_authed

    # Helpers below deliberately decouple the gh|jq pipe from the assignment
    # so that a transient gh failure or empty payload can't trip pipefail and
    # silently kill the loop. Defaults are applied with \${var:-0}.
    count_or_zero() {
        # Stdin: JSON array. Stdout: integer length, or 0 on any failure.
        local n
        n=\$(jq 'length' 2>/dev/null) || n=0
        echo \"\${n:-0}\"
    }

    has_work() {
        local ready_count fix_count
        ready_count=\$(gh issue list --label ready-for-agent --state open --json number 2>/dev/null | count_or_zero)
        fix_count=\$(gh pr list --label agent-please-fix --state open --json number 2>/dev/null | count_or_zero)
        ready_count=\${ready_count:-0}
        fix_count=\${fix_count:-0}
        [ \"\$ready_count\" -gt 0 ] || [ \"\$fix_count\" -gt 0 ]
    }

    under_daily_cap() {
        bash scripts/agent-cost.sh under-cap
    }

    under_pr_cap() {
        local cap=\"\${AGENT_MAX_PRS_PER_DAY:-0}\"
        [ \"\$cap\" = \"0\" ] && return 0
        local merged_today
        merged_today=\$(gh pr list --state merged --search \"merged:\$(date +%Y-%m-%d) author:@me\" --json number 2>/dev/null | count_or_zero)
        merged_today=\${merged_today:-0}
        if [ \"\$merged_today\" -ge \"\$cap\" ]; then
            echo \"Daily PR cap reached: \$merged_today merged today >= \$cap\"
            return 1
        fi
        return 0
    }

    while true; do
        # Guard rails — check before starting a cycle.
        if ! under_daily_cap; then
            echo \"[launcher] daily cost cap reached. Sleeping 1h then re-checking.\"
            sleep 3600
            continue
        fi
        if ! under_pr_cap; then
            echo \"[launcher] daily PR merge cap reached. Sleeping 1h then re-checking.\"
            sleep 3600
            continue
        fi

        git checkout main && git pull --rebase 2>&1 | tail -3 || true
        run_agent_cycle || echo '[launcher] cycle returned non-zero, continuing loop'

        if has_work; then
            echo \"[launcher] cycle complete — work pending, starting next cycle immediately\"
        else
            echo \"[launcher] cycle complete — queue empty, sleeping \${AGENT_IDLE_SLEEP}s\"
            sleep \"\${AGENT_IDLE_SLEEP}\"
        fi
    done
" 2>&1 \
    | tee -a "$RAW_LOG" \
    | { jq -Rr --unbuffered "$HUMANISE" 2>/dev/null || cat; } \
    | tee -a "$LOG_FILE" \
    || true
set -e

# --- Post-session cleanup --------------------------------------------------
# Cleanup is handled by the EXIT trap registered above, so it runs even on
# pipefail/SIGPIPE/Ctrl-C. Nothing to do here beyond a friendly final message.

echo "Agent stopped. See $LOG_FILE."
