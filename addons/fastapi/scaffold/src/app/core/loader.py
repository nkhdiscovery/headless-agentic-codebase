"""Module loader.

Discovers feature modules via Python entry points (group: `app.modules`) and
calls each module's `register(app, scheduler)` hook.

Modules declare themselves in pyproject.toml:

    [project.entry-points."app.modules"]
    photos = "app.photos:PhotosModule"

Each module class must subclass `Module` and implement `register`.
"""

from __future__ import annotations

import logging
from importlib.metadata import entry_points
from typing import Protocol

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from fastapi import FastAPI

logger = logging.getLogger(__name__)


class Module(Protocol):
    """The contract every module must satisfy."""

    name: str
    version: str

    def register(self, app: FastAPI, scheduler: AsyncIOScheduler) -> None: ...


def load_modules(app: FastAPI, scheduler: AsyncIOScheduler) -> list[Module]:
    """Discover, instantiate, and register all installed modules."""
    eps = entry_points(group="app.modules")
    loaded: list[Module] = []

    for ep in eps:
        try:
            cls = ep.load()
            module: Module = cls()
            module.register(app, scheduler)
            loaded.append(module)
            logger.info("registered module: %s v%s", module.name, module.version)
        except Exception:
            logger.exception("failed to load module: %s", ep.name)
            raise

    return loaded
