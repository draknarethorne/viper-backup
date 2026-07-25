# Viper Backup - Copilot Instructions

## Project Overview

**viper-backup** is a Windows-focused, safety-first backup orchestrator that is
modernizing legacy Batch/Robocopy automation with a lightweight PowerShell 5.1
engine.

Primary goals:

- preserve the existing scheduled backup until a tested cutover
- plan every copy before execution
- verify destination identity before writes
- prevent accidental deletion propagation
- distinguish required failures from optional offline machines
- produce deterministic local run summaries and logs
- keep credentials, personal paths, machine-local plans, and runtime evidence
  out of the public repository

Authoritative safety guidance:

- `docs/SAFETY.md`
- `docs/BACKUP-AUDIT.md`
- `docs/MIGRATION.md`

## Runtime Baseline

- Windows PowerShell 5.1 is the compatibility floor.
- PowerShell plans use `.psd1` data files.
- Pester 3.4 compatibility is required locally; CI may also validate on modern
  Pester.
- Robocopy is the underlying copy tool.

## Non-Negotiable Safety Rules

1. Plan/list-only mode is the default.
2. Never run production backup jobs, Robocopy without `/L`, mirrors, or scheduled
   task changes during development unless the user explicitly authorizes a
   controlled execution.
3. `Update` is the default copy mode and must not delete destination-only files.
4. `Mirror` requires plan-level `AllowDelete`, invocation-level `-AllowDelete`,
   and verified destination identity.
5. A drive letter alone is not identity; validate expected volume label and any
   local-only serial when supplied.
6. Required missing sources fail. Optional unavailable network machines are
   explicitly skipped and reported.
7. Capture `$LASTEXITCODE` immediately after Robocopy. Codes 0-7 are nonfatal;
   codes 8+ fail.
8. Never auto-hydrate cloud files or treat placeholders as backed-up content.
9. Never commit `local/`, `state/`, logs, task XML exports, credentials, user
   SIDs, volume serials, or personal backup inventories.
10. Tests use temporary directories and fake/mocked process outcomes only.

## Architecture

```text
config/                 Public fictional plan examples
scripts/                User-facing entry points
src/PSViperBackup/      Engine and safety functions
tests/                  Pester unit/integration tests
docs/                   Audit, safety, migration, restore guidance
local/                  Ignored machine-local plans
state/                   Ignored run logs/manifests/summaries
*.bat / *.CMD           Preserved legacy baseline
```

Keep configuration parsing, validation, process invocation, result
classification, and report rendering separate and testable.

## Legacy Policy

The scheduled task still runs `DoBackup.bat`. Do not edit legacy scripts or
redirect Task Scheduler during planner development. If legacy cleanup is later
needed, retain the exact baseline through commit `941b4e5` and document behavior
changes explicitly.

Machine activity context:

- GT, MB, and HS are regular network sources.
- YA is occasional.
- NI, EV, XG, and ZG are historical/rare and should not be enabled by default.
- USB scripts are manual capacity-specific exports, not the daily plan.
- media scripts distribute data and are not independent backup versions.

## Engineering Workflow

1. Read relevant safety/docs/source first.
2. Update the todo list for multi-step work.
3. Add a failing regression test before behavior changes when practical.
4. Make the smallest targeted implementation.
5. Run parser diagnostics and Pester tests.
6. Run only list-only fixtures, never production copies.
7. Review `git diff --check`, secret patterns, and ignored runtime state.
8. Commit and push in focused increments when requested.

## Documentation Style

Match the Viper/Thorne public-repository style:

- concise branded title and tagline
- task-oriented sections and quick links
- status and structure tables
- explicit safety callouts
- implementation-grounded claims only
- UTF-8 Markdown with clear, actionable language
