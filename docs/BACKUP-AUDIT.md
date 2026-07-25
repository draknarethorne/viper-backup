# Legacy Backup Audit

Audit date: 2026-07-25

## Scope

The audit reviewed script/configuration metadata, aggregate log errors, volume
identity, top-level backup layout, and presence of common high-value locations.
It did not read personal backup payload contents, run a backup, or modify the
scheduled task.

## Topology

```text
Local and network machines
          |
          v
D:  My Data (aggregation copy)
          |
          v
K:  My Backup (second external copy)

D: also distributes selected media/setup content to network machines and
manual USB targets.
```

The `D:` and `K:` copies are both local external media. They improve device
redundancy but do not satisfy the off-site portion of a 3-2-1 strategy.
OneDrive and Google Drive may provide another copy for synchronized content,
but synchronization can propagate deletion and cloud placeholders may not hold
local bytes.

## Machine activity baseline

| Tier | Machines | Intended behavior |
| --- | --- | --- |
| Regular | GT, MB, HS | Attempt when configured; report unavailable distinctly |
| Local | ST | Required current-machine source |
| Occasional | YA | Skip cleanly when offline unless explicitly required |
| Historical/rare | NI, EV, XG, ZG | Preserve scripts; do not place in default daily plan |

Machine names are historical identifiers, not proof that a machine is online or
still has the same shares.

## Confirmed strengths

- Multiple physical copies are attempted.
- `robocopy` handles interrupted/network copies better than simple copy tools.
- Junction traversal is disabled with `/XJ`.
- Temporary files and selected system paths are excluded.
- Logs are rotated and detailed Robocopy output is retained for several runs.
- AppData is intentionally narrowed rather than copied wholesale.
- Rare machine scripts are retained instead of silently discarded.

## Critical findings

### Completion is not success

`BACKUP.CMD` does not convert Robocopy exit codes into batch success/failure, and
`DoBackup.bat` does not aggregate child-script failures. The latest audited run
contained access-denied, sharing-violation, and missing-path errors while the
summary log still printed `Backup Complete`.

Robocopy codes are bitmasks. Codes 0–7 are nonfatal outcomes; 8 or higher means
at least one copy failure. A trustworthy runner must capture the code
immediately after every job.

### Mirrors propagate deletion

Every legacy copy uses `/MIR`. A source deletion, wrong mapping, empty/unmounted
source, ransomware change, or configuration mistake can remove destination
files. Mirroring `D:` to `K:` can propagate damage from the aggregation copy to
the second external copy.

The modern default is non-deleting `Update`. `Mirror` requires authorization in
both the plan and invocation, plus destination identity validation.

### Drive letters are not identities

The audited labels were:

- `D:` — `My Data`
- `K:` — `My Backup`

Letters can move. The modern runner validates expected labels and can also use a
local-only volume identifier. Public example plans never contain real serials.

### Coverage is broad but incomplete

The current ST and network scripts exclude all `AppData`; key scripts also
exclude Google Drive and `.vscode`. Selective exceptions cover Minecraft and
EverQuest, but other local-only state is not represented.

Presence-only checks on ST found VS Code user state, Windows Terminal state,
and browser profiles. This does not mean every profile should be copied live.
The plan should identify restore-worthy data and use application-aware exports
or quiesced copies where necessary.

### Cloud sync needs hydration checks

OneDrive is configured on ST. Google Drive was not present at the legacy path at
audit time and its client was intentionally stopped. A cloud folder can contain
online-only placeholders. Copying a placeholder does not guarantee recoverable
content, and a mirror must never treat an unavailable cloud root as an empty
source.

### Logs are runtime evidence, not source

Legacy logs live beside executable scripts, are ignored by Git, and rotate after
10 detailed generations. They mix planning, network mappings, job output, and
errors. The modern layout writes one timestamped run directory with:

- `summary.json`
- `summary.txt`
- one Robocopy log per job
- a sanitized plan snapshot

Retention is configurable locally.

## Important categories to decide explicitly

| Category | Legacy state | Modern recommendation |
| --- | --- | --- |
| Desktop/Documents/Downloads/Saved Games | Broad Users mirror | Keep explicit and required |
| OneDrive | Included on ST but hydration unknown | Dedicated cloud-aware job |
| Google Drive | Usually excluded | Discover actual configured root; cloud-aware job |
| VS Code user settings/snippets | Omitted with AppData/.vscode | Add selective roaming `Code\User` paths |
| VS Code extensions | `.vscode` excluded | Export extension list; reinstall rather than copying binaries |
| Browser state | Omitted with AppData | Prefer account sync/export; selectively back up local-only data |
| Windows Terminal | Omitted with AppData | Back up `settings.json` or package LocalState selectively |
| Email archives | Not explicitly covered | Detect PST/local mail stores and add if present |
| SSH/GPG keys | Not present in audit | If later present, use encrypted restricted destination |
| App inventories | Not captured | Export package/application lists as generated evidence |
| Restore test | Not documented | Perform periodic isolated sample restores |

## USB script interpretation

The USB scripts intentionally target smaller or occasional removable media and
therefore have different subsets. They should become named manual plans with
capacity checks, expected labels, list-only previews, and no assumption that an
arbitrary `E:` volume is the intended device.

## Non-goals during initial migration

- No live production copy from the new engine.
- No scheduled-task replacement.
- No automatic cloud hydration or mass file pinning.
- No deletion against `D:`, `K:`, network shares, or USB media.
- No claim that file presence alone proves restorability.
