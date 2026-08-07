# Exercise 2 — Print Spooler Crash Analysis

**Analyst:** DWP Endpoint Support  
**Date:** 2024-03-15  
**Scope:** Windows System Event Log — Print Spooler crash loop  
**Source Host:** (endpoint not specified in log extract)

---

## 1. Distinct Event IDs Identified

| Event ID | Source | Level | Count in Log |
|----------|--------|-------|--------------|
| 7034 | Service Control Manager | Error | 3 |
| 7031 | Service Control Manager | Error | 1 |
| 7023 | Service Control Manager | Error | 1 |
| 7038 | Service Control Manager | Error | 1 |

---

## 2. What Each Event ID Records

### Event ID 7034 — Service Terminated Unexpectedly
Logged by the Service Control Manager (SCM) when a service process exits without notifying the SCM of an orderly shutdown. The SCM increments a counter each time this happens. No recovery action is triggered by this event alone; it is purely informational about the crash count.

### Event ID 7031 — Service Terminated Unexpectedly (with Recovery Action)
Functionally identical to 7034 but additionally records the configured recovery action. In this case the SCM is configured to restart the service after 60,000 ms (60 seconds). This event fires when the crash count reaches the threshold at which a recovery action is defined in the service's failure settings.

### Event ID 7023 — Service Terminated with Error
Records that the service process exited and returned a specific Win32 error code to the SCM. The error reported here is **"The specified module could not be found"** (Win32 error 0x7E / ERROR_MOD_NOT_FOUND). This means a DLL or executable that the service (or one of its print drivers) attempted to load was not present on disk or was not accessible via the system PATH.

### Event ID 7038 — Service Logon Failure
Records that the SCM attempted to start the service under its configured account and the logon was rejected by the Local Security Authority (LSA). The account here is `NT AUTHORITY\SYSTEM`. The error is **"Logon failure: the user has not been granted the requested logon type at this computer."** This indicates a User Rights Assignment (URA) policy is preventing the SYSTEM account from using the required logon type.

> **Note:** `NT AUTHORITY\SYSTEM` having a logon failure is highly abnormal. This account is built into Windows and is not subject to password policies; a logon failure for this account almost always points to a Group Policy Object (GPO) that has explicitly restricted one of the "Log on as a service", "Log on locally", or "Allow log on locally" user rights, or has added SYSTEM to a "Deny" right — which would be an unusual and likely unintentional configuration.

---

## 3. What Each Error Message Means

| Error Message | Meaning |
|---|---|
| "The Print Spooler service terminated unexpectedly. It has done this N time(s)." | The spooler process exited abnormally. The SCM is counting crashes. No specific cause is given in this event alone. |
| "The following corrective action will be taken in 60000 milliseconds: Restart the service." | The SCM's configured failure recovery action has been triggered. It will attempt to restart the service after a 1-minute delay. |
| "The specified module could not be found." | A required DLL, driver file, or executable cannot be located. The spooler itself or a third-party or native print driver it hosts is referencing a file that is absent or unreachable. |
| "Logon failure: the user has not been granted the requested logon type at this computer." | The SYSTEM account is being denied the logon type required to start a service. This is a permissions/policy issue at the OS level, not a credential issue. |

---

## 4. Chronological Sequence of Events

| Timestamp | Event ID | Description |
|---|---|---|
| 10:01:14 | 7034 | Print Spooler crashes for the 1st time. SCM records the unexpected termination; no recovery action yet. |
| 10:01:45 | 7034 | Print Spooler crashes for the 2nd time (approximately 31 seconds later). The service was restarted manually or automatically and crashed again almost immediately. |
| 10:02:16 | 7034 | 3rd crash, again roughly 31 seconds after the previous. The pattern is consistent — something is causing rapid failure on startup. |
| 10:02:47 | 7031 | 4th crash. This is the threshold at which the SCM's configured recovery action fires. The SCM schedules a restart attempt in 60 seconds. |
| 10:03:49 | 7023 | The SCM's restart attempt executes (~62 seconds after 10:02:47). The service terminates with a specific error: a required module cannot be found. This is the first event that reveals a **concrete error code** — the crashes above were likely caused by the same missing module, but the code was not captured until this point. |
| 10:03:50 | 7038 | One second after the module-not-found error, the SCM records a logon failure for `NT AUTHORITY\SYSTEM`. This suggests that during or after the module failure, the SCM attempted to reinitialise the service under its configured account and was denied by a URA policy. |

**Plain-English Summary:**  
The Print Spooler started, immediately crashed, restarted automatically, and crashed again in a rapid loop. After four crashes the SCM invoked its configured recovery action (restart after 60 s). On that recovery restart, the SCM finally recorded a specific reason: a required DLL or module was missing. Simultaneously, a Group Policy restriction prevented the SYSTEM account from logging on with the required logon type, blocking any further restart attempt. The service is now stuck — it cannot load its dependencies and cannot log on to try again.

---

## 5. Root Cause Identification

### Primary Root Cause — Missing Module (DLL/Driver)

**Evidence:** Event ID 7023 explicitly records `ERROR_MOD_NOT_FOUND`. The Print Spooler service hosts print drivers in-process (or in a separate `PrintIsolationHost.exe` process). A corrupted, deleted, or renamed printer driver DLL — or a system file dependency of that driver — is the most likely cause of every crash in this log. The consistent ~31-second crash interval before recovery action suggests the service starts, attempts to load the driver, fails, and exits cleanly enough for the SCM to record it.

**Supporting evidence:** The three preceding 7034 events showed a consistent rapid crash pattern before the specific error was logged, consistent with a driver load failure on service initialisation.

### Secondary Contributing Cause — SYSTEM Account Logon Right Restriction (GPO)

**Evidence:** Event ID 7038 records `NT AUTHORITY\SYSTEM` being denied logon. This is abnormal under default Windows configuration. The most common cause is a GPO that has been applied to the machine which defines explicit "Deny" user rights assignments or has replaced the default "Log on as a service" grant without including SYSTEM. This would prevent even a successful driver fix from resolving the issue unless the policy is also corrected.

---

## 6. Issue Classification

**Verdict: Combination of multiple issues**

| Issue Type | Present? | Evidence |
|---|---|---|
| Service crash (crash loop) | Yes | 7034/7031 — repeated unexpected terminations |
| Missing dependency / module | Yes (primary) | 7023 — ERROR_MOD_NOT_FOUND |
| Service account / permissions | Yes (secondary) | 7038 — SYSTEM logon denied |
| Group Policy issue | Likely (secondary) | 7038 — logon type restriction is typically GPO-driven |
| Corruption | Possible | Missing module may be caused by file corruption or partial update; unconfirmed |

**Reasoning:**  
The crash loop is a symptom, not a cause. The underlying driver is the engine causing the crashes. The SYSTEM logon failure compounds the issue by preventing automatic recovery. If only the missing module were present, the service might recover. If only the GPO issue existed, the service would fail to start but would not crash in a loop. The combination means both must be addressed.

---

## 7. Ranked Remediation Plan

### Step 1 — Identify and Remove/Reinstall the Faulty Print Driver (Highest Priority)

**Rationale:** Directly addresses the `ERROR_MOD_NOT_FOUND` root cause.

**Checks:**
1. Stop the Print Spooler service: `Stop-Service -Name Spooler`
2. Open `%SystemRoot%\System32\spool\drivers\` and inspect subfolders (`W32X86`, `x64`, `3`). Look for driver folders referencing missing DLL files.
3. Open Print Management (`printmanagement.msc`) and note all installed drivers.
4. Remove suspect drivers: `printui /s /t2` or via PowerShell: `Get-PrinterDriver | Remove-PrinterDriver`
5. Clear the spool queue: delete all files in `%SystemRoot%\System32\spool\PRINTERS\`
6. Restart the Spooler: `Start-Service -Name Spooler`
7. Monitor Event Viewer for recurrence of 7023.

> **Verify against Microsoft Docs:** [Troubleshoot print spooler errors](https://learn.microsoft.com/en-us/troubleshoot/windows-server/printing/troubleshoot-print-spooler-errors) — confirm driver isolation settings and supported removal procedures.

---

### Step 2 — Run System File Checker and DISM (If Step 1 Does Not Resolve)

**Rationale:** If the missing module is a Windows system DLL rather than a third-party driver, file corruption may be the cause.

**Checks:**
1. Run `sfc /scannow` and review `%WinDir%\Logs\CBS\CBS.log` for repaired or unrepairable files.
2. Run `DISM /Online /Cleanup-Image /RestoreHealth` to repair the Windows image from Windows Update.
3. Restart and re-test the Spooler.

> **Verify against Microsoft Docs:** [Use the System File Checker tool](https://support.microsoft.com/en-us/topic/use-the-system-file-checker-tool-to-repair-missing-or-corrupted-system-files-79aa86cb-ca52-166a-92a3-966e85d4094e)

---

### Step 3 — Review and Correct Group Policy User Rights Assignments

**Rationale:** Addresses the 7038 logon failure. Even after fixing the module issue, a SYSTEM logon denial will prevent service recovery.

**Checks:**
1. On the affected machine, run `gpresult /H C:\Temp\gpresult.html` and open the report.
2. Search for **User Rights Assignment** settings under Computer Configuration. Check:
   - `Deny log on as a service` — SYSTEM must not appear here.
   - `Deny log on locally` — SYSTEM must not appear here.
   - `Log on as a service` — if explicitly configured, SYSTEM must be present.
3. Identify the GPO applying the restriction (look for the GPO name in the Applied GPOs section).
4. In Group Policy Management Console (`gpmc.msc`), open the identified GPO and review `Computer Configuration > Windows Settings > Security Settings > Local Policies > User Rights Assignment`.
5. Remove SYSTEM from any "Deny" right or add it to `Log on as a service` as appropriate.
6. Force GP update: `gpupdate /force` and restart the Spooler.

> **Verify against Microsoft Docs:** [Service accounts and User Rights Assignments](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/log-on-as-a-service) — confirms that SYSTEM should not normally need to be explicitly listed but must not be explicitly denied.

---

### Step 4 — Check for Recent Windows or Driver Updates

**Rationale:** A Windows Update or driver package update may have replaced or removed a DLL that an existing driver still references.

**Checks:**
1. Review Windows Update history: `Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 10`
2. Cross-reference the most recent update date with the first occurrence of 7034 (2024-03-15 10:01:14).
3. If a recent update correlates, consider using `wusa.exe /uninstall /kb:XXXXXXX` to roll back, or contact the driver vendor for an updated driver package.

---

### Step 5 — Verify Spooler Service Configuration Integrity

**Rationale:** In rare cases the service configuration in the registry can become corrupted, causing both the logon type to be set incorrectly and the binary path to be wrong.

**Checks:**
1. Verify the Spooler service binary path: `sc qc Spooler` — should show `%SystemRoot%\System32\spoolsv.exe`.
2. Verify the logon account: should be `LocalSystem` (i.e. NT AUTHORITY\SYSTEM).
3. If the path or account is wrong, restore defaults:
   ```cmd
   sc config Spooler binPath= "%SystemRoot%\System32\spoolsv.exe" obj= LocalSystem
   ```
4. Restart and test.

---

## 8. Assumptions

- The logs provided are complete and unedited. No earlier events (before 10:01:14) are assumed to exist that might indicate a prior cause.
- The endpoint is domain-joined and subject to GPO. The 7038 event is attributed to GPO rather than local policy because local policy misconfiguration of SYSTEM rights would be unusual in a managed environment.
- The ~31-second crash interval is assumed to be the service attempting to start and failing consistently, not indicative of an external trigger.
- The service's configured recovery action (restart after 60 s) was set prior to this incident, either by default or by a previous administrator.
- No third-party print management software is confirmed present; however, third-party drivers are considered a likely source of the missing module.

---

## 9. Items to Verify Against Microsoft Documentation

| Item | Reference Area |
|---|---|
| Default behaviour of NT AUTHORITY\SYSTEM and URA defaults | [User Rights Assignment documentation](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/user-rights-assignment) |
| Print Spooler driver isolation settings (in-process vs isolated) | [Print Spooler architecture and isolation](https://learn.microsoft.com/en-us/windows-hardware/drivers/print/print-spooler-architecture) |
| ERROR_MOD_NOT_FOUND (0x7E) in the context of spooler drivers | [Troubleshoot print spooler errors](https://learn.microsoft.com/en-us/troubleshoot/windows-server/printing/troubleshoot-print-spooler-errors) |
| Safe removal of print drivers while spooler is stopped | [Remove a printer driver from Windows](https://learn.microsoft.com/en-us/windows-hardware/drivers/print/removing-a-printer-driver) |
| DISM and SFC repair procedures | [Repair a Windows image](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/repair-a-windows-image) |

---

## 10. Business Impact

The Print Spooler is a core Windows service responsible for managing all print jobs and communication with print devices. When it is in a crash loop and cannot recover:

- **All printing on the affected endpoint is completely unavailable.** Users cannot print documents, letters, forms, or reports until the service is restored.
- **Shared printer queues hosted on this machine (if it is a print server) will also be unavailable**, extending the impact to every user mapped to those queues.
- **Automated print workflows** — such as scheduled report generation, batch document printing, or line-of-business application print outputs — will silently fail or queue without delivery.
- In a DWP context, roles that depend heavily on physical document output (casework, correspondence, benefit decisions, interview documentation) face direct operational disruption.
- If this machine serves as a departmental or floor-level print server, the impact multiplies across all connected users until resolved.

---

## 11. User Impact

| User Group | Impact |
|---|---|
| Individual desktop users on the affected endpoint | Cannot print any documents. All print jobs will fail or remain queued indefinitely. |
| Users mapped to shared print queues on this machine | Unable to print; jobs may silently queue without delivery or return errors in applications. |
| Users submitting automated/scheduled print jobs | Automated outputs will fail; users may not be aware until they check physical output trays. |
| IT/Service Desk | Likely to receive a spike in "printer not working" tickets from all affected users simultaneously. |

**Workaround available to users:** Redirect print jobs to an alternative printer or print server if one is available. Users should be informed of this option immediately while the fault is being investigated.

---

## 12. Severity Assessment

| Attribute | Assessment |
|---|---|
| **Severity** | **High** |
| **Service state** | Fully unavailable — crash loop with no automatic recovery possible |
| **Scope** | Single endpoint confirmed; potential fleet-wide impact if a GPO or update is the trigger |
| **Recovery without intervention** | No — automatic recovery is blocked by the SYSTEM logon failure (7038) |
| **Data loss risk** | Low — queued print jobs may be lost from the spool directory; no user data at risk |
| **Escalation trigger** | Escalate to DWP Engineering if GPO misconfiguration is confirmed or if multiple endpoints are affected |

**Justification:** The service is entirely non-functional and cannot self-heal. The combination of a missing module and a blocked logon type means no recovery attempt will succeed without manual intervention. If the GPO fault is present across a wider OU scope, multiple endpoints may be simultaneously affected without individual fault reports.

---

## 13. Printing and Document Processing Impact

| Function | Impact |
|---|---|
| Desktop printing (local and network printers) | Completely unavailable on affected endpoint |
| Print-to-PDF / virtual printers (if driver-based) | May also be affected if the driver DLL is the missing module |
| Fax services (if using Windows Fax and Scan via Spooler) | Unavailable |
| Automated report printing from line-of-business applications | Will fail silently or return application-level errors |
| Document scanning (if scanner drivers depend on Spooler) | Potentially affected depending on driver architecture |
| Print job auditing and logging | No new jobs are captured while the service is down; audit trail has a gap from 10:01:14 onwards |

Users should be advised not to retry print jobs repeatedly, as queued jobs accumulate in `%SystemRoot%\System32\spool\PRINTERS\` and will need to be cleared as part of the remediation process.

---

## 14. Recommended Service Desk Actions

These are immediate actions the Service Desk should take without requiring engineering-level access.

1. **Raise and categorise the incident** as a P2/High priority Windows service failure — Print Spooler. Record the affected hostname, user, and time of first report.
2. **Communicate to the user** that printing is unavailable and provide the nearest available alternative printer or print server as a workaround.
3. **Collect the event log evidence** — export the System event log from the affected machine (`eventvwr.msc > System > Save All Events As`) and attach to the incident ticket.
4. **Attempt a manual service restart** via Services console (`services.msc`):
   - Locate "Print Spooler"
   - Right-click > Restart
   - If it fails to start, note the exact error message and add to the ticket
   - Do not attempt repeated restarts if the first fails — this will not resolve the root cause
5. **Check whether other users/machines are reporting the same issue** — if so, escalate immediately as a potential fleet-wide GPO or update impact.
6. **Escalate to DWP Engineering** if the service does not start after one restart attempt, attaching the exported event log and incident notes.
7. **Do not attempt driver removal or registry edits** — these are engineering-level actions.

---

## 15. Recommended DWP Engineering Actions

These actions require elevated permissions and engineering-level knowledge of the environment.

1. **Identify the missing module:**
   - Stop the Spooler (`Stop-Service -Name Spooler`)
   - Enumerate installed print drivers: `Get-PrinterDriver | Select-Object Name, InfPath, DriverVersion`
   - Cross-reference driver DLL paths in `%SystemRoot%\System32\spool\drivers\x64\` against files present on disk
   - Use Process Monitor (Sysinternals) if the DLL name is not obvious — capture the spooler start attempt and filter for `NAME NOT FOUND` file system events

2. **Remove the faulty driver and clear the spool queue:**
   - With Spooler stopped, delete all files in `%SystemRoot%\System32\spool\PRINTERS\`
   - Remove the faulty driver: `Remove-PrinterDriver -Name "<driver name>"`
   - Restart the Spooler and confirm it starts cleanly

3. **Investigate the GPO causing 7038:**
   - Run `gpresult /H C:\Temp\gpresult.html` on the affected machine
   - Review User Rights Assignments for any "Deny" entries affecting SYSTEM
   - Identify the GPO by name and confirm its scope (which OUs it applies to)
   - Engage the GPO/AD team to correct the misconfigured right — **do not modify the GPO without change control approval**

4. **Check for fleet-wide exposure:**
   - Query other endpoints in the same OU using a remote PowerShell check:
     ```powershell
     Invoke-Command -ComputerName <list> -ScriptBlock { Get-Service Spooler | Select-Object Name, Status }
     ```
   - If multiple machines show a stopped Spooler, treat this as a P1 incident

5. **Run SFC/DISM if driver removal does not resolve 7023:**
   - `sfc /scannow` then `DISM /Online /Cleanup-Image /RestoreHealth`
   - Restart and retest

6. **Document all changes made** in the incident record for audit purposes.

---

## 16. Recommended Windows Service Troubleshooting Actions

These are general Windows-level diagnostic steps applicable to any service crash loop, recorded here for reference and reuse.

### Confirm Service State and Configuration
```powershell
# Check service status and startup type
Get-Service -Name Spooler | Select-Object Name, Status, StartType

# Check full service configuration including binary path and logon account
sc.exe qc Spooler
```

### Review Event Logs for the Service
```powershell
# Pull last 20 System events related to the Spooler or Service Control Manager
Get-WinEvent -LogName System -MaxEvents 200 |
  Where-Object { $_.ProviderName -eq 'Service Control Manager' -and $_.Message -match 'Spooler' } |
  Select-Object TimeCreated, Id, Message |
  Format-List
```

### Check for Dependency Failures
```powershell
# List services the Spooler depends on and their current state
(Get-Service -Name Spooler).DependentServices
(Get-Service -Name Spooler).ServicesDependedOn | Select-Object Name, Status
```

### Inspect the Spool Driver Directory
```powershell
# List driver folders — look for folders containing no DLL files or referencing missing paths
Get-ChildItem "$env:SystemRoot\System32\spool\drivers\x64" -Recurse -Filter "*.dll" |
  Select-Object FullName, LastWriteTime
```

### Check User Rights Assignments via Security Policy
```powershell
# Export local security policy to a text file for review
secedit /export /cfg C:\Temp\secpol.cfg
Select-String -Path C:\Temp\secpol.cfg -Pattern "SeServiceLogonRight|SeDenyServiceLogonRight"
```

### Capture a Process Monitor Trace (Sysinternals)
If the specific missing DLL cannot be identified from event logs alone:
1. Download and run **Process Monitor** (Sysinternals) as administrator.
2. Set a filter: `Process Name is spoolsv.exe` AND `Result is NAME NOT FOUND`.
3. Start the Spooler service and capture events.
4. The PATH column will reveal the exact file the process was unable to locate.

### Verify Group Policy Application
```cmd
gpresult /H C:\Temp\gpresult.html
gpresult /R
```
Review the output for User Rights Assignments and identify any GPO modifying `SeServiceLogonRight` or `SeDenyServiceLogonRight`.

---

*Report generated: 2024-03-15 | Classification: Internal Use Only*
