# 🐍 viper-backup

## Plan safely • Copy deliberately • Prove recovery

Windows backup orchestration for local, network, cloud-synchronized, and
removable-media data—modernizing years of trusted batch automation without
sacrificing safety or recoverability.

[🎯 Overview](#-what-is-viper-backup) • [📊 Status](#-project-status) • [🧱 Structure](#-project-structure) • [🚀 Quick Start](#-quick-start) • [🛡️ Safety](docs/SAFETY.md) • [📝 Logs](docs/LOGGING-AND-RETENTION.md) • [♻️ Restore](docs/RESTORE-VALIDATION.md) • [🔍 Audit](docs/BACKUP-AUDIT.md) • [🗺️ Migration](docs/MIGRATION.md)

## 🎯 What is viper-backup?

`viper-backup` preserves and modernizes the Windows backup automation
historically run from `D:\Backup`.

The repository currently contains two layers:

1. **Legacy baseline** — the original batch files remain operational and are the
   scripts used by the existing scheduled task.
2. **Modern planner** — a tested PowerShell 5.1-compatible,
   configuration-driven engine beside the legacy scripts. It is plan-only by
   default and is not connected to Task Scheduler.

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
- prevent overlapping runs with an exclusive state lock
- run bounded batches with independently captured job outcomes

See [Safety](docs/SAFETY.md), [Audit](docs/BACKUP-AUDIT.md), and
[Migration](docs/MIGRATION.md).

## 📊 Project Status

| Component | Status | Notes |
| --- | --- | --- |
| Legacy baseline | ✅ Preserved | Exact scripts committed as `941b4e5` |
| Public repository | ✅ Active | Logs, task exports, local plans, and secrets ignored |
| Safety and migration docs | ✅ Complete | Audit-backed operating model |
| VS Code workspace | ✅ Ready | PowerShell, Markdown, Git, and guarded terminal defaults |
| PowerShell planner | ✅ Ready for parallel validation | Plan-only default; not connected to Task Scheduler |
| Automated tests | ✅ Active | PowerShell 5.1, safety regressions, and real temporary `/L` fixture |
| Production cutover | ⏸️ Deferred | Legacy `DoBackup.bat` remains scheduled |

## 🧱 Project Structure

```text
viper-backup/
├── .github/                    # CI, Copilot instructions, focused agents
├── config/                     # Public fictional plan examples
├── docs/                       # Audit, safety, migration, restore guidance
├── scripts/                    # User-facing PowerShell entry points
├── src/PSViperBackup/          # Lightweight PowerShell backup engine
├── tests/                      # Pester safety and behavior tests
├── Archive/                    # Historical/rare machine batch scripts
├── *.bat / *.CMD               # Preserved legacy automation
└── viper-backup.code-workspace # Configured VS Code workspace
```

Why this structure?

- ✅ Legacy behavior remains visible and recoverable in Git history
- ✅ Engine, plans, tests, documentation, and runtime state stay separate
- ✅ Public examples contain no personal paths, machine names, or drive serials
- ✅ Local plans and execution evidence remain private and Git-ignored

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

## 🚀 Quick Start

Copy `config/backup-plan.example.psd1` to the ignored
`local/backup-plan.psd1`, customize destination identity and jobs, validate it,
then run a plan:

```powershell
.\scripts\Test-ViperBackupPlan.ps1 -PlanPath .\local\backup-plan.psd1
.\scripts\Invoke-ViperBackup.ps1 -PlanPath .\local\backup-plan.psd1
```

That command is list-only by default. Execution will require `-Execute`.
Mirror jobs additionally require `-AllowDelete` and plan-level authorization.
Use `-MaxParallelJobs` to start bounded batches of independent Robocopy jobs;
the initial engine waits for the whole active batch before starting another.

### Job modes

| Mode | Destination | Destination-only entries | Best fit |
| --- | --- | --- | --- |
| `Update` | Stable | Preserved | Safe default aggregation |
| `Mirror` | Stable | Deleted | Space-efficient exact image behind dual authorization |
| `Snapshot` | Timestamped | Not applicable | Small, critical configuration/version sets |

Every invocation writes ignored `summary.json`, `summary.txt`, and one Robocopy
log per started job under `state/runs/<timestamp>/`. See
[Logging and Retention](docs/LOGGING-AND-RETENTION.md).

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

Development tests use temporary directories, mocked/fake Robocopy outcomes, and
one real Robocopy `/L` integration fixture that proves no destination is created.
Until migration reaches an approved parallel-validation phase, do not run the
modern engine with `-Execute` against production paths and do not change the
scheduled task.

## 🧪 Testing and CI

The modern engine is validated with Pester 3.4-compatible tests on Windows.
Tests use temporary paths; the integration case invokes Robocopy only with `/L`.
CI never accesses real backup volumes or network shares.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Behavior changes require tests, and any
write/delete capability requires explicit safety analysis.

## 📜 License

MIT—see [LICENSE](LICENSE).

Built with care for data that cannot be replaced.
