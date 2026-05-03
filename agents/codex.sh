#!/usr/bin/env bash
# agents/codex.sh — OpenAI Codex CLI runtime adapter.
#
# Uses the OpenAI Codex CLI: https://github.com/openai/codex
# Install: npm install -g @openai/codex
# Auth: codex login (ChatGPT account) or set OPENAI_API_KEY.

set -euo pipefail

is_chatgpt_auth() {
    [ -z "${OPENAI_API_KEY:-}" ] \
        && [ -f "$HOME/.codex/auth.json" ] \
        && jq -er '.auth_mode == "chatgpt"' "$HOME/.codex/auth.json" >/dev/null 2>&1
}

codex_model() {
    case "${AGENT_MODEL:-default}" in
        default|codex) echo "gpt-5-codex" ;;
        gpt-5)         echo "gpt-5" ;;
        *)             echo "$AGENT_MODEL" ;;
    esac
}

run_agent_cycle() {
    local model
    local codex_home
    local rc
    model="$(codex_model)"
    echo "[codex] cycle starting with requested model: $model"

    # In the unattended launcher, stdin stays attached to the container process.
    # Redirect from /dev/null so Codex doesn't wait for extra input before starting.
    # The Docker container is already our outer sandbox, so avoid nesting Codex's
    # bubblewrap sandbox inside it.
    if is_chatgpt_auth; then
        codex_home="$(mktemp -d)"
        mkdir -p "$codex_home"
        cp "$HOME/.codex/auth.json" "$codex_home/auth.json"
        echo "[codex] ChatGPT auth detected; using account-default model"
        CODEX_HOME="$codex_home" \
            codex exec \
            --dangerously-bypass-approvals-and-sandbox \
            "$AGENT_PROMPT" \
            </dev/null
        rc=$?
        rm -rf "$codex_home"
        return "$rc"
    fi

    codex exec \
        --model "$model" \
        --dangerously-bypass-approvals-and-sandbox \
        "$AGENT_PROMPT" \
        </dev/null
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
