"""APScheduler setup with SQLAlchemy job store so jobs survive restarts."""

from __future__ import annotations

import logging

from apscheduler.jobstores.sqlalchemy import SQLAlchemyJobStore
from apscheduler.schedulers.asyncio import AsyncIOScheduler

from app.settings import get_settings

logger = logging.getLogger(__name__)


def start_scheduler() -> AsyncIOScheduler:
    settings = get_settings()
    # Use sync URL for the job store (APScheduler is not async-native for storage).
    sync_url = settings.database_url.replace("+aiosqlite", "").replace("+asyncpg", "")
    jobstores = {"default": SQLAlchemyJobStore(url=sync_url)}
    scheduler = AsyncIOScheduler(jobstores=jobstores)
    scheduler.start()
    logger.info("scheduler started")
    return scheduler


def stop_scheduler(scheduler: AsyncIOScheduler) -> None:
    scheduler.shutdown(wait=False)
    logger.info("scheduler stopped")
