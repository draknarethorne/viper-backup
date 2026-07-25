# TAKP Backup, Snapshots, and Portable Sync

## Goals

TAKP needs three related but distinct protections:

1. a broad local backup of the authoritative installation;
2. timestamped history for small, important configuration;
3. optional one-way publication of portable state to another gaming machine.

These must not become an unreviewed bidirectional sync.

## Source authority

Choose one machine as the authoritative source for portable TAKP state. The
initial design treats the current workstation as authoritative and the older
gaming laptop as a destination. Changes made only on the destination can be
overwritten or left divergent; they are never automatically merged.

Before execution, record the authority and target in the ignored local plan.

## Three logical jobs

### Full local backup

Copy the full authoritative TAKP tree into the selected-folder aggregation area.
Use `Update` during migration so destination-only recovery material is not
silently deleted. This protects game/system files and configuration as one
recoverable tree.

A future exact-image `Mirror` may be appropriate when capacity requires it, but
only after the source/destination pair and exclusions pass list-only comparison
and restore testing.

### Portable configuration snapshot

Create a timestamped snapshot of an explicit allowlist of small configuration
files. Candidate classes include:

- character-specific UI/layout files
- hotkey, macro, spell-set, and user-authored configuration
- timer configuration and exported timer data
- custom interface resources

Do not assume every `.ini` file is portable. Classify actual filenames before
enabling an unattended snapshot. The public plan therefore uses fictional
patterns that must be replaced locally.

### Gaming-machine publication

Publish the approved portable subset and desired game/system files one way to
the gaming laptop. Start with `Update`, not `Mirror`, so destination-only
machine settings survive. Keep a per-target exclusion list.

## Machine-specific exclusions

`eqclient.ini` is machine-specific and must not be copied between machines by
the portable publication job. It commonly represents display, renderer,
window, audio, input, and performance choices that differ by hardware.

Also review and normally exclude:

- resolution/window-position files
- device/GPU/audio-specific settings
- remembered account, credential, or token state
- caches, patcher temporary files, crash dumps, and logs
- destination-machine overlays maintained intentionally on that machine

The broad local backup may retain these files for recovery on the source
machine; the cross-machine publication job must exclude them.

## Conflict and safety rules

- Direction is one-way; no automatic merge.
- `eqclient.ini` is always excluded from cross-machine publication.
- Unknown settings are backup-only until classified.
- Do not copy files while a launcher/game/timer process is actively rewriting
  them when consistency matters.
- Use list-only output before every exclusion or destination change.
- Keep portable snapshots independently of the current full-tree copy.
- Never publish credentials or account-selection state.

## Validation checklist

Before enabling a real TAKP publication plan:

1. inventory configuration filenames without publishing their contents;
2. classify each as portable, machine-specific, generated, or unknown;
3. create an ignored local allowlist/exclusion list;
4. run list-only against the target;
5. verify `eqclient.ini` and target-specific files are absent from planned work;
6. execute only against a test destination first;
7. launch both installations and verify display, input, UI, characters, and
   timers independently;
8. perform an isolated restore from a timestamped snapshot.

Public starting points are `config/takp-sync.example.psd1` and
`config/critical-snapshots.example.psd1`.
