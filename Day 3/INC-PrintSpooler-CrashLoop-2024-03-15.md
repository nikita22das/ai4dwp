# Incident Report — Print Spooler Service Crash Loop

| Field | Detail |
|---|---|
| **Report Reference** | INC-PRINT-2024-0315-001 |
| **Classification** | Internal Use Only |
| **Incident Date** | 2024-03-15 |
| **Report Date** | 2024-03-15 |
| **Prepared By** | DWP Endpoint Support — Analyst |
| **Reviewed By** | DWP Engineering |
| **Status** | Under Investigation |
| **Severity** | High |
| **Service Affected** | Windows Print Spooler (`spoolsv.exe`) |
| **Source Host** | Not specified in log extract — confirm with Service Desk ticket |

---

## 1. Executive Summary

On 2024-03-15, commencing at 10:01:14, the Windows Print Spooler service entered a crash loop on an affected DWP endpoint. The service terminated unexpectedly four times in under two minutes before the Service Control Manager (SCM) triggered its configured automatic recovery action. The subsequent restart attempt also failed, this time surfacing two distinct and compounding errors: a missing module (DLL or print driver file) that the service could not load, and a Group Policy-enforced logon restriction that prevented the SYSTEM account from starting the service.

The result is that the Print Spooler is fully non-functional and cannot self-recover. All printing on the affected endpoint is unavailable. Manual engineering intervention is required to resolve both the missing module and the policy misconfiguration before the service can be restored.

The primary root cause is a missing or corrupted print driver module (`ERROR_MOD_NOT_FOUND`). A secondary and compounding cause is a Group Policy Object (GPO) that has applied a logon type restriction to the `NT AUTHORITY\SYSTEM` account, which is abnormal under standard Windows configuration and blocks all automatic recovery attempts.

---

## 2. Timeline of Events

| # | Timestamp | Event ID | Source | Description |
|---|---|---|---|---|
| 1 | 2024-03-15 10:01:14 | 7034 | Service Control Manager | Print Spooler terminated unexpectedly — 1st occurrence. No recovery action triggered. |
| 2 | 2024-03-15 10:01:45 | 7034 | Service Control Manager | Print Spooler terminated unexpectedly — 2nd occurrence (~31 s after first crash). Service restarted and crashed again almost immediately. |
| 3 | 2024-03-15 10:02:16 | 7034 | Service Control Manager | Print Spooler terminated unexpectedly — 3rd occurrence (~31 s pattern continues). Consistent with a driver load failure at service initialisation. |
| 4 | 2024-03-15 10:02:47 | 7031 | Service Control Manager | Print Spooler terminated unexpectedly — 4th occurrence. SCM failure threshold reached. Corrective action scheduled: restart service in 60,000 ms (60 seconds). |
| 5 | 2024-03-15 10:03:49 | 7023 | Service Control Manager | SCM executes the scheduled restart (~62 s after event 4). Service terminates with a specific Win32 error: **"The specified module could not be found"** (0x7E / `ERROR_MOD_NOT_FOUND`). |
| 6 | 2024-03-15 10:03:50 | 7038 | Service Control Manager | One second after event 5, the SCM attempts to re-authenticate the service account. `NT AUTHORITY\SYSTEM` is denied: **"Logon failure: the user has not been granted the requested logon type at this computer."** Service cannot start. Crash loop ends — service is now stuck in a stopped state. |

**Duration of active crash loop:** ~2 minutes 35 seconds (10:01:14 to 10:03:49).  
**Service state at end of sequence:** Stopped. Cannot restart without manual intervention.

---

## 3. Event ID Analysis

### 3.1 Event ID 7034 — Service Terminated Unexpectedly

- **Source:** Service Control Manager
- **Level:** Error
- **What it records:** The SCM detected that the service process exited without sending the SCM an orderly stop notification. The SCM increments an internal crash counter each time this occurs. This event does not contain a specific error code — it records the fact of the crash and the cumulative count only.
- **Significance in this incident:** Fired three times in under 90 seconds, establishing a consistent ~31-second crash interval. This pattern is characteristic of a service that starts, attempts to load a dependency, fails, and exits before completing initialisation.

### 3.2 Event ID 7031 — Service Terminated Unexpectedly (Recovery Action Configured)

- **Source:** Service Control Manager
- **Level:** Error
- **What it records:** Functionally equivalent to 7034 but additionally logs the recovery action that has been configured for this failure count threshold. In this incident the action is "Restart the service" with a delay of 60,000 milliseconds.
- **Significance in this incident:** Confirms that failure recovery was configured and that the SCM will attempt a restart. This is the trigger for the events that follow at 10:03:49 and 10:03:50.

### 3.3 Event ID 7023 — Service Terminated with Error Code

- **Source:** Service Control Manager
- **Level:** Error
- **What it records:** The service process exited and returned a specific Win32 error code to the SCM. The SCM records the human-readable error string alongside the event.
- **Error recorded:** `"The specified module could not be found"` — Win32 error code **0x7E** (`ERROR_MOD_NOT_FOUND`).
- **Significance in this incident:** This is the most diagnostically important event in the log. It confirms that the crashes are driven by a missing file — a DLL, executable, or driver module that `spoolsv.exe` or a hosted print driver attempted to load and could not locate. This error would have been the underlying cause of all preceding 7034 events, but was not captured until this point.

### 3.4 Event ID 7038 — Service Logon Failure

- **Source:** Service Control Manager
- **Level:** Error
- **What it records:** The SCM attempted to start the service under its configured logon account and the Local Security Authority (LSA) rejected the authentication.
- **Account:** `NT AUTHORITY\SYSTEM`
- **Error recorded:** `"Logon failure: the user has not been granted the requested logon type at this computer."`
- **Significance in this incident:** This event is highly abnormal. `NT AUTHORITY\SYSTEM` is a built-in Windows identity that does not use passwords. A logon failure for this account is almost exclusively caused by an explicit User Rights Assignment (URA) restriction applied via Local Security Policy or GPO. Under default Windows configuration this event should never occur for the Print Spooler service. Its presence strongly indicates a GPO misconfiguration affecting this machine.

---

## 4. Service Failure Analysis

### 4.1 Crash Pattern

The consistent ~31-second interval between the first three crashes (7034 events) suggests a deterministic failure mode rather than a resource contention or timing issue. The service is not hanging — it is starting, reaching a specific point in its initialisation sequence, failing, and exiting cleanly enough for the SCM to record the termination each time.

Print Spooler initialisation includes loading all registered print drivers into memory. If a driver references a DLL that does not exist on disk, the load will fail immediately and reproducibly on every start attempt.

### 4.2 Recovery Mechanism Behaviour

The SCM's built-in failure recovery (Event ID 7031) functioned as configured — it scheduled and executed a restart after 60 seconds. However, the recovery attempt encountered the same module failure (7023) and was further blocked by the logon restriction (7038). The SCM's recovery mechanism has no capability to repair missing files or override security policy; once both errors are present, automatic recovery is exhausted.

### 4.3 Driver Isolation Context

The Windows Print Spooler can load printer drivers either in-process (within `spoolsv.exe`) or in an isolated host process (`PrintIsolationHost.exe`). If the driver is loaded in-process and its DLL is missing, `spoolsv.exe` itself will crash — producing the 7034 events observed. If driver isolation were enabled for the faulty driver, the crash would typically be contained to the isolation host rather than the spooler. The in-process crash pattern observed here suggests the faulty driver was running in-process.

> **Verify:** Confirm driver isolation setting for the suspect driver via `printmanagement.msc` or `Get-PrinterDriver | Select-Object Name, PrinterEnvironment`.

---

## 5. Authentication Failure Analysis

### 5.1 Why This Event Is Abnormal

`NT AUTHORITY\SYSTEM` is not a conventional user account. It does not authenticate using credentials in the traditional sense. The Print Spooler service is configured by default to run as `LocalSystem`, which maps to `NT AUTHORITY\SYSTEM`. Under normal Windows configuration, the SYSTEM account has implicit rights to log on as a service and log on locally. The Windows SCM does not require an explicit User Rights Assignment for SYSTEM under default conditions.

### 5.2 Most Likely Cause of the Logon Failure

The error `"the user has not been granted the requested logon type"` maps to a User Rights Assignment restriction. The two most likely GPO-applied settings causing this are:

| GPO Setting | Policy Path | Effect if SYSTEM is listed |
|---|---|---|
| `Deny log on as a service` (`SeDenyServiceLogonRight`) | Computer Config > Windows Settings > Security Settings > Local Policies > User Rights Assignment | Explicitly blocks SYSTEM from the service logon type |
| `Deny log on locally` (`SeDenyInteractiveLogonRight`) | Same path as above | Blocks SYSTEM from interactive logon; may affect service start depending on Windows version and service type |

A third possibility is that a GPO has explicitly defined `Log on as a service` (`SeServiceLogonRight`) with a restricted list of accounts that does not include SYSTEM, overriding the built-in default.

### 5.3 Implications

The authentication failure is a compounding factor, not the primary cause of the crash loop. However, it means that even if the missing module were restored, the service would still fail to start on this machine until the GPO restriction is corrected. Both issues must be resolved in sequence.

---

## 6. Technical Findings

| # | Finding | Confidence | Evidence |
|---|---|---|---|
| F-01 | Print Spooler entered a crash loop on 2024-03-15 from 10:01:14 | Confirmed | Event IDs 7034 (×3) and 7031 (×1) |
| F-02 | The service crashes every ~31 seconds, consistent with a deterministic load failure | High | Timestamps of 7034 events |
| F-03 | A required module (DLL or driver file) is missing or unreachable | Confirmed | Event ID 7023 — `ERROR_MOD_NOT_FOUND` |
| F-04 | The missing module is the root cause of all crashes | High | 7023 on the recovery restart; same error code would apply to all preceding crashes |
| F-05 | A GPO is restricting the SYSTEM account's logon rights on this machine | High | Event ID 7038 — logon type not granted for `NT AUTHORITY\SYSTEM` |
| F-06 | The GPO restriction blocks all automatic recovery attempts | Confirmed | 7038 fires immediately after 7023 on the recovery restart |
| F-07 | The service is currently stopped and cannot self-recover | Confirmed | No further service start events in the log after 10:03:50 |
| F-08 | Scope of the GPO fault is unknown — may affect other machines in the same OU | Unconfirmed | Requires AD/GPO investigation |

---

## 7. Most Likely Root Cause

**A corrupted, deleted, or missing print driver DLL or its dependency, combined with a GPO misconfiguration that prevents automatic service recovery.**

The crash loop is driven by `ERROR_MOD_NOT_FOUND` — a file that the Print Spooler or a hosted print driver requires is not present on disk or is not accessible via the system DLL search path. This is the direct cause of every service crash from 10:01:14 onwards.

The GPO logon restriction (`NT AUTHORITY\SYSTEM` denied logon type) is a secondary compounding fault that prevents the SCM from recovering the service even after the module failure is addressed. This is almost certainly an unintentional GPO configuration — either a security hardening policy was applied without accounting for built-in Windows service accounts, or a URA policy was modified and SYSTEM was inadvertently omitted or added to a Deny list.

The most probable sequence of causation:
1. A print driver was installed or updated, introducing or leaving behind a broken DLL reference.
2. OR a Windows Update or system change removed a DLL that an existing driver still references.
3. The spooler crashes on every start attempt because of the missing DLL.
4. A separately applied GPO (possibly predating this incident or applied as part of a hardening exercise) blocks SYSTEM's logon type, which prevents recovery.

---

## 8. Alternative Root Cause Theories

### Theory A — Windows Update Removed a System DLL
A recent cumulative update or security patch may have replaced or removed a DLL that a legacy print driver references. This is consistent with `ERROR_MOD_NOT_FOUND` and would explain why the failure appeared suddenly rather than gradually.

**Supporting indicators:** Check Windows Update history (`Get-HotFix`) and cross-reference the date of the most recent update with 2024-03-15.  
**Against this theory:** System DLLs are rarely removed entirely by updates; version mismatches are more common.

### Theory B — Third-Party Print Management Software Partially Uninstalled
If a third-party print management or monitoring agent was removed or upgraded, its DLL may have been deleted while a driver entry still references it in the registry.

**Supporting indicators:** Check installed software list (`Get-Package`) and correlate any recent changes with 2024-03-15.  
**Against this theory:** No third-party software is confirmed in the available logs.

### Theory C — Manual or Scripted Driver Removal Left Orphaned Registry Entries
An administrator may have manually deleted driver files from `%SystemRoot%\System32\spool\drivers\` without removing the corresponding registry entries or using the correct uninstall procedure. The spooler then fails when it tries to load the orphaned driver on startup.

**Supporting indicators:** Examine the `HKLM\SYSTEM\CurrentControlSet\Control\Print\Environments` registry key for driver entries that reference non-existent file paths.  
**Against this theory:** Speculative without change history.

### Theory D — File System Corruption
The module file exists on disk but is unreadable due to file system corruption (bad sectors, NTFS corruption).

**Supporting indicators:** `ERROR_MOD_NOT_FOUND` can in rare cases be returned when a file is present but inaccessible; CHKDSK or SFC output would confirm.  
**Against this theory:** `ERROR_MOD_NOT_FOUND` more typically indicates a genuinely absent file. Corruption would more commonly produce `ERROR_ACCESS_DENIED` or CRC errors. This theory requires SFC/CHKDSK results to assess.

---

## 9. Evidence Supporting Root Cause

| Evidence | How It Supports the Root Cause |
|---|---|
| Event ID 7023 with `ERROR_MOD_NOT_FOUND` | Directly confirms a required module is missing at the point of service initialisation |
| Consistent ~31-second crash interval across events 1–4 | Indicates a deterministic failure at a fixed point in the startup sequence (e.g. driver load), not a resource or timing issue |
| No 7009 (service timeout) or 7000 (service failed to start — dependency) events | Eliminates dependency services as the cause; the spooler started and crashed rather than failing to start |
| Event ID 7038 for `NT AUTHORITY\SYSTEM` | Confirms an abnormal GPO-enforced logon restriction is preventing recovery |
| No events after 10:03:50 | Confirms the service is stuck and no further automatic recovery is occurring |

---

## 10. Impact Assessment

### 10.1 Severity

| Attribute | Detail |
|---|---|
| **Overall Severity** | **High** |
| **Service State** | Fully stopped — not degraded, fully unavailable |
| **Self-Recovery Possible** | No — blocked by both missing module and logon restriction |
| **Data Loss Risk** | Low — queued print jobs in the spool directory will be lost on clearance; no user data at risk |
| **Potential Fleet-Wide Scope** | Yes — if the GPO fault applies to a wider OU, multiple endpoints may be silently affected |

### 10.2 Business Impact

- All printing on the affected endpoint is completely unavailable.
- If this machine hosts shared print queues, the impact extends to all users mapped to those queues.
- Automated print workflows (scheduled reports, batch document output, application print jobs) will fail silently.
- In a DWP operational context, roles dependent on physical document output — casework, correspondence, benefit decision letters, interview documentation — face direct disruption.

### 10.3 User Impact

| User Group | Impact |
|---|---|
| Desktop user on affected endpoint | Cannot print; all jobs fail or queue without delivery |
| Users mapped to shared queues on this machine | Unable to print; jobs silently accumulate |
| Users with automated print workflows | Outputs fail; users may not be aware until checking trays |
| IT Service Desk | Expected spike in printer fault tickets |

**User workaround:** Redirect to an alternative printer or print server while fault is resolved. Communicate this to affected users immediately.

### 10.4 Printing and Document Processing Impact

| Function | Status |
|---|---|
| Desktop printing (local and network) | Unavailable |
| Print-to-PDF / virtual driver-based printing | Potentially affected |
| Fax via Windows Fax and Scan (Spooler-dependent) | Unavailable |
| Automated application print jobs | Failing |
| Print job audit trail | Gap in audit log from 10:01:14 onwards |

---

## 11. Ranked Remediation Plan

### Remediation Step 1 — Identify and Remove the Faulty Print Driver *(Highest Priority)*

**Owner:** DWP Engineering  
**Rationale:** Directly resolves `ERROR_MOD_NOT_FOUND` — the primary root cause.

```powershell
# Step 1: Stop the Spooler
Stop-Service -Name Spooler -Force

# Step 2: List installed drivers and their file paths
Get-PrinterDriver | Select-Object Name, InfPath, DriverVersion | Format-List

# Step 3: Check the driver directory for missing DLLs
Get-ChildItem "$env:SystemRoot\System32\spool\drivers\x64" -Recurse -Filter "*.dll" |
  Select-Object FullName, LastWriteTime

# Step 4: Remove the suspect driver (replace <DriverName> with identified driver)
Remove-PrinterDriver -Name "<DriverName>"

# Step 5: Clear the spool queue
Remove-Item "$env:SystemRoot\System32\spool\PRINTERS\*" -Force

# Step 6: Restart the Spooler and verify
Start-Service -Name Spooler
Get-Service -Name Spooler
```

Monitor Event Viewer for recurrence of 7023 after restart.

> **Verify:** [Troubleshoot print spooler errors — Microsoft Learn](https://learn.microsoft.com/en-us/troubleshoot/windows-server/printing/troubleshoot-print-spooler-errors)

---

### Remediation Step 2 — Correct the GPO User Rights Assignment *(Required in Parallel)*

**Owner:** DWP Engineering / GPO/AD Team  
**Rationale:** Resolves the 7038 logon failure. Without this fix, the service will fail to start even after the module is restored.  
**Note:** GPO changes require change control approval before implementation.

```cmd
REM Generate GP result report
gpresult /H C:\Temp\gpresult.html

REM Review applied URA settings
secedit /export /cfg C:\Temp\secpol.cfg
findstr /i "SeDenyServiceLogonRight SeServiceLogonRight SeDenyInteractiveLogonRight" C:\Temp\secpol.cfg
```

In Group Policy Management Console (`gpmc.msc`):
1. Identify the GPO setting `Deny log on as a service` or a restricted `Log on as a service` list.
2. Ensure `NT AUTHORITY\SYSTEM` is not present in any Deny right.
3. If `Log on as a service` is explicitly defined, confirm SYSTEM is included (or remove the explicit definition to restore the Windows default).
4. Apply change via change control, then run `gpupdate /force` on the affected machine and restart the Spooler.

> **Verify:** [Log on as a service — Microsoft Learn](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/log-on-as-a-service)

---

### Remediation Step 3 — Run SFC and DISM *(If Step 1 Does Not Resolve the Module Error)*

**Owner:** DWP Engineering  
**Rationale:** If the missing module is a Windows system DLL (rather than a third-party driver DLL), SFC/DISM can restore it from the Windows image.

```cmd
sfc /scannow
DISM /Online /Cleanup-Image /RestoreHealth
```

Review `%WinDir%\Logs\CBS\CBS.log` for files that were repaired or could not be repaired. Restart and retest the Spooler.

> **Verify:** [Use the System File Checker tool — Microsoft Support](https://support.microsoft.com/en-us/topic/use-the-system-file-checker-tool-to-repair-missing-or-corrupted-system-files-79aa86cb-ca52-166a-92a3-966e85d4094e)

---

### Remediation Step 4 — Review Recent Windows and Driver Updates *(Investigative)*

**Owner:** DWP Engineering  
**Rationale:** Correlate the start of the crash loop (10:01:14) with recent update activity to confirm or rule out an update-triggered DLL removal.

```powershell
Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10
```

If a recent update is correlated, assess whether rollback is appropriate or whether the driver vendor needs to be contacted for an updated driver package.

---

### Remediation Step 5 — Check Fleet-Wide Scope *(Risk Mitigation)*

**Owner:** DWP Engineering  
**Rationale:** If the GPO fault applies to a wider OU scope, other endpoints may be silently affected.

```powershell
# Query Spooler status across a list of endpoints
Invoke-Command -ComputerName (Get-Content C:\Temp\endpoints.txt) -ScriptBlock {
  Get-Service -Name Spooler | Select-Object Name, Status, MachineName
}
```

If multiple endpoints show a stopped Spooler, escalate to P1 and engage the GPO/AD team immediately.

---

### Remediation Step 6 — Verify Spooler Service Configuration Integrity *(If All Above Steps Fail)*

**Owner:** DWP Engineering  
**Rationale:** In rare cases, registry corruption can cause the service binary path or logon account to be incorrect.

```cmd
sc qc Spooler
```

Expected output:
- `BINARY_PATH_NAME`: `%SystemRoot%\System32\spoolsv.exe`
- `SERVICE_START_NAME`: `LocalSystem`

If either is incorrect, restore defaults:
```cmd
sc config Spooler binPath= "%SystemRoot%\System32\spoolsv.exe" obj= LocalSystem
```

> **Verify:** [Configure service startup type — Microsoft Learn](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/sc-config)

---

## 12. Preventive Actions

| # | Action | Owner | Priority |
|---|---|---|---|
| P-01 | Establish a baseline inventory of all installed print drivers across the fleet. Document driver names, versions, vendor, and associated DLL paths. | DWP Engineering | High |
| P-02 | Enable Print Spooler driver isolation for all third-party drivers. This contains crashes to `PrintIsolationHost.exe` rather than crashing `spoolsv.exe` itself. | DWP Engineering | High |
| P-03 | Audit all GPOs that modify User Rights Assignments before deployment. Ensure SYSTEM is never added to a Deny right and is not inadvertently excluded from `SeServiceLogonRight` if explicitly defined. | GPO/AD Team | High |
| P-04 | Implement proactive monitoring for Event IDs 7034, 7031, 7023, and 7038 via SIEM or endpoint monitoring tooling. Alert on first occurrence rather than waiting for user reports. | DWP Engineering | Medium |
| P-05 | Test Windows Updates in a pre-production ring before fleet-wide deployment. Include a print test in the post-update validation checklist. | DWP Engineering | Medium |
| P-06 | Document a standard print driver removal procedure. Require use of `printui /s /t2` or `Remove-PrinterDriver` rather than manual file deletion to prevent orphaned registry entries. | DWP Engineering | Medium |
| P-07 | Review the recovery action configuration for the Print Spooler service on managed endpoints. Ensure failure recovery is set to restart on all three failure counts, with an appropriate reset interval. | DWP Engineering | Low |

---

## 13. Lessons Learned

| # | Lesson |
|---|---|
| L-01 | `ERROR_MOD_NOT_FOUND` (0x7E) in a 7023 event for the Print Spooler almost always indicates a missing or orphaned print driver DLL. Starting diagnosis with driver enumeration and file path validation is faster than generic SFC/DISM runs. |
| L-02 | Event ID 7038 for `NT AUTHORITY\SYSTEM` is never expected under default Windows configuration. When it appears, the immediate investigative path is GPO User Rights Assignments — not service account credentials. |
| L-03 | Crash loop incidents require two parallel investigations: (a) what is causing the crash, and (b) what is preventing recovery. Both must be resolved before the service will run. Fixing only the crash cause may leave the logon restriction in place and the service still unable to start. |
| L-04 | GPO hardening policies that modify User Rights Assignments can inadvertently affect built-in Windows service accounts. All URA GPO changes should be peer-reviewed against a list of Windows built-in service accounts (`SYSTEM`, `LOCAL SERVICE`, `NETWORK SERVICE`) before deployment. |
| L-05 | A consistent crash interval (here ~31 seconds) is a strong indicator of a deterministic load failure at service initialisation, not an intermittent fault. This pattern should direct investigation toward startup dependencies (drivers, DLLs) rather than runtime conditions. |
| L-06 | Enabling Print Spooler driver isolation is a direct mitigation that limits the blast radius of future driver faults. It should be a standard endpoint configuration in managed DWP environments. |

---

## 14. References to Verify Against Microsoft Documentation

The following references were used in the preparation of this report. All should be verified against current Microsoft documentation before being used as the basis for change actions, as guidance and behaviour may vary by Windows version or update level.

| Reference | URL | Purpose |
|---|---|---|
| Troubleshoot Print Spooler errors | https://learn.microsoft.com/en-us/troubleshoot/windows-server/printing/troubleshoot-print-spooler-errors | Driver removal, spooler restart procedures, ERROR_MOD_NOT_FOUND context |
| Print Spooler architecture and driver isolation | https://learn.microsoft.com/en-us/windows-hardware/drivers/print/print-spooler-architecture | In-process vs isolated driver loading behaviour |
| Log on as a service (SeServiceLogonRight) | https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/log-on-as-a-service | Default SYSTEM behaviour; URA policy interaction |
| User Rights Assignment documentation | https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-rights-assignment | Full list of URA settings and their defaults |
| Use the System File Checker tool | https://support.microsoft.com/en-us/topic/use-the-system-file-checker-tool-to-repair-missing-or-corrupted-system-files-79aa86cb-ca52-166a-92a3-966e85d4094e | SFC usage and CBS.log interpretation |
| Repair a Windows image (DISM) | https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/repair-a-windows-image | DISM /RestoreHealth usage and requirements |
| Remove a printer driver | https://learn.microsoft.com/en-us/windows-hardware/drivers/print/removing-a-printer-driver | Safe driver removal procedure |
| sc config command reference | https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/sc-config | Restoring service binary path and logon account |
| Service Control Manager event IDs | https://learn.microsoft.com/en-us/windows/security/threat-protection/auditing/basic-audit-system-events | Event ID 7023, 7031, 7034, 7038 definitions |
| Print driver isolation | https://learn.microsoft.com/en-us/windows-hardware/drivers/print/printer-driver-isolation | Enabling and configuring driver isolation |

---

*Report Reference: INC-PRINT-2024-0315-001 | Classification: Internal Use Only | DWP Endpoint Support*
