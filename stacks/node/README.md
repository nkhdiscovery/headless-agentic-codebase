# Node/TypeScript stack

Adds TypeScript + ESLint + Vitest tooling. Node.js itself is already in the base image.

## Apply

```bash
# No Dockerfile changes needed — Node is already in the base image.

# Copy Makefile targets
# (manual: replace placeholders with stacks/node/Makefile.snippet contents)

# Copy starter package.json + tsconfig
cp stacks/node/package.json.template package.json
cp stacks/node/tsconfig.json.template tsconfig.json
cp stacks/node/eslint.config.js.template eslint.config.js

# Update docs-gate config in CI:
#   DOCS_GATE_SOURCE_ROOT: src
#   DOCS_GATE_EXT: ts
```

## What you get

- `make test` → `vitest run`
- `make lint` → `eslint . && tsc --noEmit`
- `make format` → `prettier --write .`
- ESM modules, strict TypeScript
- Vitest for tests (Jest-compatible API but faster)
