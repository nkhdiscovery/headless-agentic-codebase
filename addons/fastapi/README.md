# Backend addon — FastAPI

Production-ready FastAPI backend with SQLite/Postgres, Alembic migrations, APScheduler, and OpenAPI auto-generation.

## What you get

- `src/<package>/core/` — app factory, DB engine, lifespan management
- `src/<package>/core/loader.py` — entry-point module loader (so features register themselves)
- SQLAlchemy 2.0 with async support
- Alembic configured with autogenerate
- APScheduler with SQLAlchemy job store (jobs survive restart)
- Pydantic v2 settings from env vars
- Structured logging with secret redaction
- OpenAPI spec extraction (`scripts/dump_openapi.py`)
- Health endpoint `/api/health` returning `{status, version, build}`

## Requires

- `stacks/python` applied first

## Apply

```bash
# Apply the Python stack first
cat stacks/python/Dockerfile.snippet >> docker/Dockerfile.dev

# Drop the FastAPI scaffold into src/
cp -r addons/fastapi/scaffold/src/* src/

# Update pyproject.toml to add deps:
#   fastapi, uvicorn[standard], sqlalchemy, alembic, apscheduler, pydantic-settings, httpx
```

## Files

```
addons/fastapi/
├── README.md
└── scaffold/
    └── src/<package>/
        ├── __init__.py
        ├── daemon.py             # Entry point: python -m <package>.daemon
        ├── settings.py           # Pydantic settings
        ├── core/
        │   ├── __init__.py
        │   ├── app.py            # create_app()
        │   ├── db.py             # engine, session
        │   ├── loader.py         # entry-point module discovery
        │   └── scheduler.py      # APScheduler setup
        └── alembic/
            ├── env.py
            └── script.py.mako
```

Add to CLAUDE.md when adopting:

```
## Backend invariants
- All routes go through registered modules — no routes added directly to the app.
- Schema changes go through Alembic. Never edit migrations after merge.
- DB sessions are async. Use `Depends(get_session)` in routes.
- Background work goes through APScheduler, not bare asyncio tasks.
- All env vars are typed in `src/<package>/settings.py`.
```
