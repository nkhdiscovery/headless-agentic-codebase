---
description: Scaffold a new module that registers with core
---

Scaffold a new module named: $ARGUMENTS

Before writing code:

1. Read the relevant ADR for module registration (typically ADR 0003 or similar).
2. Read `docs/architecture.md` to see where this module fits.
3. Check the project manifest (`pyproject.toml`, `package.json`, etc.) for the module entry-point group.

Then create, in this order:

1. `<source_root>/$ARGUMENTS/__init__.py` (or equivalent) — exports the Module class.
2. `<source_root>/$ARGUMENTS/routes.py` — HTTP routes (empty if none).
3. `<source_root>/$ARGUMENTS/jobs.py` — scheduled jobs (empty if none).
4. `tests/$ARGUMENTS/test_registration.py` — module loads and registers correctly.
5. `docs/codebase/$ARGUMENTS.md` — populate the seven-section template.
6. Update the project manifest to declare the entry point.

Do NOT:
- Reach into core internals beyond the registration API.
- Write production logic in this scaffolding pass.

When done, run `make test` and report.
