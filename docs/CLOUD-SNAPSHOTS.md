# Cloud-Local Backup and Snapshots

## Why cloud content still needs backup

OneDrive and Google Drive synchronize state; they are not automatically an
independent offline history. Deletion, ransomware changes, account problems,
client mistakes, or online-only placeholders can affect recoverability.

A small critical cloud tree—such as a limited OneDrive allocation—is a strong
candidate for a dedicated local snapshot when every selected file is confirmed
available offline.

## Required design

Use one explicit job per provider and machine:

- exact configured source root
- `CloudAware = $true`
- verified local backup destination
- no automatic hydration
- no fallback to an empty or guessed source path

Remove provider roots from broad user-profile jobs when the dedicated job is
adopted. This prevents duplicate work and makes hydration failures visible.

## Modes

| Mode | Cloud use |
| --- | --- |
| `Update` | Stable current local copy; destination-only recovery files remain |
| `Snapshot` | Timestamped versions for a small, critical, fully local tree |
| `Mirror` | Not recommended for cloud acquisition because deletion can propagate |

For a small critical OneDrive tree, a daily or weekly `Snapshot` is preferred
once capacity and payload-retention policy are defined. Google Drive should be
added only after its actual configured root and local availability are verified.

## Hydration policy

The engine checks for offline/recall attributes and fails a cloud-aware job when
content is not fully local. It never pins or downloads content automatically.
This avoids surprise storage/network consumption and prevents placeholders from
being reported as protected bytes.

Current limitations:

- no provider-root discovery
- no cloud-client health/status check
- no per-folder mixed hydration policy
- no payload snapshot pruning yet
- hydration inspection can be expensive on very large trees

Until those features exist, local plans must name exact small roots and the
operator must manage offline availability in the provider client.

## Snapshot retention prerequisite

Run-log retention under `state\runs` does not remove timestamped backup payload
snapshots. Before unattended cloud snapshots are enabled, define:

- minimum generations to keep
- maximum age
- minimum destination free space
- protected snapshot root
- list-only preview and manifest before deletion
- a restore test before the first pruning operation

No payload snapshot cleanup should be added by reusing generic log cleanup.

## Validation checklist

1. Confirm the provider's configured local root.
2. Confirm selected folders are marked available offline.
3. Run the cloud-aware plan in list-only mode.
4. Verify the source file count is plausible and no placeholder failure occurs.
5. Confirm destination identity and free-space threshold.
6. Test a small isolated snapshot destination.
7. Restore representative files into a temporary directory and open them.
8. Define payload retention before scheduling repeated snapshots.

Public starting point: `config/critical-snapshots.example.psd1`.
