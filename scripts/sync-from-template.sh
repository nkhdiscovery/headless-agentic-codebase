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
echo "==> Reviewing files that may have local customisations..."

APPLIED=()
CONFLICTS=()
UNCHANGED=()

for f in "${REVIEW_FILES[@]}"; do
    # Skip if file doesn't exist in template
    if ! git cat-file -e "$TEMPLATE_REMOTE_NAME/main:$f" 2>/dev/null; then
        continue
    fi

    THEIRS_TMP=$(mktemp)
    git show "$TEMPLATE_REMOTE_NAME/main:$f" > "$THEIRS_TMP"

    # If we don't have the file locally, just take theirs
    if [ ! -f "$f" ]; then
        mkdir -p "$(dirname "$f")"
        cp "$THEIRS_TMP" "$f"
        rm "$THEIRS_TMP"
        APPLIED+=("$f")
        echo "  added:     $f (didn't exist locally)"
        continue
    fi

    # If our version is identical to template, nothing to do
    if cmp -s "$f" "$THEIRS_TMP"; then
        rm "$THEIRS_TMP"
        UNCHANGED+=("$f")
        continue
    fi

    # Files differ. Try 3-way merge only if we have a saved baseline.
    if [ ! -f "$BASE_DIR/$f" ]; then
        # No baseline — can't safely merge. Surface as conflict.
        # Show both versions so user can decide.
        echo "  REVIEW:    $f (no baseline — manually compare with template)"
        echo "             Your version: $f"
        echo "             Template:     git show $TEMPLATE_REMOTE_NAME/main:$f"
        echo "             To adopt template: git checkout $TEMPLATE_REMOTE_NAME/main -- $f"
        
        # Save template as baseline for next time
        mkdir -p "$(dirname "$BASE_DIR/$f")"
        cp "$THEIRS_TMP" "$BASE_DIR/$f"
        rm "$THEIRS_TMP"
        CONFLICTS+=("$f")
        continue
    fi

    # We have a baseline. Check if baseline == template (suspicious).
    BASE_TMP=$(mktemp)
    cp "$BASE_DIR/$f" "$BASE_TMP"
    
    # If baseline is identical to template, but yours differs, this is a stale
    # local version that got left behind in an earlier sync. Don't 3-way merge
    # (it'll silently keep stale), force to REVIEW instead.
    if cmp -s "$BASE_TMP" "$THEIRS_TMP"; then
        echo "  REVIEW:    $f (yours differs from template; baseline already up-to-date)"
        echo "             Compare:       git diff $TEMPLATE_REMOTE_NAME/main -- $f"
        echo "             Adopt template: git checkout $TEMPLATE_REMOTE_NAME/main -- $f"
        rm "$BASE_TMP" "$THEIRS_TMP"
        CONFLICTS+=("$f")
        continue
    fi

    # Real 3-way merge: base ≠ template, both changed since last sync.
    MINE_TMP=$(mktemp)
    cp "$f" "$MINE_TMP"

    if git merge-file -L "yours" -L "baseline" -L "template" \
            "$MINE_TMP" "$BASE_TMP" "$THEIRS_TMP" 2>/dev/null; then
        # Clean merge
        cp "$MINE_TMP" "$f"
        # Update baseline to new template version
        mkdir -p "$(dirname "$BASE_DIR/$f")"
        cp "$THEIRS_TMP" "$BASE_DIR/$f"
        APPLIED+=("$f")
        echo "  merged:    $f (clean)"
    else
        # Conflict — apply the conflicted version so user can resolve
        cp "$MINE_TMP" "$f"
        CONFLICTS+=("$f")
        echo "  CONFLICT:  $f (resolve conflict markers, then re-run sync)"
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
echo "Files applied:         ${#APPLIED[@]}"
echo "Unchanged:             ${#UNCHANGED[@]}"
echo "Needs review/resolve:  ${#CONFLICTS[@]}"
echo ""

if [ "${#APPLIED[@]}" -gt 0 ]; then
    echo "Changes applied (verify with 'git diff HEAD'):"
    for f in "${APPLIED[@]}"; do
        lines=$(git diff HEAD -- "$f" 2>/dev/null | grep -c "^+" || echo "?")
        echo "  $f (+$lines lines)"
    done
    echo ""
fi

if [ "${#CONFLICTS[@]}" -gt 0 ]; then
    echo "Files needing your attention:"
    for f in "${CONFLICTS[@]}"; do
        if grep -q "^<<<<<<< yours" "$f" 2>/dev/null; then
            echo "  $f (CONFLICT — resolve markers, then re-run sync)"
        else
            echo "  $f (REVIEW — yours differs from template)"
            echo "             Compare:       git diff $TEMPLATE_REMOTE_NAME/main -- $f"
            echo "             Adopt template: git checkout $TEMPLATE_REMOTE_NAME/main -- $f"
        fi
    done
    echo ""
    echo "Conflict markers look like:"
    echo "    <<<<<<< yours"
    echo "    your customised line"
    echo "    ||||||| baseline"
    echo "    the line when you last synced"
    echo "    ======="
    echo "    the line in template now"
    echo "    >>>>>>> template"
    echo ""
    echo "Resolve markers, then re-run sync or commit directly."
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
