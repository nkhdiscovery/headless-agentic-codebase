#!/usr/bin/env bash
# agents/codex.sh — OpenAI Codex CLI runtime adapter.
#
# Uses the OpenAI Codex CLI: https://github.com/openai/codex
# Install: npm install -g @openai/codex
# Auth: codex login (ChatGPT account) or set OPENAI_API_KEY.

set -euo pipefail

codex_model() {
    case "${AGENT_MODEL:-default}" in
        default|codex) echo "gpt-5-codex" ;;
        gpt-5)         echo "gpt-5" ;;
        *)             echo "$AGENT_MODEL" ;;
    esac
}

run_agent_cycle() {
    local model
    model="$(codex_model)"
    echo "[codex] cycle starting with model: $model"

    # Codex CLI's non-interactive flag is `exec`, with --full-auto for unattended.
    codex exec \
        --model "$model" \
        --full-auto \
        "$AGENT_PROMPT"
}

check_agent_installed() {
    command -v codex >/dev/null 2>&1 || {
        echo "ERROR: codex CLI not found. Install: npm install -g @openai/codex"
        return 1
    }
}

check_agent_authed() {
    if [ -z "${OPENAI_API_KEY:-}" ] && [ ! -f "$HOME/.codex/auth.json" ]; then
        echo "ERROR: Codex not authed. Run: codex login   (or set OPENAI_API_KEY)"
        return 1
    fi
}
