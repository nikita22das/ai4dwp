Title: Floor 6 Evidence Collection Script Review
Version: 1.0
Date: 14/08/2026
Author: Nikita
Status: Draft

AI Generated Script (Version 1)

```powershell
param(
    [string]$OutputPath = "C:\Temp\Floor6Evidence",
    [switch]$DryRun
)

$since = (Get-Date).AddHours(-48)
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

# Evidence object for handoff to another engineer
$evidence = [ordered]@{
    Metadata = [ordered]@{
        Hostname = $env:COMPUTERNAME
        CollectedAt = (Get-Date).ToString("s")
        DryRun = [bool]$DryRun
        Since = $since.ToString("s")
    }
    SystemInformation = $null
    StartupApplications = $null
    RunningProcesses = $null
    CpuUsage = $null
    MemoryUsage = $null
    DiskUtilisation = $null
    InstalledApplications = $null
    ApplicationErrors48h = $null
    LoginPerformanceIndicators = $null
}

$evidence.SystemInformation = Get-ComputerInfo |
    Select-Object WindowsProductName, WindowsVersion, OsBuildNumber, CsModel, CsManufacturer, CsTotalPhysicalMemory

$evidence.StartupApplications = Get-CimInstance Win32_StartupCommand |
    Select-Object Name, Command, Location, User

$processes = Get-Process | Select-Object Name, Id, CPU, WS, PM, StartTime -ErrorAction SilentlyContinue
$evidence.RunningProcesses = $processes | Sort-Object CPU -Descending | Select-Object -First 40

try {
    $cpuSample = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5
    $avgCpu = ($cpuSample.CounterSamples | Measure-Object -Property CookedValue -Average).Average
} catch {
    $avgCpu = $null
}
$evidence.CpuUsage = [ordered]@{ AveragePercent = [math]::Round($avgCpu,2) }

$os = Get-CimInstance Win32_OperatingSystem
$memUsedBytes = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) * 1KB
$evidence.MemoryUsage = [ordered]@{
    TotalGB = [math]::Round(($os.TotalVisibleMemorySize * 1KB) / 1GB, 2)
    FreeGB = [math]::Round(($os.FreePhysicalMemory * 1KB) / 1GB, 2)
    UsedGB = [math]::Round($memUsedBytes / 1GB, 2)
}

$evidence.DiskUtilisation = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
    Select-Object DeviceID, VolumeName,
        @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB,2)}},
        @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace / 1GB,2)}},
        @{Name='UsedPercent';Expression={ if ($_.Size) { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2) } else { $null } }}

$regPaths = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)
$evidence.InstalledApplications = Get-ItemProperty $regPaths -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName } |
    Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
    Sort-Object DisplayName

$evidence.ApplicationErrors48h = Get-WinEvent -FilterHashtable @{
    LogName = "Application"
    Level = 2
    StartTime = $since
} -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, ProviderName, Message -First 200

$evidence.LoginPerformanceIndicators = @(
    Get-WinEvent -FilterHashtable @{
        LogName = "Microsoft-Windows-Diagnostics-Performance/Operational"
        StartTime = $since
    } -ErrorAction SilentlyContinue |
    Select-Object TimeCreated, Id, LevelDisplayName, Message -First 200
)

if (-not $DryRun) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    $jsonPath = Join-Path $OutputPath "Floor6_Evidence_$timestamp.json"
    $evidence | ConvertTo-Json -Depth 6 | Out-File -FilePath $jsonPath -Encoding utf8
    Write-Host "Evidence written to: $jsonPath"
} else {
    Write-Host "Dry run enabled. No files were written."
    $evidence | ConvertTo-Json -Depth 4
}
```

Engineer Review

Weaknesses:
- Startup command collection is useful, but Version 1 does not explicitly capture startup impact metrics (for example process CPU spikes during sign-in windows).
- Installed application output is broad and not scoped to the newly deployed Document Management app, so correlation is slower.
- Login performance indicators rely on one log source only, which can miss profile and Group Policy delay signals.
- Event collection takes first 200 rows without consistent ordering, so recent high-value events may be dropped unpredictably.
- No collector-level status map exists, making it hard for another engineer to distinguish no-data from collector failure.

Missing evidence:
- No explicit capture of group policy processing events in the same time window.
- No user-session timing correlation field (for example who logged in when, and when slowdown occurred).
- No focused process snapshot for suspected app executables/services.
- No summary index output for rapid handoff (only raw JSON in non-dry-run mode).

Assumptions in Version 1:
- Assumes Diagnostics-Performance log alone is enough to represent login performance.
- Assumes reading only HKLM uninstall keys is sufficient for all relevant application inventory.
- Assumes a single sample average CPU is adequate to describe performance contention.

Areas needing improvement:
- Add per-collector validation and error handling with reason codes.
- Add deterministic sorting and tighter field selection for high-volume event data.
- Add targeted app match section for the Document Management deployment clue without assuming causation.
- Improve operator usability with transcript logging and both JSON and CSV outputs.

Side-by-side improvement summary:

| Version 1 | Version 2 |
|---|---|
| Single-path collection flow | Collector wrapper with status tracking and exception capture |
| One login-related log source | Multiple login-impact log sources (Diagnostics, Winlogon, GroupPolicy, User Profile Service) |
| Broad app inventory only | Broad inventory plus targeted app-match evidence section |
| Minimal runtime logging | Timestamped logging and transcript for handoff/auditability |
| JSON only | JSON plus compact summary CSV for quick engineering triage |

Hand-Corrected Script (Version 2)

```powershell
[CmdletBinding()]
param(
    [ValidateNotNullOrEmpty()]
    [string]$OutputPath = "C:\Temp\Floor6Evidence",

    [ValidateNotNullOrEmpty()]
    [string]$SuspectAppPattern = "Document|DMS|Matter",

    [int]$LookbackHours = 48,

    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$runId = Get-Date -Format "yyyyMMdd_HHmmss"
$since = (Get-Date).AddHours(-1 * $LookbackHours)
$collectorStatus = New-Object System.Collections.Generic.List[object]
$transcriptStarted = $false

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO","WARN","ERROR")]
        [string]$Level = "INFO"
    )
    $ts = Get-Date -Format "s"
    Write-Host "[$ts][$Level] $Message"
}

function Invoke-Collector {
    param(
        [Parameter(Mandatory)] [string]$Name,
        [Parameter(Mandatory)] [scriptblock]$ScriptBlock
    )

    try {
        Write-Log "Collecting $Name"
        $data = & $ScriptBlock
        $collectorStatus.Add([pscustomobject]@{ Collector = $Name; Status = "Success"; Detail = "OK" }) | Out-Null
        return $data
    } catch {
        $collectorStatus.Add([pscustomobject]@{ Collector = $Name; Status = "Error"; Detail = $_.Exception.Message }) | Out-Null
        Write-Log "Collector failed: $Name - $($_.Exception.Message)" "WARN"
        return $null
    }
}

function Get-InstalledApps {
    $paths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    $raw = foreach ($p in $paths) {
        Get-ItemProperty -Path $p -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            Select-Object DisplayName, DisplayVersion, Publisher, InstallDate, PSPath
    }

    $raw |
        Sort-Object DisplayName, DisplayVersion -Unique
}

function Get-EventSlice {
    param(
        [string]$LogName,
        [int[]]$Ids = @(),
        [int]$MaxEvents = 200
    )

    $fh = @{ LogName = $LogName; StartTime = $since }
    if ($Ids.Count -gt 0) { $fh.Id = $Ids }

    Get-WinEvent -FilterHashtable $fh -ErrorAction Stop |
        Sort-Object TimeCreated -Descending |
        Select-Object -First $MaxEvents TimeCreated, Id, LevelDisplayName, ProviderName, Message
}

$metadata = [ordered]@{
    Hostname = $env:COMPUTERNAME
    CollectedAt = (Get-Date).ToString("s")
    DryRun = [bool]$DryRun
    LookbackHours = $LookbackHours
    Since = $since.ToString("s")
    SuspectAppPattern = $SuspectAppPattern
}

if (-not $DryRun) {
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    $transcriptPath = Join-Path $OutputPath "Floor6_Evidence_$runId.transcript.log"
    Start-Transcript -Path $transcriptPath -Force | Out-Null
    $transcriptStarted = $true
}

$systemInfo = Invoke-Collector -Name "SystemInformation" -ScriptBlock {
    Get-ComputerInfo |
        Select-Object WindowsProductName, WindowsVersion, OsBuildNumber, CsManufacturer, CsModel, CsTotalPhysicalMemory, BiosSerialNumber
}

$startupApps = Invoke-Collector -Name "StartupApplications" -ScriptBlock {
    Get-CimInstance Win32_StartupCommand |
        Select-Object Name, Command, Location, User |
        Sort-Object Name
}

$runningProcesses = Invoke-Collector -Name "RunningProcesses" -ScriptBlock {
    Get-Process -ErrorAction SilentlyContinue |
        Select-Object Name, Id, CPU, PM, WS, StartTime |
        Sort-Object CPU -Descending |
        Select-Object -First 60
}

$cpuUsage = Invoke-Collector -Name "CpuUsage" -ScriptBlock {
    $counter = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 10
    $avg = ($counter.CounterSamples | Measure-Object CookedValue -Average).Average
    $peak = ($counter.CounterSamples | Measure-Object CookedValue -Maximum).Maximum
    [pscustomobject]@{ AveragePercent = [math]::Round($avg,2); PeakPercent = [math]::Round($peak,2) }
}

$memoryUsage = Invoke-Collector -Name "MemoryUsage" -ScriptBlock {
    $os = Get-CimInstance Win32_OperatingSystem
    $total = $os.TotalVisibleMemorySize * 1KB
    $free = $os.FreePhysicalMemory * 1KB
    [pscustomobject]@{
        TotalGB = [math]::Round($total / 1GB, 2)
        FreeGB = [math]::Round($free / 1GB, 2)
        UsedGB = [math]::Round(($total - $free) / 1GB, 2)
        UsedPercent = [math]::Round((($total - $free) / $total) * 100, 2)
    }
}

$diskUtilisation = Invoke-Collector -Name "DiskUtilisation" -ScriptBlock {
    Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" |
        Select-Object DeviceID, VolumeName,
            @{Name='SizeGB';Expression={[math]::Round($_.Size / 1GB,2)}},
            @{Name='FreeGB';Expression={[math]::Round($_.FreeSpace / 1GB,2)}},
            @{Name='UsedPercent';Expression={ if ($_.Size -gt 0) { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 2) } else { $null } }} |
        Sort-Object DeviceID
}

$installedApps = Invoke-Collector -Name "InstalledApplications" -ScriptBlock {
    Get-InstalledApps
}

$matchedApps = Invoke-Collector -Name "SuspectApplicationMatches" -ScriptBlock {
    if (-not $installedApps) { return @() }
    $installedApps |
        Where-Object { $_.DisplayName -match $SuspectAppPattern } |
        Sort-Object DisplayName
}

$appErrors48h = Invoke-Collector -Name "ApplicationErrors48h" -ScriptBlock {
    Get-WinEvent -FilterHashtable @{ LogName = "Application"; Level = 2; StartTime = $since } -ErrorAction Stop |
        Sort-Object TimeCreated -Descending |
        Select-Object -First 300 TimeCreated, Id, ProviderName, Message
}

$loginPerformance = Invoke-Collector -Name "LoginPerformanceIndicators" -ScriptBlock {
    [ordered]@{
        DiagnosticsPerformance = Get-EventSlice -LogName "Microsoft-Windows-Diagnostics-Performance/Operational" -Ids @(100,101,102,103,200,201,202) -MaxEvents 200
        WinlogonOperational = Get-EventSlice -LogName "Microsoft-Windows-Winlogon/Operational" -MaxEvents 150
        GroupPolicyOperational = Get-EventSlice -LogName "Microsoft-Windows-GroupPolicy/Operational" -MaxEvents 150
        UserProfileOperational = Get-EventSlice -LogName "Microsoft-Windows-User Profile Service/Operational" -MaxEvents 150
    }
}

$evidence = [ordered]@{
    Metadata = $metadata
    CollectorStatus = $collectorStatus
    SystemInformation = $systemInfo
    StartupApplications = $startupApps
    RunningProcesses = $runningProcesses
    CpuUsage = $cpuUsage
    MemoryUsage = $memoryUsage
    DiskUtilisation = $diskUtilisation
    InstalledApplications = $installedApps
    SuspectApplicationMatches = $matchedApps
    ApplicationErrors48h = $appErrors48h
    LoginPerformanceIndicators = $loginPerformance
}

if ($DryRun) {
    Write-Log "Dry-run mode enabled. No files will be written."
    $evidence | ConvertTo-Json -Depth 8
    return
}

try {
    $jsonPath = Join-Path $OutputPath "Floor6_Evidence_$runId.json"
    $statusCsvPath = Join-Path $OutputPath "Floor6_Evidence_$runId.collector_status.csv"

    $evidence | ConvertTo-Json -Depth 8 | Out-File -FilePath $jsonPath -Encoding utf8
    $collectorStatus | Export-Csv -Path $statusCsvPath -NoTypeInformation -Encoding utf8

    Write-Log "Evidence JSON written to $jsonPath"
    Write-Log "Collector status CSV written to $statusCsvPath"
} finally {
    if ($transcriptStarted) { Stop-Transcript | Out-Null }
}
```

