# OpenAPI clients addon

Auto-generate type-safe API clients for your mobile and web apps from your backend's OpenAPI spec. Stops the agent (and humans) from hand-maintaining client DTOs that drift from the server.

## What you get

- `scripts/dump_openapi.py` — extracts spec from a running FastAPI app
- `scripts/gen-clients.sh` — generates Swift, Kotlin, TypeScript clients via openapi-generator
- `openapitools.json` config
- CI workflow that fails if generated clients are out of date with the spec

## Requires

- A backend exposing `/openapi.json` (FastAPI does this automatically)
- One or more client targets (mobile, web)

## Apply

```bash
cp scripts/dump_openapi.py scripts/
cp scripts/gen-clients.sh scripts/
cp openapitools.json .

# Install openapi-generator-cli in the dev container
# (already in the base image as @openapitools/openapi-generator-cli)

# Configure targets in scripts/gen-clients.sh
```

## Workflow

1. Backend exposes OpenAPI spec.
2. `make gen-clients` runs `dump_openapi.py` then `gen-clients.sh`.
3. Generated clients land in `mobile/ios/Generated/`, `mobile/android/generated/`, `web/src/generated/`.
4. CI fails if PR changes backend routes without regenerating clients.

Add to CLAUDE.md:

```
## API contract
- Backend OpenAPI spec is the source of truth for client DTOs.
- Hand-written client code in api/ folders is OK; hand-written DTOs are not.
- Run `make gen-clients` after any route change.
```
