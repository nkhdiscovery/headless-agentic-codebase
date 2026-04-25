"""Entry point: `python -m app.daemon`.

Bootstraps logging → settings → app factory → uvicorn.
No business logic lives here.
"""

from __future__ import annotations

import logging

import uvicorn

from app.core.app import create_app
from app.settings import get_settings


def main() -> None:
    settings = get_settings()
    logging.basicConfig(
        level=settings.log_level,
        format="%(asctime)s %(levelname)s %(name)s %(message)s",
    )
    app = create_app()
    uvicorn.run(
        app,
        host=settings.host,
        port=settings.port,
        log_config=None,
    )


if __name__ == "__main__":
    main()
