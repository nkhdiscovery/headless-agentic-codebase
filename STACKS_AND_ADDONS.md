# Stacks and addons

The core of this template is **language-agnostic**. Pick exactly the optional pieces you need.

## Stacks (pick one or more)

A stack adds a language toolchain — compiler, package manager, linter, test runner — to the dev container and Makefile. Most projects need at least one.

| Stack | Includes | When to pick |
|---|---|---|
| `stacks/python/` | Python 3.12 + ruff + mypy + pytest | Backend, ML, data, scripts |
| `stacks/node/` | TypeScript + ESLint + Vitest + Prettier | Web frontend, CLI tools, anything npm-based |
| `stacks/go/` | Go 1.22 + gofmt + staticcheck | Single-binary CLIs, backend services that need to be small |
| `stacks/rust/` | Rust stable + clippy + rustfmt | Performance-critical, embedded, Tauri shells |

You can apply more than one — e.g. Python backend + Node frontend.

## Addons (drop in when you need them)

An addon is a feature pack you might or might not need, depending on the project shape. Each is self-contained; you can add or remove without touching the core.

| Addon | What it scaffolds | Requires |
|---|---|---|
| `addons/fastapi/` | FastAPI backend with SQLite, Alembic, APScheduler, module loader | `stacks/python` |
| `addons/nextjs/` | Next.js 15 web app with App Router + Tailwind | `stacks/node` |
| `addons/mobile-rn/` | React Native + Expo cross-platform mobile app | `stacks/node` |
| `addons/mobile-native/` | Native SwiftUI iOS + Kotlin/Compose Android | none (Xcode/Android Studio on host) |
| `addons/desktop-tauri/` | Tauri desktop app for Mac/Windows/Linux | `stacks/rust` + a web UI |
| `addons/cli-tool/` | CLI argument parsing, subcommands, config, completion | one of the stacks |
| `addons/openapi-clients/` | Auto-generated mobile/web clients from backend OpenAPI spec | a backend that exposes /openapi.json |

## How to apply

Each stack and addon has its own `README.md` with apply instructions. The pattern:

1. Read the README in the directory
2. Append/copy snippets to your `Dockerfile.dev`, `Makefile`, `.github/workflows/ci.yml`
3. Copy scaffold files into the project layout the addon expects
4. Add the relevant invariant block to your `CLAUDE.md` (each addon README shows the block)
5. Configure `DOCS_GATE_*` in CI if the docs-gate should cover the new code

## Combining

Common combinations:

**Backend + mobile app + admin web**
```
stacks/python + stacks/node
addons/fastapi
addons/nextjs        (admin web)
addons/mobile-rn     (or mobile-native if quality matters)
addons/openapi-clients
```

**Single-binary CLI tool**
```
stacks/go            (or stacks/rust)
addons/cli-tool
```

**Full SaaS (the kitchen sink)**
```
stacks/python + stacks/node + stacks/rust
addons/fastapi
addons/nextjs
addons/mobile-native
addons/desktop-tauri
addons/openapi-clients
```

## Adding your own

If you need a stack or addon that isn't here, follow the convention:

1. Create `stacks/<lang>/` or `addons/<feature>/`
2. README explaining what it does, when to use it, when NOT to use it
3. Snippets for `Dockerfile.dev`, `Makefile`, CI
4. Scaffold files in `scaffold/` if applicable
5. CLAUDE.md invariant block in the README

Then PR it back to the template if you think others would use it.
