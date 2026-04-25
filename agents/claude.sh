#!/usr/bin/env bash
# agents/claude.sh — Claude Code runtime adapter.
#
# Contract: every agent adapter exports a `run_agent_cycle` function that runs
# one work cycle and exits. The launcher loop calls this in a `while true` loop.

set -euo pipefail

# Map AGENT_MODEL ("default" or specific) to Claude Code's model strings.
claude_model() {
    case "${AGENT_MODEL:-default}" in
        default|opus)   echo "claude-opus-4-7" ;;
        sonnet|fast)    echo "claude-sonnet-4-6" ;;
        haiku|cheapest) echo "claude-haiku-4-5-20251001" ;;
        *)              echo "$AGENT_MODEL" ;;  # pass through if user specified explicit model
    esac
}

run_agent_cycle() {
    local model
    model="$(claude_model)"
    echo "[claude] cycle starting with model: $model"

    claude -p \
        --model "$model" \
        --dangerously-skip-permissions \
        --add-dir /workspace \
        --output-format stream-json \
        --verbose \
        "$AGENT_PROMPT"
}

check_agent_installed() {
    command -v claude >/dev/null 2>&1 || {
        echo "ERROR: claude CLI not found. Install: npm install -g @anthropic-ai/claude-code"
        return 1
    }
}

check_agent_authed() {
    # Claude Code uses ~/.claude.json for auth state.
    if [ ! -f "$HOME/.claude.json" ]; then
        echo "ERROR: Claude not logged in. Run: claude login"
        return 1
    fi
}
