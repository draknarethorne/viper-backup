# Agent Selection Guide

## ViperBackup

Use for end-to-end work involving architecture, PowerShell implementation,
configuration, documentation, tests, and incremental Git delivery.

## ViperBackup-Analysis

Use for read-only work such as:

- mapping source/destination coverage
- classifying regular, optional, and historical machines
- interpreting aggregate logs and Robocopy outcomes
- identifying omitted restore-worthy data
- comparing legacy behavior with a proposed plan

## ViperBackup-Testing

Use for validation work such as:

- testing plan parsing and safety gates
- validating Robocopy exit-code classification
- checking drive-identity enforcement
- proving Update versus Mirror behavior with temporary fixtures
- reviewing CI and deterministic summary contracts

## Boundaries

No agent should run a production copy, a write-capable Robocopy command, a
mirror, a cloud hydration operation, or a scheduled-task change unless the user
explicitly authorizes that exact controlled action.
