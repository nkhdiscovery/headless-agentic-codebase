# CLI tool addon

Boilerplate for shipping a command-line tool — argument parsing, subcommands, config files, completion scripts.

## What you get

- Argument parsing with sensible defaults (Click for Python, oclif for Node, cobra for Go, clap for Rust)
- Subcommand structure
- Config file loading (~/.config/<tool>/config.toml)
- Shell completion generation
- Single-binary release pipeline (where applicable)
- `make cli-build`, `make cli-test` targets

## Requires

- One of `stacks/python`, `stacks/node`, `stacks/go`, `stacks/rust`

## Variants

Pick the language file matching your stack:

- `addons/cli-tool/python/` — Click + Typer
- `addons/cli-tool/node/` — oclif (best for npm-distributed tools)
- `addons/cli-tool/go/` — cobra (best for single-binary distribution)
- `addons/cli-tool/rust/` — clap (smallest binaries, fastest startup)

## Apply

```bash
cp -r addons/cli-tool/<lang>/scaffold/* .
```

Add to CLAUDE.md:

```
## CLI invariants
- Commands return exit codes — 0 success, 1 user error, 2 system error.
- All output to stderr except the actual result.
- Long operations show progress to stderr.
- Config from $XDG_CONFIG_HOME/<tool>/config.toml, env vars override file.
- --help is always available; --version prints semver.
```
