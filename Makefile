# Generic agent Makefile.
# All commands route through Docker so dev matches CI exactly.
# Customise test/lint/format targets per language.

.PHONY: help build shell test lint format ci daemon \
        agent-start agent-stop agent-logs clean fresh

# Project-scoped compose — derives a unique name from the repo directory so
# multiple agent instances on the same host don't collide on image, container,
# network, or volume names. Override with PROJECT_NAME=foo if needed.
PROJECT_NAME ?= $(notdir $(CURDIR))
COMPOSE := docker compose -f docker/docker-compose.yml -p $(PROJECT_NAME)
export COMPOSE_PROJECT_NAME = $(PROJECT_NAME)

help:  ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build:  ## Build the dev image
	$(COMPOSE) build dev

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

# --- Housekeeping ---
clean:  ## Remove build artefacts
	find . -type d -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name node_modules -prune -exec rm -rf {} + 2>/dev/null || true
	rm -rf dist build *.egg-info .pytest_cache .mypy_cache .ruff_cache

fresh: clean  ## Full rebuild
	$(COMPOSE) down -v
	$(COMPOSE) build --no-cache dev
