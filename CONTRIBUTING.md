# Contributing

Thanks for contributing to `viper-backup`.

## Workflow

1. Create a branch from `main`.
2. Read `docs/SAFETY.md` before changing copy behavior.
3. Install the project-managed quality tools and Git hooks.
4. Keep changes focused and reviewable.
5. Add or update tests whenever behavior changes.
6. Run list-only validation; never use production backup paths in tests.
7. Ensure CI is green before opening a pull request.

## Development setup

The backup engine remains Windows PowerShell 5.1 compatible and does not need
Python at runtime. Python 3.12+ is used only to provide a consistent pre-commit
runner across projects:

```powershell
python -m pip install -e ".[dev]"
pre-commit install --install-hooks
Install-Module PSScriptAnalyzer -RequiredVersion 1.25.0 -Scope CurrentUser
```

`pyproject.toml` owns development-tool versions and records the PowerShell,
PSScriptAnalyzer, and local Pester baselines. `.pre-commit-config.yaml` owns
hook execution, while `PSScriptAnalyzerSettings.psd1` contains the enforced
PowerShell rules.

## Quality contract

Run the same fast repository gates as CI:

```powershell
pre-commit run --all-files --show-diff-on-failure
.\scripts\Invoke-QualityChecks.ps1
```

Run the complete safety suite before pushing:

```powershell
.\tests\Run-Tests.ps1
```

Commit-time checks cover file hygiene, YAML validity, and PowerShell analysis.
Pre-push runs all Pester tests. CI repeats every gate from a clean environment,
validates the module manifest, and rejects tracked private/runtime state.

The initial analyzer policy emphasizes parser safety, PowerShell 5.1 syntax,
credential handling, command aliases, and invocation hazards. Broader style
rules should be adopted incrementally after existing findings are remediated,
not hidden with ad hoc inline suppressions.

Quality commands must never execute production backups, Robocopy without `/L`,
cloud hydration, Task Scheduler changes, or real network/share probes.

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
