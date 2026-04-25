#!/usr/bin/env bash
# scripts/gen-clients.sh
#
# Generate type-safe API clients from the backend's OpenAPI spec.
# Edit the TARGETS array to match your project — drop targets you don't ship.

set -euo pipefail

SPEC="${SPEC:-docs/openapi.json}"

if [ ! -f "$SPEC" ]; then
    echo "ERROR: spec not found at $SPEC. Run scripts/dump_openapi.py first." >&2
    exit 1
fi

# Each entry: "<generator>:<output_dir>:<extra_args>"
TARGETS=(
    "typescript-fetch:web/src/generated/api"
    "swift5:ios/Generated"
    "kotlin:android/app/src/main/java/com/example/api/generated"
)

for target in "${TARGETS[@]}"; do
    IFS=':' read -r gen out _ <<< "$target"
    [ -d "$(dirname "$out")" ] || continue   # skip targets whose parent doesn't exist
    echo "==> $gen -> $out"
    mkdir -p "$out"
    npx --yes @openapitools/openapi-generator-cli generate \
        -i "$SPEC" \
        -g "$gen" \
        -o "$out" \
        --skip-validate-spec
done

echo "done"
