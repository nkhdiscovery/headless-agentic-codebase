# `<module_name>`

<!-- Replace <module_name> with the actual import path, e.g. `src.core` or `myapp.ingestion` -->

## What it does

<!-- One paragraph in plain language. What does this module own? Who calls it? -->

## Public API

<!-- Classes, functions, or endpoints other modules depend on. Be concrete:

- `class CoreApp` — the FastAPI app factory. Called from `daemon.py`.
- `def register_module(name, module) -> None` — registers a module's routes and jobs.
- `GET /api/health` — returns `{status, version}`.
-->

## Data tables / state

<!-- DB tables this module owns (with prefix), in-memory state, files on disk.

Example:
- `photos` — primary table, prefix-free since core. Migration 001.
  - `id INTEGER PK`, `path TEXT UNIQUE`, `sha256 TEXT`, `taken_at DATETIME`, ...
  - Relationships: 1:N with `faces`, `tags`, `places_photos`.

Skip if the module is stateless. Write `n/a`. -->

## Pipeline steps

<!-- If the module contributes steps to a processing pipeline:

- `step_name` (depends_on: `prev_step`)
  - reads: photo path, EXIF
  - writes: `photos.exif_json`, `photos.taken_at`

`n/a` if not applicable. -->

## Routes

<!-- HTTP routes this module registers, with shape:

- `GET /api/photos` → `{photos: [{id, path, taken_at}]}`
- `POST /api/photos/{id}/favorite` → `{ok: true}`

`n/a` if no routes. -->

## Configuration

<!-- Env vars and defaults:

| Var | Default | Purpose |
|---|---|---|
| `FRAME_FOO` | `bar` | Description |

`n/a` if none. -->

## Notes and gotchas

<!-- Free-form. Things future-you and the agent need to know:

- Why we use sha256 not blake3 (link to ADR or PR).
- Race condition in X if you call Y before Z.
- Performance caveat at >10k rows.
-->
