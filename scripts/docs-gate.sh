#!/usr/bin/env bash
# scripts/docs-gate.sh
#
# Enforces: every PR that changes <SOURCE_ROOT>/<module>/**/*.<EXT> must
# also change docs/codebase/<module>.md. Keeps the per-module knowledge
# base honest without human policing.
#
# Configure for your project by editing the two CONFIG variables below,
# OR by setting env vars DOCS_GATE_SOURCE_ROOT / DOCS_GATE_EXT.
#
# Env vars expected by CI:
#   BASE_SHA, HEAD_SHA — diff range. Optional locally.
#   PR_LABELS — if it contains "docs-exempt", the gate passes.
#
# Exits 0 clean, 1 if the gate fails.

set -euo pipefail

# ---- CONFIG (edit per project) ---------------------------------------------

# Where your source code lives (relative to repo root). Examples: src, frame, lib, app.
SOURCE_ROOT="${DOCS_GATE_SOURCE_ROOT:-src}"

# File extension regex (no leading dot). Examples: py, ts, go, rs, java
EXT="${DOCS_GATE_EXT:-py}"

# ---- Early exit on docs-exempt label ---------------------------------------

if [ "${PR_LABELS:-}" ]; then
    if printf '%s' "$PR_LABELS" | tr ' \t\n,' '\n\n\n\n' | grep -Fxq "docs-exempt"; then
        echo "docs-gate: PR has docs-exempt label — skipping."
        exit 0
    fi
fi

# ---- Resolve base / head ---------------------------------------------------

BASE="${BASE_SHA:-}"
HEAD="${HEAD_SHA:-HEAD}"

if [ -z "$BASE" ]; then
    if git rev-parse --verify --quiet origin/main >/dev/null; then
        BASE="$(git merge-base origin/main HEAD)"
    elif git rev-parse --verify --quiet main >/dev/null; then
        BASE="$(git merge-base main HEAD)"
    else
        echo "docs-gate: no base ref found (set BASE_SHA, or ensure origin/main/main exists)." >&2
        exit 2
    fi
fi

# ---- Collect changed files -------------------------------------------------

mapfile -t CHANGED < <(git diff --name-only "$BASE" "$HEAD" | grep -v '^$' || true)

if [ "${#CHANGED[@]}" -eq 0 ]; then
    echo "docs-gate: no changed files."
    exit 0
fi

declare -A CODE_MODULES=()
declare -A DOC_MODULES=()

CODE_RE="^${SOURCE_ROOT}/([a-zA-Z_][a-zA-Z0-9_]*)/.+\.${EXT}$"
DOC_RE='^docs/codebase/([a-zA-Z_][a-zA-Z0-9_]*)\.md$'
TEST_RE="^${SOURCE_ROOT}/[^/]+/tests/"

for path in "${CHANGED[@]}"; do
    if [[ "$path" =~ $CODE_RE ]]; then
        module="${BASH_REMATCH[1]}"
        if [[ "$path" =~ $TEST_RE ]]; then
            continue
        fi
        CODE_MODULES["$module"]=1
        continue
    fi
    if [[ "$path" =~ $DOC_RE ]]; then
        DOC_MODULES["${BASH_REMATCH[1]}"]=1
    fi
done

# ---- Report missing docs ---------------------------------------------------

missing=()
for mod in "${!CODE_MODULES[@]}"; do
    if [ -z "${DOC_MODULES[$mod]+set}" ]; then
        missing+=("$mod")
    fi
done

if [ "${#missing[@]}" -eq 0 ]; then
    if [ "${#CODE_MODULES[@]}" -eq 0 ]; then
        echo "docs-gate: OK (no code modules changed)."
    else
        echo "docs-gate: OK (modules touched: ${!CODE_MODULES[*]})."
    fi
    exit 0
fi

echo "docs-gate: FAIL — the following module(s) changed without a matching doc update:"
for mod in "${missing[@]}"; do
    echo "  - ${SOURCE_ROOT}/$mod/ → expected docs/codebase/$mod.md in this PR"
done
echo ""
echo "Either update docs/codebase/<module>.md for each listed module, or"
echo "label the PR with \"docs-exempt\" if the change is trivial (typo,"
echo "log-string fix). See docs/codebase.md."
exit 1
