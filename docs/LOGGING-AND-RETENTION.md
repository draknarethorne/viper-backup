# Logging and Retention

## Naming standard

Viper Backup uses invariant, sortable timestamps:

```text
yyyyMMdd-HHmmss
```

Example: `20260725-184530`.

This format avoids locale-dependent `%DATE%` parsing, sorts chronologically as
text, and is unambiguous across machines. It is preferred over `MMddyyyy` even
though both are readable.

## Run layout

Each planner invocation creates an ignored local run directory:

```text
state/runs/20260725-184530/
├── summary.json
├── Required_user_documents.robocopy.log
└── Optional_network_machine.robocopy.log
```

The summary records plan-only versus execute mode, each job status, Robocopy
exit code, severity, and log path. Logs use one file per job so parallel jobs do
not interleave output. `MaxParallelJobs` bounds each active batch; the initial
implementation waits for that batch to finish before starting the next one.
An exclusive state lock prevents scheduled and manual runs from overlapping.

When jobs declare `Stage`, summaries record the stage for each result. All jobs
in the active stage complete before the next stage starts. This allows required
acquisition and snapshots to gate a later second-copy stage without forcing
independent acquisition jobs to run serially.

## Status vocabulary

| Status | Meaning |
| --- | --- |
| `Disabled` | Job intentionally disabled in the plan |
| `SkippedUnavailable` | Optional source was offline or absent |
| `SkippedDestinationUnavailable` | Explicitly optional destination was offline or absent |
| `Planned` | Robocopy list-only completed without a failure code |
| `Completed` | Write-capable execution completed without a failure code |
| `Failed` | Validation, identity, cloud, process, or Robocopy failure |

`Completed` means the copy command reported no failure code. It does not replace
an isolated restore test.

## Automatic trimming

Run-history cleanup is repository-scoped and keeps both:

- at least the newest `KeepLast` run directories
- any run newer than `MaxAgeDays`

Preview cleanup:

```powershell
.\scripts\Remove-ViperBackupRunHistory.ps1 -KeepLast 30 -MaxAgeDays 90
```

Apply cleanup explicitly:

```powershell
.\scripts\Remove-ViperBackupRunHistory.ps1 -KeepLast 30 -MaxAgeDays 90 -Execute
```

Cleanup refuses paths outside this repository's `state` tree. Legacy
`Backup*.log` files remain untouched until the scheduled workflow is migrated.

## Backup naming standard

Use the mode to choose naming:

- **Update:** stable destination path; destination-only files remain
- **Mirror:** stable destination path; exact image, deletion-gated
- **Snapshot:** timestamp appended to destination path

For small configuration sets, a descriptive prefix may precede the timestamp:

```text
TAKP-ini-20260725-184530
```

Do not timestamp large image copies merely for naming consistency when capacity
cannot support duplication. Use a verified Mirror plus a separate versioned tier
for only the irreplaceable smaller subset.
