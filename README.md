# Viper Backup

Viper Backup preserves and modernizes the Windows backup automation historically
run from `D:\Backup`.

The repository currently contains two layers:

1. **Legacy baseline** — the original batch files remain operational and are the
   scripts used by the existing scheduled task.
2. **Modern planner** — a PowerShell 5.1-compatible, configuration-driven engine
   being developed beside the legacy scripts. It is plan-only by default and is
   not yet connected to Task Scheduler.

## Safety status

> The scheduled task still runs the unchanged `DoBackup.bat`. No production
> cutover has occurred.

The legacy scripts use `robocopy /MIR`, which can delete destination content.
They do not validate drive labels or correctly propagate Robocopy failure exit
codes. Use them only with the same caution as before; do not infer success from
an ending `Backup Complete` line.

The modern engine is designed to:

- default to Robocopy list-only (`/L`) planning
- require explicit execution and a second explicit deletion opt-in
- verify destination volume identity before copying
- treat Robocopy codes 0–7 as nonfatal results and 8+ as failures
- keep machine-specific plans, logs, manifests, and credentials out of Git
- generate one run directory containing structured summary and per-job logs
- avoid one oversized command line by executing each configured job separately

See [Safety](docs/SAFETY.md), [Audit](docs/BACKUP-AUDIT.md), and
[Migration](docs/MIGRATION.md).

## Automation roles

### Daily aggregation

`DoBackup.bat` gathers selected local and network-machine data onto the external
`D:` volume, then mirrors `D:` to the external `K:` volume. Historically:

- GT, MB, and HS are the most active network machines
- YA is occasional
- NI, EV, XG, and ZG are retained historical/rare-use variants

Availability is not health. An offline optional machine should become a clearly
reported `Skipped` job, while a required source must fail the run.

### USB utilities

`USB*.bat` scripts are manual, capacity-specific exports to smaller USB drives
or occasional external mirrors. They are not the authoritative daily backup
plan. Their scope varies intentionally (backup folders, media, music, pictures,
server data, or broad mirrors).

### Media distribution

`DoMedia*.bat` scripts distribute selected media/setup folders from `D:` to
other machines. They are replication jobs, not independent backup versions.

## Repository boundaries

Tracked:

- scripts and PowerShell source
- public plan examples
- tests and CI
- architecture, safety, restore, and migration documentation

Ignored:

- `Backup*.log` and new runtime logs
- machine-bound scheduled-task XML exports
- local plans, drive identifiers, credentials, and manifests
- backup payloads

The GitHub repository is public. Never commit passwords, tokens, private keys,
volume serials, user SIDs, or reports containing personal file paths.

## Open the workspace

Open `viper-backup.code-workspace` in VS Code. The recommended extension is
Microsoft PowerShell.

## Modern planner quick start

After the engine commit, copy `config/backup-plan.example.psd1` to the ignored
`local/backup-plan.psd1`, customize it, then run a plan:

```powershell
.\scripts\Invoke-ViperBackup.ps1 -PlanPath .\local\backup-plan.psd1
```

That command is list-only by default. Execution will require `-Execute`.
Mirror jobs additionally require `-AllowDelete` and plan-level authorization.

## Current backup coverage guidance

The broad legacy `Users` mirror captures common profile folders but deliberately
excludes all `AppData`, Google Drive, and `.vscode` on key machines. Selective
modern coverage should consider:

- VS Code user settings, snippets, profiles, and keybindings
- Windows Terminal settings
- browser bookmarks/profile state when not already account-synchronized
- email archives and local-only mail stores, if present
- game saves and application-specific state
- PowerShell profiles and local scripts
- SSH/GPG material only into an encrypted, access-controlled backup
- installed-application and configuration inventories
- OneDrive/Google Drive files only after confirming local hydration

Cloud synchronization is useful redundancy, but it is not a versioned offline
backup and online-only placeholders are not backed-up file content.

## Validation policy

Development tests use temporary directories and mocked/fake Robocopy outcomes.
Until migration reaches an approved parallel-validation phase, do not run the
modern engine with `-Execute` against production paths and do not change the
scheduled task.
