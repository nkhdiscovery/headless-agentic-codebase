# Pull Request

## What this does
<!-- One paragraph, plain English. -->

## Issue / deliverable
<!-- Refs #N -->

## ADRs referenced or introduced

## Checklist
- [ ] `make ci` passes locally (exit 0)
- [ ] Local `make ci` output posted as a PR comment listing the suites that ran
- [ ] Tests added or updated
- [ ] No secrets, API keys, or personal data in diff
- [ ] Docs updated if behaviour or architecture changed

## Local test output

The agent posts the captured `make ci` output as a separate PR comment after
every run (see `docs/unattended-rules.md` → "Posting local test output to
the PR"). The local result is the merge gate — GitHub Actions is opt-in and
human-only in this template (see `.github/workflows/README.md` for the
billing rationale).

## Agent attribution
<!-- If Claude Code wrote significant portions, say so. -->

## Risk / blast radius
<!-- "Touches core module" vs "Internal to X module only" -->
