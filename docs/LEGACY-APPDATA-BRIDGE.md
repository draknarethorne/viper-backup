# Legacy ST AppData Bridge

## Purpose

The scheduled legacy workflow still excludes broad `AppData` from the current
workstation's `Users` mirror. This is intentional: `AppData` contains large
caches, cloud-client databases, locked browser stores, transient package data,
and authentication state that should not be copied wholesale with `/MIR`.

Until the modern PowerShell plans replace the legacy workflow,
`DoBackupST.bat` selectively re-enters three confirmed local paths:

| Path | Recovery value | Deliberate exclusions |
| --- | --- | --- |
| `%APPDATA%\Code\User` | VS Code settings, keybindings, snippets, tasks, and profiles | `workspaceStorage`, `globalStorage`, `History` |
| `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState` | Windows Terminal settings | `state.json` transient window state |
| `%APPDATA%\Microsoft\Templates` | Custom Microsoft Office templates | Global temporary-file rules plus Office `~$*` lock files |

Each call is guarded with `if exist`, so a missing application path does not
create an avoidable Robocopy failure. Confirmed-absent ST Minecraft, EverQuest
VirtualStore, and EQTimer calls were retired on 2026-07-26. Full `C:\TAKP`
coverage remains active.

The broad profile calls now exclude `NTUSER.DAT`. The selected recovery scope
is personal files and reviewed application settings, not a live Windows
registry-hive or full-system restore. Full profile recovery requires a separate
VSS/system-image-aware mechanism.

## Why not remove `/XD AppData`

Opening all of `AppData` would immediately place every included subtree under
the legacy wrapper's `/MIR` behavior. Risks include:

- deletion propagation into the backup copy;
- locked/inconsistent SQLite and application databases;
- browser cookies, sessions, tokens, and encryption-bound credentials;
- large caches, package data, logs, service workers, and cloud-client state;
- longer runs and more sharing-violation noise masking meaningful failures.

Available capacity does not remove those consistency, privacy, or deletion
risks. Add future paths only after identifying their restore value and safe
copy boundary.

## Not covered by this bridge

- Whole Chrome, Edge, or Firefox profiles
- OneDrive or Google Drive client databases
- VS Code extensions and extension-owned `globalStorage`
- Live mail databases
- Generic package caches

Browser bookmarks should be exported into Documents or captured later with a
closed-application, file-specific modern job. Cloud user content belongs in a
dedicated cloud-aware plan, not in client AppData.

## Operational notes

- Close VS Code, Windows Terminal, and Office applications before a manually
  supervised run when practical.
- The daily scheduled run may still encounter live files. The legacy wrapper
  uses `/R:0`, captures Robocopy results immediately, and marks codes 8+ as
  failures.
- These additions are a temporary safety bridge, not proof of recovery.
- Confirm files on `D:` and perform an isolated sample restore.
- The modern plan should ultimately use non-deleting `Update` or timestamped
  `Snapshot` semantics for these settings.
