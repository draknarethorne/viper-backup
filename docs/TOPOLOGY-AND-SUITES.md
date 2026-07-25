# Topology and Backup Suites

## Purpose

Viper Backup separates **backup acquisition**, **second-copy protection**,
**historical snapshots**, and **distribution**. They may run from one scheduled
suite later, but they have different recovery value and failure rules.

## Storage roles

| Location | Role | Notes |
| --- | --- | --- |
| `D:\Backup` | Control plane | Repository, legacy scripts, modern engine, tests, and local runtime state |
| `D:\Backup_Folders` | Selected-folder aggregation | Application, project, and game trees collected from a machine's primary drive |
| Other top-level `D:` categories | Aggregation/data hub | User, family, server, archive, media, mobile, music, and setup collections |
| `K:` second-copy root | Local second copy | Protects against failure of `D:`; not off-site and not independent history |
| Household machines | Sources and distribution targets | Some data is acquired from them; large collections are also published to them |

`D:\Backup` and `D:\Backup_Folders` must never be treated as interchangeable.
The first is the automation repository; the second is one data category. The
whole eligible `D:` data hub is the source of the broad second copy.

## Machine roles

| Role | Intended use |
| --- | --- |
| Current workstation | Required source for important local files, selected application trees, cloud-local content, and game state |
| Home server | Regular server/user-data source and limited distribution target |
| Family workstation | Regular family-data source and selective media replica |
| Older gaming laptop | Regular user/game-data source and broad distribution target; optional TAKP portable-state target |
| Occasional/historical machines | Explicit on-demand acquisition only |

A reachable machine is not automatically current. Regular network machines may
be skipped when offline during migration, but summaries must make the skipped
source visible. A future freshness ledger should report how old the last
successful acquisition is before a second copy is described as current.

## Suite model

### 1. Daily acquisition

Purpose: collect current, important, non-cloud and cloud-local data into `D:`.

Suggested contents:

- required local user data and selected application/project roots
- full local TAKP backup in `Update` mode during migration
- dedicated cloud-aware OneDrive snapshot or update job
- regular network-machine acquisition, visibly skipped when unavailable
- home-server active data

Rules:

- no distribution jobs
- no USB jobs
- no historical machines by default
- no broad deletion during the initial migration
- cloud roots are dedicated jobs, not hidden inside a broad user-profile copy

Public starting point: `config/daily-acquisition.example.psd1`.

### 2. Daily second copy

Purpose: copy the eligible `D:` data hub onto the verified `K:` device.

Initial migration mode is `Update`, preserving destination-only data. The long-
term exact-image option is `Mirror`, but only after list-only parity, restore
validation, capacity review, and explicit deletion authorization.

The second-copy step runs only after required acquisition succeeds. If a regular
network machine was unavailable, the second copy contains the previous `D:`
version for that machine and must not be described as freshly acquired.

Public starting point: `config/second-copy.example.psd1`.

### 3. Weekly and on-demand snapshots

Purpose: retain timestamped versions of small, high-value, frequently changing
sets where accidental overwrite or deletion matters.

Good candidates:

- portable TAKP character/UI/timer configuration
- OneDrive content that is confirmed fully local
- selected application settings and exports
- small source-code/configuration trees not already versioned elsewhere

Snapshots are not appropriate for the entire large `D:` data hub. Payload
snapshot retention is separate from run-log retention and must be capacity-
limited before unattended scheduling.

Public starting points:

- `config/critical-snapshots.example.psd1`
- `config/snapshot-plan.example.psd1`

### 4. Distribution

Purpose: publish large local collections—music, mobile, media, setup files, and
similar material—to household machines acting as NAS-style replicas.

Distribution is not backup acquisition and is not independent version history.
It must use one-way authoritative sources and per-target plans. A destination
machine being offline may skip that target only when the job explicitly sets
`DestinationRequired = $false`; wrong destination identity still fails closed.

Public starting point: `config/distribution.example.psd1`.

### 5. On-demand exports

USB and historical-machine operations remain separately invoked plans:

- capacity-specific USB exports
- deletion-gated USB mirrors
- occasional/historical machine acquisition
- isolated restore validation

They do not belong in the default daily suite.

## Proposed schedule

| Frequency | Workflow | Initial mode |
| --- | --- | --- |
| Daily | Local + regular-machine acquisition | `Update` |
| Daily, after acquisition | `D:` data hub to verified `K:` | `Update` during migration |
| Daily or weekly | Fully local OneDrive critical snapshot | `Snapshot` |
| Weekly | TAKP portable configuration snapshot | `Snapshot` |
| Weekly or on demand | Media/mobile/music/setup distribution | `Update` |
| On demand | TAKP portable state to gaming laptop | `Update`, one-way |
| On demand | USB exports and historical machines | Plan-specific |

## Cutover principle

The existing scheduled `DoBackup.bat` remains authoritative until every modern
plan has:

1. a validated local configuration;
2. list-only output compared with the equivalent legacy script;
3. required/optional source policy confirmed;
4. destination identity verified;
5. an isolated restore test;
6. an operator-reviewed schedule and failure policy.

The engine now supports ordered stages inside one plan. The eventual scheduled
entry point can use a staged daily plan so Stage 1 acquisition/snapshots gate
Stage 2 second copy while preserving bounded parallelism inside each stage.
`config/daily-suite.example.psd1` demonstrates that structure. Keep the legacy
scheduled entry point unchanged until the local version has list-only parity
and restore evidence.
