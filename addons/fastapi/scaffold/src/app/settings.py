"""Typed application settings, loaded from environment variables."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """All configuration goes through this class. Never read os.environ directly."""

    model_config = SettingsConfigDict(env_prefix="APP_", env_file=".env", extra="ignore")

    # --- Server ---
    host: str = "0.0.0.0"
    port: int = 8000
    log_level: str = "INFO"

    # --- Storage ---
    data_dir: Path = Field(default=Path("./.data"))
    config_dir: Path = Field(default=Path("./.config"))

    # --- Database ---
    database_url: str = "sqlite+aiosqlite:///./.data/app.sqlite"

    # --- App identity ---
    version: str = "0.0.1"
    build: str = "dev"


@lru_cache
def get_settings() -> Settings:
    return Settings()
