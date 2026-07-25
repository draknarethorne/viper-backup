# Migration Plan

The migration deliberately keeps `DoBackup.bat` as the scheduled production
entry point until plan parity and restore tests are complete.

## Phase 0 — baseline (complete)

- Initialize Git at `D:\Backup`.
- Ignore logs, scheduled-task XML, credentials, and local runtime state.
- Commit the existing scripts without cleanup.
- Push the immutable baseline to `draknarethorne/viper-backup`.

Baseline commit: `941b4e5`.

## Phase 1 — planner beside legacy

- Add PowerShell 5.1-compatible module and tests.
- Add public fictional plan examples.
- Default every invocation to list-only.
- Validate labels, source availability, job modes, and Robocopy codes.
- Keep Task Scheduler unchanged.

## Phase 2 — local plan reconstruction

Create ignored `local\backup-plan.psd1` from the legacy call graph:

- ST local projects and user data → `D:` aggregation
- GT, MB, HS as regular network sources
- YA as optional/occasional
- historical machines excluded from the daily plan
- `D:` → `K:` as a separate second-copy stage
- USB scripts represented as manual plans, not daily jobs
- media distribution represented separately from backup acquisition

Run validation and list-only plans. Compare every source, destination, exclusion,
and expected deletion with the legacy scripts.

## Phase 3 — parallel evidence

Continue running the legacy scheduled task. Run the modern planner manually in
list-only mode after selected legacy runs and compare:

- jobs attempted/skipped
- source availability
- planned file/byte changes
- exclusions
- Robocopy result codes
- run duration and log completeness

No production writes occur from the new engine in this phase.

## Phase 4 — controlled update-mode pilot

After backups are current and the known C: storage incident is resolved, select
a noncritical temporary test source and destination. Validate:

1. initial copy
2. changed file copy
3. destination-only file preservation in Update mode
4. intentional deletion only with all Mirror gates
5. unavailable source fail-closed behavior
6. wrong-label destination rejection
7. isolated restore

Then pilot one low-risk real Update job manually.

## Phase 5 — scheduled cutover

Only after documented parity and restore validation:

- export the current scheduled task to ignored local state
- create a new task rather than overwriting the old one initially
- run PowerShell with `-NoProfile -NonInteractive`
- use a local plan and explicit `-Execute`
- retain the legacy task disabled for rollback
- monitor summaries daily during the acceptance period

Mirror authorization should not be placed in the initial scheduled invocation.

## Phase 6 — retention and off-site copy

Add versioned snapshots or another retention mechanism for critical files.
Evaluate an encrypted off-site target. Cloud sync alone is not sufficient
because it can propagate deletion and ransomware changes.

## Rollback

Until cutover, rollback is simply not invoking the modern engine. After cutover,
disable the new task and re-enable the preserved legacy task definition. Never
run both write-capable jobs concurrently.
