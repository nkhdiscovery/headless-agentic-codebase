"""Application factory.

`create_app()` builds the FastAPI instance, wires DB lifespan, runs the
module loader so feature modules register their routes and jobs.
"""

from __future__ import annotations

import logging
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from app.core.db import close_engine, init_engine
from app.core.loader import load_modules
from app.core.scheduler import start_scheduler, stop_scheduler
from app.settings import get_settings

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    settings.data_dir.mkdir(parents=True, exist_ok=True)
    settings.config_dir.mkdir(parents=True, exist_ok=True)

    await init_engine(settings.database_url)
    scheduler = start_scheduler()
    app.state.scheduler = scheduler

    load_modules(app, scheduler)
    logger.info("startup complete")

    try:
        yield
    finally:
        stop_scheduler(scheduler)
        await close_engine()
        logger.info("shutdown complete")


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title="App",
        version=settings.version,
        lifespan=lifespan,
    )

    @app.get("/api/health")
    async def health() -> dict[str, str]:
        return {
            "status": "ok",
            "version": settings.version,
            "build": settings.build,
        }

    return app
