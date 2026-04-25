#!/usr/bin/env python3
"""Dump the OpenAPI spec from a running FastAPI app.

Usage:
    python scripts/dump_openapi.py [output_path]

If no output path, writes to docs/openapi.json. The CI gen-clients job
expects this file to exist before running openapi-generator-cli.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> None:
    # Adjust this import path for your project layout.
    from app.core.app import create_app

    app = create_app()
    spec = app.openapi()

    out = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("docs/openapi.json")
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(spec, indent=2, sort_keys=True))
    print(f"wrote {out} ({len(json.dumps(spec))} chars)")


if __name__ == "__main__":
    main()
