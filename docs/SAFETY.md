# Safety Model

## Core rules

1. Planning is the default. Without `-Execute`, Robocopy receives `/L`.
2. Destination identity is checked before every job.
3. Missing required sources fail; optional offline sources are explicitly
   skipped and reported.
4. Update mode does not delete destination-only content.
5. Mirror mode requires all of:
   - `Mode = 'Mirror'` on the job
   - `AllowDelete = $true` on the job
   - `-AllowDelete` on the invocation
   - an identity-verified destination
6. Robocopy exit codes are captured immediately. Codes 8+ fail the run.
7. Logs and manifests are local runtime state and are never committed.
8. Credentials are managed by Windows/SMB outside public plans; plaintext
   passwords are never accepted by the engine.
9. Cloud-aware jobs fail closed when their root is missing and warn/block when
   online-only content is detected.
10. The runner never formats drives, changes firmware, modifies cloud pinning,
    or changes Task Scheduler.

## Why update is the default

A backup copy should preserve a recovery opportunity when a source file is
accidentally deleted or corrupted. `Update` copies current content but does not
remove destination-only content. It is not a complete retention system—the
destination can still be overwritten—so future phases add snapshots/versioned
retention for critical data.

## Robocopy result model

| Exit bits | Meaning | Viper result |
| ---: | --- | --- |
| 0 | No change | Success |
| 1 | Files copied | Success |
| 2 | Extra destination entries | Notice |
| 4 | Mismatches | Warning |
| 8 | Copy failures | Failure |
| 16 | Fatal error | Failure |

Combinations are interpreted by bits. Any result with bit 8 or 16 is a failure;
a numeric code of 8 or greater is therefore blocked.

## Drive identity

Expected volume labels belong in the plan. Optional volume serials belong only
in ignored local configuration. Network destinations are validated by their UNC
root and availability rather than local drive-letter mappings where practical.

A drive letter alone is never sufficient authorization for a mirror.

## Cloud files

Cloud sync clients may expose placeholders that have metadata but no local file
content. The runner does not hydrate content automatically because that can
consume substantial space and network bandwidth. It reports the condition and
requires the user to make content available offline before treating the job as
complete.

## Logs and privacy

Each run uses a new timestamped directory under ignored `state\runs`. Logs may
contain personal paths and filenames. Do not attach or publish them without
review. Public summaries and tests use fictional paths and machine names.

## Restore validation

A successful copy is evidence, not proof. Periodically restore a sample into an
isolated directory and verify it can be opened. Critical encrypted material must
also have a tested key-recovery procedure.
