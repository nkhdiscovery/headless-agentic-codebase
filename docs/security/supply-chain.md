# Supply chain security

How we keep dependencies and build artefacts safe.

## Dependency management

- Lock files committed: `package-lock.json` / `poetry.lock` / `Cargo.lock` etc.
- New dependencies require justification in commit message and an ADR if they touch security-sensitive paths.
- Dependabot enabled for weekly updates, grouped per ecosystem.

## Auditing

- `pip-audit` / `npm audit` / `cargo audit` run in CI on every PR.
- High/critical CVEs block merge until addressed or explicitly accepted.

## Build provenance

<!-- Once you ship binaries, add details here:
- Reproducible builds, if applicable
- Signed releases (cosign, gpg)
- SBOM generation (CycloneDX, SPDX)
- Where artefacts are published from (which CI job, which environment)
-->

## Container images

<!-- If you ship container images:
- Base image policy (e.g. only official slim images)
- Image scanning (trivy in CI)
- Signing (cosign keyless or kms-backed)
-->

## Secrets management

- Secrets never in code or config files committed to the repo.
- `.env` is gitignored; `.env.example` lists required vars.
- Production secrets in a managed secret store — see `docs/decisions/`.
