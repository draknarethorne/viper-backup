# Restore Validation

A successful copy is not the same as a proven restore.

## Safe validation cycle

1. Select a small representative set with no secrets.
2. Restore it into an isolated temporary directory—not over the original.
3. Verify expected files and directories are present.
4. Open representative documents/configuration with their owning application.
5. For encrypted data, verify keys and recovery instructions are available.
6. Record the date, source backup, sample scope, and result locally.
7. Remove the temporary restore only after validation is complete.

## Recommended cadence

- monthly for a small rotating sample
- after changing backup exclusions or job modes
- after replacing a drive or changing network shares
- before retiring an old machine or backup device
- after any run containing warnings or prior failures

## What not to do

- Do not restore over live source data as a test.
- Do not publish restore manifests containing personal paths.
- Do not treat hashes alone as application-level restore proof.
- Do not disconnect the only known-good copy during investigation.

## Long-term recovery layers

Large datasets may use a space-efficient exact Mirror, but critical smaller data
should also have versioned snapshots and an encrypted off-site copy. This limits
the damage from accidental deletion, ransomware, or a bad mirror source.
