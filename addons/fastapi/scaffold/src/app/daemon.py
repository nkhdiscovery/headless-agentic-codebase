"""Entry point: `python -m app.daemon`.

Bootstraps logging → settings → app factory → uvicorn.
No business logic lives here.
"""

from __future__ import annotations

import logging
import logging.handlers
from pathlib import Path

import uvicorn

from app.core.app import create_app
from app.settings import get_settings


def setup_logging(log_level: str, log_dir: Path | str = "./logs") -> None:
    """Configure logging with timestamps for both console and file output."""
    log_dir = Path(log_dir)
    log_dir.mkdir(parents=True, exist_ok=True)

    log_format = "%(asctime)s [%(levelname)-8s] %(name)s - %(message)s"
    date_format = "%Y-%m-%d %H:%M:%S"

    root_logger = logging.getLogger()
    root_logger.setLevel(log_level)

    formatter = logging.Formatter(log_format, datefmt=date_format)

    console_handler = logging.StreamHandler()
    console_handler.setLevel(log_level)
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)

    log_file = log_dir / "app.log"
    file_handler = logging.handlers.RotatingFileHandler(
        log_file,
        maxBytes=10 * 1024 * 1024,
        backupCount=5,
    )
    file_handler.setLevel(log_level)
    file_handler.setFormatter(formatter)
    root_logger.addHandler(file_handler)


def main() -> None:
    settings = get_settings()
    setup_logging(settings.log_level)
    app = create_app()
    uvicorn.run(
        app,
        host=settings.host,
        port=settings.port,
        log_config=None,
    )


if __name__ == "__main__":
    main()
