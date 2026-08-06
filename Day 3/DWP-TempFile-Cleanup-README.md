# DWP Temp File Cleanup Script

## Overview

`DWP-TempFile-Cleanup.ps1` safely cleans temp files on a Windows endpoint by moving eligible files into a rollback store instead of permanently deleting them. This keeps the cleanup reversible and makes repeated runs safe.

## Safety Features

- Dry run mode lists files that would be staged.
- Locked files are skipped and logged.
- Per-file `try/catch` handling prevents one failure from stopping the whole run.
- A timestamped log file is created for every execution.
- A rollback manifest is created for each cleanup batch.
- The script avoids cleaning its own `Logs` and `RollbackStore` folders.
- Re-running cleanup is idempotent because already-staged files are no longer in the source path.
- Re-running rollback is idempotent because already-restored entries are skipped.

## Default Behavior

If `-Path` is not supplied, the script scans these locations when they exist:

- The current user temp folder from `%TEMP%`
- The current user temp folder from `%TMP%`
- `C:\Windows\Temp`

## Parameters

### Cleanup mode

- `-Path <string[]>`
  One or more folders to scan recursively for files.

- `-OlderThanDays <int>`
  Only targets files with `LastWriteTime` older than the specified number of days.
  Default: `0`

- `-DryRun`
  Lists eligible files and writes log entries without moving any files.

### Rollback mode

- `-Rollback`
  Switches the script into rollback mode.

- `-RollbackManifestPath <string>`
  Path to the `RollbackManifest.csv` file created by a previous cleanup run.

## Examples

Dry run against the default temp folders:

```powershell
.\DWP-TempFile-Cleanup.ps1 -DryRun
```

Dry run against a specific folder for files older than 7 days:

```powershell
.\DWP-TempFile-Cleanup.ps1 -Path 'C:\Temp' -OlderThanDays 7 -DryRun
```

Cleanup a custom temp folder for files older than 3 days:

```powershell
.\DWP-TempFile-Cleanup.ps1 -Path 'C:\Temp' -OlderThanDays 3
```

Rollback a previous cleanup batch:

```powershell
.\DWP-TempFile-Cleanup.ps1 -Rollback -RollbackManifestPath '.\RollbackStore\Batch-20260805-103000\RollbackManifest.csv'
```

## Output Locations

- Logs: `Day 3\Logs\DWP-TempFile-Cleanup-<timestamp>.log`
- Rollback batches: `Day 3\RollbackStore\Batch-<timestamp>\`
- Rollback manifest: `Day 3\RollbackStore\Batch-<timestamp>\RollbackManifest.csv`

## Operational Notes

- The script only processes files, not directories.
- `-OlderThanDays 0` means any file older than the current execution time is eligible.
- If a file is in use, the script logs the skip and continues.
- If the original path already exists during rollback, that file is skipped to avoid overwriting data.