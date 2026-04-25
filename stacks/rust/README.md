# Rust stack

Adds Rust toolchain (rustup, cargo, clippy, rustfmt) to the dev container.

## Apply

```bash
cat stacks/rust/Dockerfile.snippet >> docker/Dockerfile.dev

# Copy Makefile targets from stacks/rust/Makefile.snippet

# Init project: cargo init --name {{PROJECT_NAME}}

# Update docs-gate config in CI:
#   DOCS_GATE_SOURCE_ROOT: src
#   DOCS_GATE_EXT: rs
```

## What you get

- `make test` → `cargo test`
- `make lint` → `cargo clippy -- -D warnings && cargo fmt --check`
- `make format` → `cargo fmt`
