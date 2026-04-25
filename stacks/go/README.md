# Go stack

Adds Go 1.22+ to the dev container.

## Apply

```bash
cat stacks/go/Dockerfile.snippet >> docker/Dockerfile.dev

# Copy Makefile targets from stacks/go/Makefile.snippet

# go.mod will be created by `go mod init <module-path>`

# Update docs-gate config in CI:
#   DOCS_GATE_SOURCE_ROOT: pkg     (or wherever your packages live)
#   DOCS_GATE_EXT: go
```

## What you get

- `make test` → `go test ./...`
- `make lint` → `go vet ./... && staticcheck ./...`
- `make format` → `gofmt -w .`
