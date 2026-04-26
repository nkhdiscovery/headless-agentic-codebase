#!/usr/bin/env bash
# scripts/agent-cost.sh
#
# Parse forensic .jsonl logs to compute agent token usage and cost.
#
# Subcommands:
#   today              today's tokens + cost (human-readable)
#   total              all-time tokens + cost
#   range FROM TO      cost between YYYY-MM-DD dates inclusive
#   raw-today          today's stats as JSON (machine-readable)
#   under-cap          exit 0 if under AGENT_MAX_DAILY_USD, 1 if over
#   pr-cost            cost of the most recent agent session today
#
# Pricing: hardcoded USD per million tokens. Update when prices change.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [ -f agent.config ]; then
    # shellcheck disable=SC1091
    source agent.config
fi

# --- Pricing per million tokens, USD ---------------------------------------
# Returns: input output cache_read cache_write

price_for() {
    case "$1" in
        *opus-4*)            echo "15 75 1.5 18.75" ;;
        *sonnet-4*)          echo "3 15 0.3 3.75" ;;
        *haiku-4*)           echo "0.8 4 0.08 1" ;;
        *gemini-2.5-pro*)    echo "1.25 10 0 0" ;;
        *gemini-2.5-flash*)  echo "0.30 2.50 0 0" ;;
        *gpt-5-codex*|*gpt-5*) echo "5 15 0 0" ;;
        *)                   echo "3 15 0.3 3.75" ;;  # safe default
    esac
}

# --- Aggregate a list of files (newline-separated paths on stdin) ---------

aggregate() {
    # Read all paths into an array
    local files=()
    while IFS= read -r f; do
        [ -n "$f" ] && [ -f "$f" ] && files+=("$f")
    done

    if [ "${#files[@]}" -eq 0 ]; then
        echo '{"input":0,"output":0,"cache_read":0,"cache_create":0,"cost_usd":0,"model":"none"}'
        return
    fi

    # Identify model from first session-init line we can find
    local model=""
    for f in "${files[@]}"; do
        model=$({ grep -E '^\{' "$f" 2>/dev/null || true; } \
            | jq -r 'select(.type=="system" and .subtype=="init") | .model // empty' 2>/dev/null \
            | head -1)
        [ -n "$model" ] && break
    done
    [ -z "$model" ] && model="${AGENT_MODEL:-unknown}"

    # Get prices
    local prices in_p out_p cache_r_p cache_w_p
    prices=$(price_for "$model")
    in_p=$(echo "$prices" | awk '{print $1}')
    out_p=$(echo "$prices" | awk '{print $2}')
    cache_r_p=$(echo "$prices" | awk '{print $3}')
    cache_w_p=$(echo "$prices" | awk '{print $4}')

    # Concatenate all valid JSON lines, sum the usage fields.
    # Use `|| true` on grep so an empty match doesn't kill the pipe under pipefail.
    { cat "${files[@]}" | grep -E '^\{' || true; } \
      | jq -s --arg model "$model" \
              --argjson in_p "$in_p" \
              --argjson out_p "$out_p" \
              --argjson cache_r_p "$cache_r_p" \
              --argjson cache_w_p "$cache_w_p" '
        reduce .[] as $i (
            {input:0, output:0, cache_read:0, cache_create:0};
            if $i.type=="assistant" and $i.message.usage then
                .input += ($i.message.usage.input_tokens // 0) |
                .output += ($i.message.usage.output_tokens // 0) |
                .cache_read += ($i.message.usage.cache_read_input_tokens // 0) |
                .cache_create += ($i.message.usage.cache_creation_input_tokens // 0)
            else . end
        ) |
        . + {
            cost_usd: (
                (.input * $in_p + .output * $out_p +
                 .cache_read * $cache_r_p + .cache_create * $cache_w_p) / 1000000
            ),
            model: $model
        }
    '
}

humanise() {
    jq -r '
        "Model:        \(.model)
Input:        \(.input) tokens
Output:       \(.output) tokens
Cache read:   \(.cache_read) tokens
Cache write:  \(.cache_create) tokens
Cost:         $\(.cost_usd * 10000 | floor / 10000)"
    '
}

# --- Subcommands -----------------------------------------------------------

cmd_today() {
    local f="logs/daily/$(date +%Y-%m-%d).jsonl"
    if [ ! -f "$f" ]; then
        echo "No log for today yet."
        return
    fi
    if [ ! -s "$f" ]; then
        echo "Today's log is empty (no agent activity recorded yet)."
        return
    fi
    printf '%s\n' "$f" | aggregate | humanise
}

cmd_total() {
    find logs/daily -name "*.jsonl" 2>/dev/null | aggregate | humanise
}

cmd_range() {
    local from="$1" to="$2"
    {
        for f in logs/daily/*.jsonl; do
            [ -f "$f" ] || continue
            local d
            d=$(basename "$f" .jsonl)
            if [[ "$d" > "$from" || "$d" == "$from" ]] && \
               [[ "$d" < "$to" || "$d" == "$to" ]]; then
                echo "$f"
            fi
        done
    } | aggregate | humanise
}

cmd_raw_today() {
    local f="logs/daily/$(date +%Y-%m-%d).jsonl"
    if [ ! -f "$f" ] || [ ! -s "$f" ]; then
        echo '{"input":0,"output":0,"cache_read":0,"cache_create":0,"cost_usd":0,"model":"none"}'
        return
    fi
    printf '%s\n' "$f" | aggregate
}

cmd_under_cap() {
    local cap="${AGENT_MAX_DAILY_USD:-0}"
    if [ "$cap" = "0" ] || [ -z "$cap" ]; then
        return 0
    fi
    local cost
    cost=$(cmd_raw_today | jq -r '.cost_usd')
    local over
    over=$(awk -v c="$cost" -v cap="$cap" 'BEGIN { print (c >= cap) ? 1 : 0 }')
    if [ "$over" = "1" ]; then
        echo "Daily cap reached: \$$(printf '%.2f' "$cost") >= \$${cap}"
        return 1
    fi
    return 0
}

cmd_pr_cost() {
    # Cost of the most recent session in today's log.
    local f="logs/daily/$(date +%Y-%m-%d).jsonl"
    [ -f "$f" ] || { echo "0.00"; return; }

    local last_sid
    last_sid=$(grep -E '^\{' "$f" \
        | jq -r 'select(.type=="system" and .subtype=="init") | .session_id // empty' \
        | tail -1)
    [ -z "$last_sid" ] && { echo "0.00"; return; }

    local tmp
    tmp=$(mktemp)
    grep "\"session_id\":\"$last_sid\"" "$f" > "$tmp" || true

    if [ ! -s "$tmp" ]; then
        rm -f "$tmp"
        echo "0.00"
        return
    fi

    printf '%s\n' "$tmp" | aggregate | jq -r '.cost_usd | . * 100 | floor / 100'
    rm -f "$tmp"
}

cmd_pr_total() {
    # Sum all "Cycle cost: $X.XX" comments already on the given PR plus
    # this cycle's pr-cost. Returns total USD as a decimal string.
    local pr_num="$1"
    if [ -z "$pr_num" ]; then
        echo "Usage: $0 pr-total <pr-number>" >&2
        return 2
    fi

    local prior
    prior=$(gh pr view "$pr_num" --json comments --jq \
        '.comments[].body | capture("Cycle cost: \\$(?<n>[0-9.]+)") | .n' 2>/dev/null \
        | awk 'BEGIN{s=0} {s+=$1} END{printf "%.4f\n", s}')
    [ -z "$prior" ] && prior="0"

    local current
    current=$(cmd_pr_cost)
    [ -z "$current" ] && current="0"

    awk -v p="$prior" -v c="$current" 'BEGIN { printf "%.2f\n", p + c }'
}

cmd_pr_warn_threshold() {
    # Echoes the threshold (or empty if disabled).
    echo "${AGENT_PR_COST_WARN_USD:-0}"
}

case "${1:-today}" in
    today)             cmd_today ;;
    total)             cmd_total ;;
    range)             cmd_range "$2" "$3" ;;
    raw-today)         cmd_raw_today ;;
    under-cap)         cmd_under_cap ;;
    pr-cost)           cmd_pr_cost ;;
    pr-total)          cmd_pr_total "$2" ;;
    pr-warn-threshold) cmd_pr_warn_threshold ;;
    *)
        echo "Usage: $0 {today|total|range FROM TO|raw-today|under-cap|pr-cost|pr-total <N>|pr-warn-threshold}" >&2
        exit 2 ;;
esac
