# Release Checklist

Viper Backup releases must preserve plan-only defaults and must never package
machine-local plans, runtime evidence, credentials, or destination identifiers.

## Current release status

Public packaging is deferred until the modern planner has completed controlled
parallel validation and representative restore drills. Until then, `main` and
CI are the authoritative development artifacts.

The age of the preserved legacy Batch scripts does not determine the modern
engine's semantic version. Use a prerelease such as `v0.5.0-beta.1` until
production cutover and rollback have been exercised.

## Before tagging

- Confirm `main` is clean and synchronized with `origin/main`.
- Run all pre-commit gates, manifest validation, and Pester tests.
- Confirm plan/list-only behavior remains the default.
- Confirm `Update` remains non-deleting.
- Confirm `Mirror` still requires both delete authorizations and destination
  identity verification.
- Complete and record representative restore tests.
- Review changes against `docs/SAFETY.md` and `docs/MIGRATION.md`.
- Synchronize the tag with `ModuleVersion` in
  `src/PSViperBackup/PSViperBackup.psd1`.

## Future package allowlist

A modern planner ZIP may include only:

- `src/PSViperBackup/`
- supported entry points under `scripts/`
- fictional examples under `config/`
- public documentation
- `README.md`, `CONTRIBUTING.md`, `SECURITY.md`, and `LICENSE`

It must exclude:

- `local/` and `state/`
- logs, summaries, manifests, and task XML exports
- credentials, user SIDs, volume serials, and personal paths
- backup payloads and cloud placeholders
- the legacy Batch corpus from the primary modern package

## Publication gate

Do not add an automatic release workflow until the package allowlist has an
automated test and restore/parallel-validation evidence supports a public
preview. A release must include generated notes and a SHA-256 checksum.
