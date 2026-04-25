#!/usr/bin/env bash
# agents/gemini.sh — Gemini CLI runtime adapter.
#
# Uses the official Gemini CLI: https://github.com/google-gemini/gemini-cli
# Install: npm install -g @google/gemini-cli
# Auth: gemini auth (browser flow) or set GEMINI_API_KEY.
#
# Note: Gemini CLI's slash commands and behaviour differ slightly from Claude Code.
# It reads GEMINI.md by convention; we symlink it to CLAUDE.md so the same
# project files work for both runtimes.

set -euo pipefail

gemini_model() {
    case "${AGENT_MODEL:-default}" in
        default|pro)   echo "gemini-2.5-pro" ;;
        flash|fast)    echo "gemini-2.5-flash" ;;
        *)             echo "$AGENT_MODEL" ;;
    esac
}

ensure_gemini_md_link() {
    # Gemini CLI looks for GEMINI.md; we want one source of truth in CLAUDE.md.
    if [ ! -e GEMINI.md ] && [ -f CLAUDE.md ]; then
        ln -sf CLAUDE.md GEMINI.md
    fi
}

run_agent_cycle() {
    local model
    model="$(gemini_model)"
    ensure_gemini_md_link
    echo "[gemini] cycle starting with model: $model"

    # Gemini CLI's non-interactive flag is -p (prompt) similar to Claude Code.
    # --yolo skips approvals, equivalent to --dangerously-skip-permissions.
    gemini \
        --model "$model" \
        --yolo \
        -p "$AGENT_PROMPT"
}

check_agent_installed() {
    command -v gemini >/dev/null 2>&1 || {
        echo "ERROR: gemini CLI not found. Install: npm install -g @google/gemini-cli"
        return 1
    }
}

check_agent_authed() {
    if [ -z "${GEMINI_API_KEY:-}" ] && [ ! -d "$HOME/.gemini" ]; then
        echo "ERROR: Gemini not authed. Run: gemini auth   (or set GEMINI_API_KEY)"
        return 1
    fi
}
