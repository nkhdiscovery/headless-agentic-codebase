#!/usr/bin/env bash
# agents/junie.sh — JetBrains Junie runtime adapter.
#
# Junie is JetBrains' coding agent. As of late 2025/early 2026 it primarily
# runs inside JetBrains IDEs; CLI/headless mode availability varies by version.
#
# This adapter is a placeholder: if you have a Junie CLI binary installed,
# wire it up here. Otherwise, Junie isn't suitable for the unattended Docker
# loop pattern this template uses — stick with claude or gemini.

set -euo pipefail

run_agent_cycle() {
    echo "[junie] WARNING: Junie headless support is limited."
    echo "[junie] Update agents/junie.sh with your local junie CLI invocation."
    echo "[junie] Falling back: this cycle will exit immediately."
    return 0
}

check_agent_installed() {
    command -v junie >/dev/null 2>&1 || {
        echo "ERROR: junie CLI not found. Junie is primarily IDE-integrated."
        echo "If you have a CLI build, edit agents/junie.sh accordingly."
        return 1
    }
}

check_agent_authed() {
    return 0  # placeholder
}
