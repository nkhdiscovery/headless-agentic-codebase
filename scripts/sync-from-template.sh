#!/usr/bin/env bash
# scripts/sync-from-template.sh
#
# Pull infrastructure updates from the headless-agentic-codebase template
# into the current project repo, surfacing conflicts where your customisations
# have diverged from the template.
#
# Strategy:
# - SAFE files: clean overwrite from template (pure infrastructure, no project content).
# - REVIEW files: 3-way merge using git merge-file. If your version diverged from
#   the template, you get standard <<<<<<< / ======= / >>>>>>> conflict markers
#   in the file. Resolve them with your editor or `git mergetool`.
#
# The 3-way merge needs three versions:
#   BASE   = the template version you last synced from (stored in .template-base/)
#   MINE   = your current file (with your customisations)
#   THEIRS = the latest template version
#
# First run: there's no BASE, so we treat the template's current main as base.
# After successful sync: we save the new template version into .template-base/
# so the next sync gets a real 3-way merge.

set -euo pipefail

TEMPLATE_REMOTE_URL="https://github.com/nkhdiscovery/headless-agentic-codebase.git"
TEMPLATE_REMOTE_NAME="template"
BASE_DIR=".template-base"

# --- Files to sync ---------------------------------------------------------

# Safe to overwrite: pure infrastructure, no project content
SAFE_FILES=(
    scripts/agent-cost.sh
    scripts/docs-gate.sh
    agents/claude.sh
    agents/gemini.sh
    agents/codex.sh
    agents/junie.sh
    agents/custom.sh
    BOOTSTRAP_PROMPT.md
    STACK_PICKER_PROMPT.md
    STACKS_AND_ADDONS.md
    REMOTE_SETUP.md
    docs/codebase/template.md
)

# Need 3-way merge: project will likely have local changes
REVIEW_FILES=(
    agent.config
    Makefile
    scripts/launch-agent.sh
    docs/unattended-rules.md
    GETTING_STARTED.md
)

# Project-only files: never sync from template (project has authoritative version)
# Listed here only so we know not to touch them.
PROJECT_ONLY_FILES=(
    CLAUDE.md
    README.md
    SECURITY.md
    .github/CODEOWNERS
    docker/Dockerfile.dev
    docker/docker-compose.yml
    docs/product.md
    docs/architecture.md
    docs/phases.md
    docs/codebase.md
)

# --- Setup -----------------------------------------------------------------

# Ensure template remote exists
if ! git remote get-url "$TEMPLATE_REMOTE_NAME" >/dev/null 2>&1; then
    echo "==> Adding template remote: $TEMPLATE_REMOTE_URL"
    git remote add "$TEMPLATE_REMOTE_NAME" "$TEMPLATE_REMOTE_URL"
fi

echo "==> Fetching latest from template..."
git fetch "$TEMPLATE_REMOTE_NAME" --quiet

# Working tree must be clean to avoid mixing your in-flight changes with sync results
if ! git diff --quiet HEAD -- 2>/dev/null; then
    echo "ERROR: working tree has uncommitted changes."
    echo "Commit or stash first, then re-run."
    git status --short
    exit 1
fi

mkdir -p "$BASE_DIR"

# --- Pull safe files (clean overwrite) -------------------------------------

echo ""
echo "==> Pulling safe files (clean overwrite)..."
for f in "${SAFE_FILES[@]}"; do
    if git cat-file -e "$TEMPLATE_REMOTE_NAME/main:$f" 2>/dev/null; then
        mkdir -p "$(dirname "$f")"
        git show "$TEMPLATE_REMOTE_NAME/main:$f" > "$f"
        # Track new template content as the new base for next sync
        mkdir -p "$(dirname "$BASE_DIR/$f")"
        cp "$f" "$BASE_DIR/$f"
        echo "  pulled:    $f"
    fi
done

# Make shell scripts executable
chmod +x scripts/*.sh agents/*.sh 2>/dev/null || true

# --- 3-way merge review files ---------------------------------------------

echo ""
echo "==> 3-way merging review files..."

CLEAN_MERGES=()
CONFLICTS=()
NO_CHANGE=()

for f in "${REVIEW_FILES[@]}"; do
    # Skip if file doesn't exist in template (template doesn't have it for some reason)
    if ! git cat-file -e "$TEMPLATE_REMOTE_NAME/main:$f" 2>/dev/null; then
        continue
    fi

    THEIRS_TMP=$(mktemp)
    git show "$TEMPLATE_REMOTE_NAME/main:$f" > "$THEIRS_TMP"

    # If we don't have the file at all yet, just take theirs
    if [ ! -f "$f" ]; then
        mkdir -p "$(dirname "$f")"
        cp "$THEIRS_TMP" "$f"
        mkdir -p "$(dirname "$BASE_DIR/$f")"
        cp "$THEIRS_TMP" "$BASE_DIR/$f"
        rm "$THEIRS_TMP"
        CLEAN_MERGES+=("$f")
        echo "  added:     $f (didn't exist locally)"
        continue
    fi

    # If their version is identical to ours, nothing to do
    if cmp -s "$f" "$THEIRS_TMP"; then
        # Update base anyway so we have it for next sync
        mkdir -p "$(dirname "$BASE_DIR/$f")"
        cp "$THEIRS_TMP" "$BASE_DIR/$f"
        rm "$THEIRS_TMP"
        NO_CHANGE+=("$f")
        continue
    fi

    # 3-way merge: base = last synced version from template (or theirs if no base yet)
    BASE_TMP=$(mktemp)
    if [ -f "$BASE_DIR/$f" ]; then
        cp "$BASE_DIR/$f" "$BASE_TMP"
    else
        # First sync — use theirs as the implicit base.
        # This means 3-way merge sees no template-side changes, so any local
        # divergence stays as-is. Conservative: nothing changes on first pass
        # for review files. (Re-run after committing to get real merges.)
        cp "$THEIRS_TMP" "$BASE_TMP"
    fi

    # `git merge-file` does a 3-way merge in place on the first arg.
    # Returns 0 if clean, >0 if conflicts.
    MINE_TMP=$(mktemp)
    cp "$f" "$MINE_TMP"

    if git merge-file -L "yours" -L "common-ancestor" -L "template" \
            "$MINE_TMP" "$BASE_TMP" "$THEIRS_TMP" 2>/dev/null; then
        # Clean merge. Apply.
        cp "$MINE_TMP" "$f"
        # Update base to the new theirs
        mkdir -p "$(dirname "$BASE_DIR/$f")"
        cp "$THEIRS_TMP" "$BASE_DIR/$f"
        CLEAN_MERGES+=("$f")
        echo "  merged:    $f (clean)"
    else
        # Conflicts. Apply the conflicted version so the user can edit.
        cp "$MINE_TMP" "$f"
        # Do NOT update base yet — base updates only after conflicts resolved + committed.
        CONFLICTS+=("$f")
        echo "  CONFLICT:  $f"
    fi

    rm -f "$THEIRS_TMP" "$BASE_TMP" "$MINE_TMP"
done

# Make scripts executable in case launch-agent.sh got merged
chmod +x scripts/*.sh agents/*.sh 2>/dev/null || true

# --- Ensure labels exist ---------------------------------------------------

if command -v gh >/dev/null 2>&1; then
    echo ""
    echo "==> Ensuring template labels exist..."
    gh label create high-cost --color e99695 --force >/dev/null 2>&1 || true
    gh label create human-only-merge --color 000000 --force >/dev/null 2>&1 || true
    gh label create docs-exempt --color c5def5 --force >/dev/null 2>&1 || true
    echo "  labels checked: high-cost, human-only-merge, docs-exempt"
fi

# --- Summary ---------------------------------------------------------------

echo ""
echo "================================================================"
echo "Sync summary"
echo "================================================================"
echo ""
echo "Safe files updated:    ${#SAFE_FILES[@]}"
echo "Clean merges:          ${#CLEAN_MERGES[@]}"
echo "No changes needed:     ${#NO_CHANGE[@]}"
echo "Conflicts to resolve:  ${#CONFLICTS[@]}"
echo ""

if [ "${#CONFLICTS[@]}" -gt 0 ]; then
    echo "Files with conflict markers — open and resolve:"
    for f in "${CONFLICTS[@]}"; do
        echo "  $f"
    done
    echo ""
    echo "Conflict markers look like:"
    echo "    <<<<<<< yours"
    echo "    your customised line"
    echo "    ||||||| common-ancestor"
    echo "    the line as it was when you last synced"
    echo "    ======="
    echo "    the line as it is in the template now"
    echo "    >>>>>>> template"
    echo ""
    echo "Resolve, save, then run this script again to update the template-base"
    echo "for next time. Or commit your resolution directly."
    echo ""
    echo "Tip: 'git mergetool' or VS Code's merge editor can help."
    echo ""
fi

echo "Next steps:"
echo "  1. Review pulled files: git diff HEAD"
echo "  2. Resolve any conflicts above"
echo "  3. Test: make fresh && make agent-start"
echo "  4. Commit:"
echo "       git add ."
echo "       git commit -m 'chore: sync infrastructure from template'"
echo "       git push"
echo ""

# Add base dir to gitignore if not already there
if [ -f .gitignore ] && ! grep -qFx "$BASE_DIR/" .gitignore; then
    echo "$BASE_DIR/" >> .gitignore
    echo "==> Added $BASE_DIR/ to .gitignore"
fi
