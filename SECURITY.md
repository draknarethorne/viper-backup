# Security Policy

## Supported Versions

This project is in active development. Security and data-safety fixes are
applied to the latest `main` branch.

## Reporting a Vulnerability

Do not open a public issue for vulnerabilities, credential exposure, unsafe
delete behavior, path traversal, destination-identity bypasses, or logs that
reveal private data.

Use [GitHub private vulnerability reporting](https://github.com/draknarethorne/viper-backup/security/advisories/new)
when available. If private reporting is unavailable, contact the repository
owner without including exploit details or private paths in a public issue.

Report privately with:

- a clear description
- safe reproduction steps using temporary data
- expected impact
- affected scripts or module functions
- any proposed mitigation

Never include real credentials, private keys, volume serials, personal paths, or
backup payloads in a report.

## Security Boundaries

`viper-backup` does not store or manage plaintext credentials. SMB access should
use Windows authentication or credentials managed outside the repository.
Runtime logs and local plans may contain sensitive paths and are Git-ignored.
Review them before sharing.
