#requires -version 5.1
<#
.SYNOPSIS
Read-only endpoint health report for DWP engineers.

.DESCRIPTION
Collects and displays:
1) System uptime
2) Free disk space
3) Pending reboot status (registry checks)
4) Top 5 processes by memory (Working Set)
5) Top 5 processes by CPU time
6) Last 5 System log errors

This script is strictly read-only. It does not write to registry, disk, or event logs.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Section 1: System uptime
# Calculates uptime from the last OS boot time and shows it in days/hours/minutes.
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$lastBoot = $os.LastBootUpTime
$uptime = (Get-Date) - $lastBoot

# Section 2: Free disk space
# Lists all local fixed disks and reports free/used/total space in GB.
$diskInfo = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID,
                  VolumeName,
                  @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB, 2)}},
                  @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
                  @{Name='UsedGB';Expression={[math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)}},
                  @{Name='FreePercent';Expression={
                      if ($_.Size -gt 0) {
                          [math]::Round(($_.FreeSpace / $_.Size) * 100, 2)
                      } else {
                          0
                      }
                  }}

# Section 3: Pending reboot (registry checks)
# Reads known registry indicators used by Windows update/component servicing.
# VERIFY BEFORE RUNNING: Confirm these keys still match your enterprise baseline for "pending reboot" detection.
$rebootChecks = @(
    @{ Name = 'Component Based Servicing'; Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'; Type = 'Key' },
    @{ Name = 'Windows Update Auto Update'; Path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired'; Type = 'Key' },
    @{ Name = 'Pending File Rename Operations'; Path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager'; Value = 'PendingFileRenameOperations'; Type = 'Value' }
)

$pendingRebootReasons = @(foreach ($check in $rebootChecks) {
    if ($check.Type -eq 'Key') {
        if (Test-Path -Path $check.Path) {
            $check.Name
        }
    } elseif ($check.Type -eq 'Value') {
        $item = Get-ItemProperty -Path $check.Path -Name $check.Value -ErrorAction SilentlyContinue
        if ($null -ne $item -and $null -ne $item.($check.Value)) {
            $check.Name
        }
    }
})
$pendingReboot = $pendingRebootReasons.Count -gt 0

# Helper: Resolve executable path for a process ID.
# Uses Win32_Process ExecutablePath and falls back to a readable placeholder when unavailable.
function Get-ExecutablePathById {
    param(
        [Parameter(Mandatory = $true)]
        [int]$ProcessId
    )

    $proc = Get-CimInstance -ClassName Win32_Process -Filter ("ProcessId = {0}" -f $ProcessId) -ErrorAction SilentlyContinue
    if ($null -ne $proc -and -not [string]::IsNullOrWhiteSpace($proc.ExecutablePath)) {
        return $proc.ExecutablePath
    }

    return 'Unavailable (system/protected process or insufficient rights)'
}

# Section 4: Top 5 processes by memory (Working Set)
# Reads running process info and shows the highest working-set consumers.
$topMemory = Get-Process |
    Sort-Object -Property WorkingSet64 -Descending |
    Select-Object -First 5 |
    ForEach-Object {
        [pscustomobject]@{
            ProcessName    = $_.ProcessName
            Id             = $_.Id
            ExecutablePath = Get-ExecutablePathById -ProcessId $_.Id
            WorkingSetMB   = [math]::Round($_.WorkingSet64 / 1MB, 2)
        }
    }

# Section 5: Top 5 processes by CPU
# Reads cumulative CPU time for running processes and shows top consumers.
$topCpu = Get-Process |
    Where-Object { $null -ne $_.CPU } |
    Sort-Object -Property CPU -Descending |
    Select-Object -First 5 |
    ForEach-Object {
        [pscustomobject]@{
            ProcessName    = $_.ProcessName
            Id             = $_.Id
            ExecutablePath = Get-ExecutablePathById -ProcessId $_.Id
            CPUSeconds     = [math]::Round($_.CPU, 2)
        }
    }

# Section 6: Last 5 System log errors
# Reads the newest 5 error entries from the System event log.
# VERIFY BEFORE RUNNING: Ensure the executing account has permission to read the System event log.
$lastSystemErrors = Get-WinEvent -FilterHashtable @{ LogName = 'System'; Level = 2 } -MaxEvents 5 |
    Select-Object TimeCreated, Id, ProviderName, Message

# Output report header
Write-Host '============================================================'
Write-Host 'DWP Endpoint Health Report (Read-Only)'
Write-Host ('Generated: {0}' -f (Get-Date))
Write-Host ('Computer : {0}' -f $env:COMPUTERNAME)
Write-Host '============================================================'
Write-Host ''

# Output Section 1
Write-Host '1) System Uptime'
Write-Host ('Last Boot Time : {0}' -f $lastBoot)
Write-Host ('Uptime         : {0} days {1} hours {2} minutes' -f [int]$uptime.TotalDays, $uptime.Hours, $uptime.Minutes)
Write-Host ''

# Output Section 2
Write-Host '2) Free Disk Space (Local Fixed Disks)'
$diskInfo | Format-Table -AutoSize
Write-Host ''

# Output Section 3
Write-Host '3) Pending Reboot Status (Registry Checks)'
Write-Host ('Pending Reboot : {0}' -f $pendingReboot)
if ($pendingReboot) {
    Write-Host 'Reasons         :'
    $pendingRebootReasons | ForEach-Object { Write-Host ('- {0}' -f $_) }
} else {
    Write-Host 'Reasons         : None detected'
}
Write-Host ''

# Output Section 4
Write-Host '4) Top 5 Processes by Memory (Working Set)'
$topMemory | Format-Table -AutoSize
Write-Host ''

# Output Section 5
Write-Host '5) Top 5 Processes by CPU Time'
$topCpu | Format-Table -AutoSize
Write-Host ''

# Output Section 6
Write-Host '6) Last 5 System Log Errors'
$lastSystemErrors | Format-Table -Wrap -AutoSize
Write-Host ''

Write-Host 'End of report.'
