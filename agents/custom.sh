#!/usr/bin/env bash
# agents/custom.sh — template for adding your own agent runtime.
#
# Copy this file to agents/<your-runtime>.sh and adapt.
# Then set AGENT_RUNTIME=<your-runtime> in agent.config.

set -euo pipefail

run_agent_cycle() {
    echo "[custom] cycle starting"

    # Replace this with your runtime's headless/non-interactive command.
    # Required behaviour:
    #   - Read $AGENT_PROMPT (a string defined in agent.config)
    #   - Use $AGENT_MODEL for model selection
    #   - Have permission to read/write the entire /workspace mount
    #   - Have access to gh CLI (already installed in the dev container)
    #   - Exit when done (the launcher's while-loop will restart the cycle)
    #
    # Example:
    #
    # your-agent-cli \
    #     --model "$AGENT_MODEL" \
    #     --workspace /workspace \
    #     --autonomous \
    #     --prompt "$AGENT_PROMPT"

    echo "[custom] not yet configured. Edit agents/custom.sh."
    return 1
}

check_agent_installed() {
    command -v your-agent-cli >/dev/null 2>&1 || {
        echo "ERROR: your-agent-cli not found."
        return 1
    }
}

check_agent_authed() {
    # Verify auth state for your runtime.
    return 0
}
