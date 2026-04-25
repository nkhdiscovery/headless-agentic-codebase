# Codebase index

One doc per top-level module under your source root (e.g. `src/<module>/` or `<package>/<module>/`). Each follows the same seven-section template — see `template.md` in this directory.

This is the **hows and whys** of the code. *What* is documented by the code itself. *Why* and *how* live here.

A CI gate (`scripts/docs-gate.sh`) fails any PR that changes `<source_root>/<module>/**/*.{ext}` without also touching the matching `docs/codebase/<module>.md`. Trivial PRs can bypass via the `docs-exempt` label on the pull request.

## Modules

<!-- Auto-maintained by the agent. Add one row per module as you create them. -->

| Module | Purpose |
|---|---|
| <!-- example: `src.core` --> | <!-- example: App factory, DB engine, module loader, scheduler. The scaffold everything hangs off. --> |

## Non-module files

<!-- Files that don't fit the module pattern but matter — `daemon.py`, `__init__.py`, etc. -->

## Template

Every per-module file follows this order:

1. **What it does** — one paragraph, plain language.
2. **Public API** — classes, functions, endpoints other modules depend on.
3. **Data tables / state** — DB tables, in-memory state, files owned.
4. **Pipeline steps** — name, depends_on, what the step reads + writes (skip if not applicable).
5. **Routes** — HTTP method + path + shape, `n/a` if the module has none.
6. **Configuration** — env vars, defaults, what they control.
7. **Notes and gotchas** — things that bit us, reasons behind non-obvious choices, perf caveats.
