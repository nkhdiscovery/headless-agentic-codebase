"""Async SQLAlchemy engine + session management.

Engine is created at startup and reused; sessions are per-request
via the `get_session` dependency.
"""

from __future__ import annotations

from collections.abc import AsyncIterator

from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine
from sqlalchemy.orm import DeclarativeBase

_engine: AsyncEngine | None = None
_session_factory: async_sessionmaker[AsyncSession] | None = None


class Base(DeclarativeBase):
    """Base for all ORM models. Modules subclass this in their own files."""


async def init_engine(database_url: str) -> None:
    global _engine, _session_factory
    _engine = create_async_engine(database_url, future=True)
    _session_factory = async_sessionmaker(_engine, expire_on_commit=False)


async def close_engine() -> None:
    global _engine, _session_factory
    if _engine is not None:
        await _engine.dispose()
    _engine = None
    _session_factory = None


async def get_session() -> AsyncIterator[AsyncSession]:
    """FastAPI dependency: yields a session, closes it after the request."""
    if _session_factory is None:
        raise RuntimeError("Engine not initialised. Did create_app() run?")
    async with _session_factory() as session:
        yield session
