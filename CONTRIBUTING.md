# Contributing

Thanks for contributing to `viper-backup`.

## Workflow

1. Create a branch from `main`.
2. Read `docs/SAFETY.md` before changing copy behavior.
3. Keep changes focused and reviewable.
4. Add or update tests whenever behavior changes.
5. Run list-only validation; never use production backup paths in tests.
6. Ensure CI is green before opening a pull request.

## Commit guidance

- Use descriptive conventional commits such as `feat(engine):`, `fix(safety):`,
  `test(plans):`, and `docs:`.
- Preserve the legacy baseline in Git history; do not rewrite it casually.
- Separate behavior changes from documentation-only changes where practical.

## Safety requirements

- Planning/list-only behavior must remain the default.
- Execution requires explicit operator intent.
- Deletion requires a separate explicit opt-in and verified destination identity.
- Required missing sources fail closed.
- Optional offline sources are reported as skipped, never silently successful.
- Robocopy exit codes must be captured immediately; 8+ is failure.
- No plaintext credentials, private keys, user SIDs, volume serials, or personal
  paths may enter the public repository.
- Tests must use temporary fixtures and may not touch real backup drives, network
  shares, cloud roots, or Task Scheduler.

## Documentation

Keep `README.md`, `docs/SAFETY.md`, and `docs/MIGRATION.md` aligned with actual
behavior. Do not document a safety guarantee before tests enforce it.
