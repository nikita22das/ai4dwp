#requires -version 5.1
<#!
.SYNOPSIS
Safely stages temp files for removal and supports rollback.

.DESCRIPTION
This script helps DWP engineers clean up temp files on Windows endpoints.
Instead of permanently deleting eligible files, it moves them into a rollback
store so they can be restored later if needed.

.NOTES
- Dry run mode lists eligible files without changing them.
- Locked files are skipped and logged.
- Every action is written to a timestamped log file.
- Cleanup is idempotent because moved files are no longer present in the source path.
- Rollback is idempotent because already-restored or missing staged files are skipped.
#>

[CmdletBinding(DefaultParameterSetName = 'Cleanup')]
param(
    # Section 1: Cleanup parameters
    # Defines which paths to scan and how old a file must be before it is eligible.
    [Parameter(ParameterSetName = 'Cleanup')]
    [string[]]$Path = @(),

    [Parameter(ParameterSetName = 'Cleanup')]
    [ValidateRange(0, 3650)]
    [int]$OlderThanDays = 0,

    [Parameter(ParameterSetName = 'Cleanup')]
    [switch]$DryRun,

    # Section 2: Rollback parameters
    # Restores files from a prior cleanup batch using the manifest created during that run.
    [Parameter(Mandatory = $true, ParameterSetName = 'Rollback')]
    [switch]$Rollback,

    [Parameter(Mandatory = $true, ParameterSetName = 'Rollback')]
    [ValidateNotNullOrEmpty()]
    [string]$RollbackManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section 3: Script paths and runtime state
# Prepares stable log and rollback locations under the script folder.
$scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }
$logRoot = Join-Path -Path $scriptRoot -ChildPath 'Logs'
$rollbackRoot = Join-Path -Path $scriptRoot -ChildPath 'RollbackStore'
$timestamp = '{0}-{1}' -f (Get-Date -Format 'yyyyMMdd-HHmmssfff'), $PID
$logFile = Join-Path -Path $logRoot -ChildPath (('DWP-TempFile-Cleanup-{0}.log' -f $timestamp))

if (-not (Test-Path -LiteralPath $logRoot)) {
    New-Item -Path $logRoot -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -LiteralPath $rollbackRoot)) {
    New-Item -Path $rollbackRoot -ItemType Directory -Force | Out-Null
}

# Section 4: Logging helper
# Writes every action to both the console and the timestamped log file.
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet('INFO', 'WARN', 'ERROR')]
        [string]$Level = 'INFO'
    )

    $entry = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

# Section 5: Path helpers
# Normalizes and compares paths so script-owned folders are never cleaned up.
function Resolve-FullPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputPath
    )

    return [System.IO.Path]::GetFullPath($InputPath)
}

function Test-IsManagedPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$CandidatePath
    )

    $candidate = Resolve-FullPath -InputPath $CandidatePath
    foreach ($managedPath in @($logRoot, $rollbackRoot)) {
        $resolvedManagedPath = Resolve-FullPath -InputPath $managedPath
        if ($candidate.StartsWith($resolvedManagedPath, [System.StringComparison]::OrdinalIgnoreCase)) {
            return $true
        }
    }

    return $false
}

function Get-RelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,

        [Parameter(Mandatory = $true)]
        [string]$ChildPath
    )

    $normalizedBasePath = Resolve-FullPath -InputPath $BasePath
    if (-not $normalizedBasePath.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $normalizedBasePath = $normalizedBasePath + [System.IO.Path]::DirectorySeparatorChar
    }

    $baseUri = New-Object System.Uri($normalizedBasePath)
    $childUri = New-Object System.Uri((Resolve-FullPath -InputPath $ChildPath))
    $relativeUri = $baseUri.MakeRelativeUri($childUri)

    return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', '\')
}

function Get-DefaultCleanupPaths {
    $defaultPaths = @(
        $env:TEMP,
        $env:TMP,
        (Join-Path -Path $env:windir -ChildPath 'Temp')
    ) |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { Resolve-FullPath -InputPath $_ } |
        Select-Object -Unique

    return @($defaultPaths)
}

# Section 6: File state helper
# Detects whether a file is currently locked by trying to open it exclusively.
function Test-FileLocked {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    try {
        $stream = [System.IO.File]::Open($FilePath, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::None)
        $stream.Close()
        return $false
    } catch [System.IO.IOException] {
        return $true
    } catch {
        return $false
    }
}

# Section 7: Cleanup action
# Stages eligible files into a rollback batch and records a manifest for restoration.
function Invoke-Cleanup {
    param(
        [string[]]$CleanupPath,

        [Parameter(Mandatory = $true)]
        [int]$FileAgeInDays,

        [Parameter(Mandatory = $true)]
        [bool]$IsDryRun
    )

    $effectivePaths = if ($null -ne $CleanupPath -and $CleanupPath.Length -gt 0) { $CleanupPath } else { Get-DefaultCleanupPaths }
    $scanRoots = @($effectivePaths |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        ForEach-Object { Resolve-FullPath -InputPath $_ } |
        Select-Object -Unique)

    $summary = [ordered]@{
        Mode              = if ($IsDryRun) { 'DryRun' } else { 'Cleanup' }
        CutoffTime        = (Get-Date).AddDays(-$FileAgeInDays)
        PathsScanned      = 0
        FilesDiscovered   = 0
        EligibleFiles     = 0
        FilesStaged       = 0
        LockedFilesSkipped = 0
        ErrorsSkipped     = 0
        MissingPaths      = 0
    }

    $batchRoot = $null
    $manifestPath = $null
    $manifestInitialized = $false
    if (-not $IsDryRun) {
        $batchRoot = Join-Path -Path $rollbackRoot -ChildPath (('Batch-{0}' -f $timestamp))
        $manifestPath = Join-Path -Path $batchRoot -ChildPath 'RollbackManifest.csv'
        New-Item -Path $batchRoot -ItemType Directory -Force | Out-Null
    }

    Write-Log -Message ('Starting {0}. OlderThanDays={1}. Cutoff={2}' -f $summary.Mode, $FileAgeInDays, $summary.CutoffTime)
    foreach ($rootPath in $scanRoots) {
        $summary.PathsScanned++

        if (-not (Test-Path -LiteralPath $rootPath)) {
            $summary.MissingPaths++
            Write-Log -Level 'WARN' -Message ('Skipping missing path: {0}' -f $rootPath)
            continue
        }

        if (Test-IsManagedPath -CandidatePath $rootPath) {
            Write-Log -Level 'WARN' -Message ('Skipping script-managed path: {0}' -f $rootPath)
            continue
        }

        Write-Log -Message ('Scanning path: {0}' -f $rootPath)

        $rootKey = ([System.Text.RegularExpressions.Regex]::Replace($rootPath.TrimEnd('\'), '[^A-Za-z0-9._-]', '_')).Trim('_')
        if ([string]::IsNullOrWhiteSpace($rootKey)) {
            $rootKey = 'Root'
        }

        $files = @(Get-ChildItem -LiteralPath $rootPath -File -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.LastWriteTime -lt $summary.CutoffTime -and -not (Test-IsManagedPath -CandidatePath $_.FullName)
            })

        $summary.FilesDiscovered += @($files).Count

        foreach ($file in $files) {
            $summary.EligibleFiles++

            if ($IsDryRun) {
                Write-Log -Message ('DRY-RUN would stage file: {0}' -f $file.FullName)
                continue
            }

            if (Test-FileLocked -FilePath $file.FullName) {
                $summary.LockedFilesSkipped++
                Write-Log -Level 'WARN' -Message ('Skipping locked file: {0}' -f $file.FullName)
                continue
            }

            try {
                $relativePath = Get-RelativePath -BasePath $rootPath -ChildPath $file.FullName
                $stagedPath = Join-Path -Path $batchRoot -ChildPath (Join-Path -Path $rootKey -ChildPath $relativePath)
                $stagedDirectory = Split-Path -Path $stagedPath -Parent

                if (-not (Test-Path -LiteralPath $stagedDirectory)) {
                    New-Item -Path $stagedDirectory -ItemType Directory -Force | Out-Null
                }

                Move-Item -LiteralPath $file.FullName -Destination $stagedPath -Force -ErrorAction Stop

                $manifestRecord = [pscustomobject]@{
                    OriginalPath = $file.FullName
                    SourceRoot   = $rootPath
                    RelativePath = $relativePath
                    StagedPath   = $stagedPath
                    BatchRoot    = $batchRoot
                    MovedAt      = Get-Date -Format 's'
                }

                if (-not $manifestInitialized) {
                    $manifestRecord | Export-Csv -Path $manifestPath -NoTypeInformation
                    $manifestInitialized = $true
                } else {
                    $manifestRecord | Export-Csv -Path $manifestPath -NoTypeInformation -Append
                }

                $summary.FilesStaged++
                Write-Log -Message ('Staged file: {0} -> {1}' -f $file.FullName, $stagedPath)
            } catch {
                $summary.ErrorsSkipped++
                Write-Log -Level 'ERROR' -Message ('Failed to stage file: {0}. Error: {1}' -f $file.FullName, $_.Exception.Message)
            }
        }
    }

    if (-not $IsDryRun -and -not $manifestInitialized) {
        @() | Export-Csv -Path $manifestPath -NoTypeInformation
    }

    Write-Log -Message ('Log file saved to: {0}' -f $logFile)
    if ($manifestPath) {
        Write-Log -Message ('Rollback manifest saved to: {0}' -f $manifestPath)
    }

    Write-Host ''
    Write-Host 'Cleanup Summary'
    Write-Host '---------------'
    Write-Host ('Mode                : {0}' -f $summary.Mode)
    Write-Host ('Paths Scanned       : {0}' -f $summary.PathsScanned)
    Write-Host ('Files Discovered    : {0}' -f $summary.FilesDiscovered)
    Write-Host ('Eligible Files      : {0}' -f $summary.EligibleFiles)
    Write-Host ('Files Staged        : {0}' -f $summary.FilesStaged)
    Write-Host ('Locked Files Skipped: {0}' -f $summary.LockedFilesSkipped)
    Write-Host ('Errors Skipped      : {0}' -f $summary.ErrorsSkipped)
    Write-Host ('Missing Paths       : {0}' -f $summary.MissingPaths)
    if ($manifestPath) {
        Write-Host ('Rollback Manifest   : {0}' -f $manifestPath)
    }
    Write-Host ('Log File            : {0}' -f $logFile)

    return [pscustomobject]@{
        Summary      = $summary
        ManifestPath = $manifestPath
        LogFile      = $logFile
    }
}

# Section 8: Rollback action
# Restores staged files back to their original locations using a manifest from a prior run.
function Invoke-Rollback {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Manifest
    )

    $resolvedManifestPath = Resolve-FullPath -InputPath $Manifest
    Write-Log -Message ('Starting rollback using manifest: {0}' -f $resolvedManifestPath)

    if (-not (Test-Path -LiteralPath $resolvedManifestPath)) {
        throw 'Rollback manifest not found.'
    }

    $records = @(Import-Csv -Path $resolvedManifestPath)
    $summary = [ordered]@{
        RecordsRead         = @($records).Count
        FilesRestored       = 0
        AlreadyRestored     = 0
        RestoreSkipped      = 0
        RestoreErrors       = 0
    }

    foreach ($record in $records) {
        try {
            if ([string]::IsNullOrWhiteSpace($record.StagedPath) -or [string]::IsNullOrWhiteSpace($record.OriginalPath)) {
                $summary.RestoreSkipped++
                Write-Log -Level 'WARN' -Message 'Skipping incomplete rollback record.'
                continue
            }

            if (-not (Test-Path -LiteralPath $record.StagedPath)) {
                if (Test-Path -LiteralPath $record.OriginalPath) {
                    $summary.AlreadyRestored++
                    Write-Log -Message ('Skipping already-restored file: {0}' -f $record.OriginalPath)
                } else {
                    $summary.RestoreSkipped++
                    Write-Log -Level 'WARN' -Message ('Staged file missing, cannot restore: {0}' -f $record.StagedPath)
                }
                continue
            }

            if (Test-Path -LiteralPath $record.OriginalPath) {
                $summary.RestoreSkipped++
                Write-Log -Level 'WARN' -Message ('Destination already exists, skipping restore: {0}' -f $record.OriginalPath)
                continue
            }

            $destinationDirectory = Split-Path -Path $record.OriginalPath -Parent
            if (-not (Test-Path -LiteralPath $destinationDirectory)) {
                New-Item -Path $destinationDirectory -ItemType Directory -Force | Out-Null
            }

            Move-Item -LiteralPath $record.StagedPath -Destination $record.OriginalPath -Force -ErrorAction Stop
            $summary.FilesRestored++
            Write-Log -Message ('Restored file: {0} -> {1}' -f $record.StagedPath, $record.OriginalPath)
        } catch {
            $summary.RestoreErrors++
            Write-Log -Level 'ERROR' -Message ('Failed to restore file: {0}. Error: {1}' -f $record.OriginalPath, $_.Exception.Message)
        }
    }

    Write-Log -Message ('Log file saved to: {0}' -f $logFile)

    Write-Host ''
    Write-Host 'Rollback Summary'
    Write-Host '----------------'
    Write-Host ('Records Read     : {0}' -f $summary.RecordsRead)
    Write-Host ('Files Restored   : {0}' -f $summary.FilesRestored)
    Write-Host ('Already Restored : {0}' -f $summary.AlreadyRestored)
    Write-Host ('Restore Skipped  : {0}' -f $summary.RestoreSkipped)
    Write-Host ('Restore Errors   : {0}' -f $summary.RestoreErrors)
    Write-Host ('Log File         : {0}' -f $logFile)

    return [pscustomobject]@{
        Summary = $summary
        LogFile = $logFile
    }
}

# Section 9: Main execution
# Selects cleanup or rollback mode and wraps the top-level call with a clear failure message.
try {
    if ($PSCmdlet.ParameterSetName -eq 'Rollback') {
        Invoke-Rollback -Manifest $RollbackManifestPath | Out-Null
    } else {
        $cleanupParameters = @{
            FileAgeInDays = $OlderThanDays
            IsDryRun      = $DryRun.IsPresent
        }

        if ($null -ne $Path -and $Path.Length -gt 0) {
            $cleanupParameters.CleanupPath = $Path
        }

        Invoke-Cleanup @cleanupParameters | Out-Null
    }
} catch {
    Write-Log -Level 'ERROR' -Message ('Script failed: {0}' -f $_.Exception.Message)
    throw
}