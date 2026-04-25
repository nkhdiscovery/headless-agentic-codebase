# Generic agent Makefile.
# All commands route through Docker so dev matches CI exactly.
# Customise test/lint/format targets per language.

.PHONY: help build rebuild shell test lint format ci daemon \
        agent-start agent-stop agent-logs agent-cost sync-template clean fresh

# Project-scoped compose — derives a unique name from the repo directory so
# multiple agent instances on the same host don't collide on image, container,
# network, or volume names. Override with PROJECT_NAME=foo if needed.
PROJECT_NAME ?= $(notdir $(CURDIR))
COMPOSE := docker compose -f docker/docker-compose.yml -p $(PROJECT_NAME)
export COMPOSE_PROJECT_NAME = $(PROJECT_NAME)

# Read AGENT_RUNTIME from agent.config so build only installs the CLI you actually
# use. Override with INSTALL_AGENTS="claude gemini" to install multiple.
AGENT_RUNTIME := $(shell bash -c 'source ./agent.config 2>/dev/null && echo $$AGENT_RUNTIME' 2>/dev/null)
AGENT_RUNTIME := $(if $(AGENT_RUNTIME),$(AGENT_RUNTIME),claude)
INSTALL_AGENTS ?= $(AGENT_RUNTIME)
BUILD_ARGS := --build-arg INSTALL_AGENTS="$(INSTALL_AGENTS)"

help:  ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build:  ## Build the dev image (only installs the AGENT_RUNTIME from agent.config)
	@echo "Building with INSTALL_AGENTS=$(INSTALL_AGENTS)"
	$(COMPOSE) build $(BUILD_ARGS) dev

rebuild:  ## Build the dev image without cache (forces fresh install of agent CLIs)
	@echo "Rebuilding with INSTALL_AGENTS=$(INSTALL_AGENTS)"
	$(COMPOSE) build --no-cache $(BUILD_ARGS) dev

shell:  ## Drop into dev container
	$(COMPOSE) run --rm dev

# --- Customise these per project ---
test:  ## Run tests
	$(COMPOSE) run --rm dev sh -c "echo 'Configure test command in Makefile'"

lint:  ## Run linters
	$(COMPOSE) run --rm dev sh -c "echo 'Configure lint command in Makefile'"

format:  ## Auto-format
	$(COMPOSE) run --rm dev sh -c "echo 'Configure format command in Makefile'"

ci: lint test  ## Run full CI suite

# --- Agent ---
agent-start:  ## Launch unattended agent
	@bash scripts/launch-agent.sh

agent-stop:  ## Stop the agent cleanly
	$(COMPOSE) stop agent 2>/dev/null || true
	@rm -f .claude/unattended
	@echo "Agent stopped."

agent-logs:  ## Tail today's log
	@tail -f logs/daily/$$(date +%Y-%m-%d).md 2>/dev/null || echo "No log yet."

agent-cost:  ## Show today's agent token spend
	@bash scripts/agent-cost.sh today

sync-template:  ## Pull infrastructure updates from the headless-agentic-codebase template (3-way merge, surfaces conflicts)
	@bash scripts/sync-from-template.sh

# --- Housekeeping ---
clean:  ## Remove build artefacts
	find . -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name node_modules -prune -exec rm -rf {} + 2>/dev/null || true
	rm -rf dist build *.egg-info .pytest_cache .mypy_cache .ruff_cache

fresh: clean  ## Full rebuild (no cache, only installs AGENT_RUNTIME)
	$(COMPOSE) down -v
	$(COMPOSE) build --no-cache $(BUILD_ARGS) dev
