# DWP Event Log Archive and Cleanup

## Overview

`DWP-EventLog-Archive-Cleanup.ps1` archives and cleans Windows event logs with safety controls for endpoint use.

## Key Safety Behavior

- Dry run mode prints the record count that would be deleted.
- Only logs whose newest event is older than the configured cutoff are eligible for cleanup.
- Every operation is wrapped with error handling and logged.
- A timestamped log file is created for each run.
- A summary is printed at the end of each run.
- Daily idempotency: if a log already has an archive for today, that log is skipped.

## Rollback Behavior

- Cleanup mode writes a rollback manifest per batch.
- Rollback mode reads that manifest and restores archive artifacts into a restore folder.
- Rollback mode is idempotent for restored artifacts in the same restore batch.

## Parameters

### Cleanup mode

- `-LogName <string[]>`
  Event logs to process. Default: `Application`, `System`.

- `-OlderThanDays <int>`
  Cutoff age in days. Default: `3`.

- `-DryRun`
  Shows counts and actions without archiving or clearing logs.

### Rollback mode

- `-Rollback`
  Enables rollback artifact restore mode.

- `-RollbackManifestPath <string>`
  Path to the manifest file from a previous cleanup run.

## Examples

Dry run with defaults:

```powershell
.\DWP-EventLog-Archive-Cleanup.ps1 -DryRun
```

Dry run for specific logs and age:

```powershell
.\DWP-EventLog-Archive-Cleanup.ps1 -LogName Application, System -OlderThanDays 7 -DryRun
```

Cleanup run:

```powershell
.\DWP-EventLog-Archive-Cleanup.ps1 -LogName Application, System -OlderThanDays 7
```

Rollback artifact restore:

```powershell
.\DWP-EventLog-Archive-Cleanup.ps1 -Rollback -RollbackManifestPath ".\EventLogRollbackStore\Batch-<runid>\RollbackManifest.csv"
```

## Output Locations

- Logs: `Day 3\Logs\DWP-EventLog-Archive-Cleanup-<runid>.log`
- Archives: `Day 3\EventLogArchive\<LogName>-<yyyymmdd>.evtx`
- Rollback manifests: `Day 3\EventLogRollbackStore\Batch-<runid>\RollbackManifest.csv`
- Restored rollback artifacts: `Day 3\EventLogRestore\Restore-<runid>\`

## Notes

- Clearing event logs requires appropriate privileges.
- Some channels may be restricted by policy or permissions.
- This script intentionally uses conservative cleanup rules to avoid deleting recent operational telemetry.