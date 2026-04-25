# Python stack

Adds Python 3.12 + ruff + mypy + pytest tooling to the base dev container and Makefile.

## Apply

```bash
# Append the Dockerfile snippet to docker/Dockerfile.dev
cat stacks/python/Dockerfile.snippet >> docker/Dockerfile.dev

# Replace Makefile test/lint/format targets with the Python ones
# (manual: copy from stacks/python/Makefile.snippet into your Makefile)

# Copy starter pyproject.toml to repo root
cp stacks/python/pyproject.toml.template pyproject.toml

# Update CI
cp stacks/python/ci.yml.snippet .github/workflows/ci-python.yml
# Or merge into existing ci.yml

# Set docs-gate config
# In .github/workflows/ci.yml under docs-gate job:
#   DOCS_GATE_SOURCE_ROOT: src       (or wherever your code lives)
#   DOCS_GATE_EXT: py
```

## What you get

- `make test` → `pytest -ra --cov`
- `make lint` → `ruff check && ruff format --check && mypy`
- `make format` → `ruff format && ruff check --fix`
- mypy strict, ruff with sensible defaults
- `pyproject.toml` with reasonable starting deps
