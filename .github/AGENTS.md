# viper-backup Agent Index

This repository uses a small set of project-scoped agents under
`.github/agents/`.

## Primary Agent

- `ViperBackup` - safety-first architecture, implementation, testing, docs, and
  incremental delivery.

## Specialized Agents

- `ViperBackup-Analysis` - read-only coverage, topology, log, and migration
  analysis.
- `ViperBackup-Testing` - plan validation, safety invariants, Pester, and CI.

## Selection Guide

See `.github/agents/AGENT-SELECTION-GUIDE.md`.

## Always-On Instructions

See `.github/copilot-instructions.md`.

All agents must preserve plan-only defaults and must not execute production
copies, mirrors, or Task Scheduler changes without explicit operator approval.
