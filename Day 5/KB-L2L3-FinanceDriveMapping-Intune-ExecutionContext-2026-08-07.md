Version: 1.0
Date: 07/08/2026
Status: Draft

# KB Article: Finance Shared Drive Mapping Failure — Intune Execution Context Mismatch

## Audience
Desktop Engineering | Workplace Services | DWP Engineers

---

## Background

### Before Migration
Finance drive `S:` was mapped via a Group Policy Object (GPO) logon script. The script executed in the signed-in **user context**, meaning it ran under the interactive user's identity and session token. This gave the script access to user-scoped resources, including the Finance UNC path `\\finbridge-fs01\Finance`, at the point of logon.

### After Migration
The drive mapping was migrated from the GPO logon script to an Intune-delivered PowerShell script (`Map-FinBridgeDrives.ps1`). The Intune deployment was configured with `Run this script using the logged on credentials = No`, meaning the script executed as the local machine `SYSTEM` account. The `SYSTEM` account does not operate within the interactive user session, does not hold the user's access token, and cannot access user-scoped network resources such as mapped drives in the way a logon script can. The script logic was not updated to account for this change in execution context.

---

## Symptom

### User-reported symptoms
- Finance mapped drive `S:` was absent from File Explorer after signing in.
- All Finance users on `DESKTOP-FB*` devices were affected simultaneously from approximately 08:00 following the overnight migration.
- No other drives or services were reported missing.

### Engineer-observed symptoms
- Drive letter `S:` not present in `net use` output on affected endpoints.
- Intune Management Extension log showed `Map-FinBridgeDrives.ps1` executed and failed at script start with exit code `1`.
- Event Viewer System log showed Ntfs Event ID `98` confirming drive `S:` was not assigned.
- Group Policy processing confirmed healthy via Event ID `1500` — ruling out a GP layer failure.
- All ~45 Finance users affected simultaneously, indicating a central mechanism failure rather than isolated endpoint issues.

---

## Root Cause

### Verified root cause
Migration of the Finance drive mapping process from a user-context GPO logon script to an Intune PowerShell script configured to run as `SYSTEM`, without redesigning the script for `SYSTEM`-context execution.

### Why the failure occurred
The script attempted to access `\\finbridge-fs01\Finance` during machine-context execution, before the interactive user session was established. The `SYSTEM` account cannot create user-scoped mapped drives in this model. The script had no retry logic configured, so when the first attempt failed, no further attempt was made.

### Supporting evidence
| Evidence | Detail |
|---|---|
| Intune log — script context | `Map-FinBridgeDrives.ps1` executed as `SYSTEM` |
| Intune log — exit code | Script exited with code `1` |
| Intune log — error text | `Network name cannot be found` |
| Intune log — retry | No retry configured |
| System log — Event ID 1500 | Group Policy processed successfully — GP layer healthy |
| System log — Event ID 98 | Drive letter `S:` not assigned |
| Change record — 2024-03-14 23:30 | Mapping method changed from GPO user logon script to Intune `SYSTEM`-context deployment |

### Eliminated alternatives
- **Group Policy failure** — eliminated by GroupPolicy Event ID `1500` confirming successful policy processing.
- **Targeting failure** — eliminated because Intune script executed on affected devices (confirmed in IME log).
- **Isolated endpoint failure** — eliminated because all ~45 Finance users were affected simultaneously.
- **Share outage** — eliminated because users could access `\\finbridge-fs01\Finance` directly via UNC after the incident.

---

## Detection

Target: Confirm or rule out this issue within 3 minutes using the steps below in order.

---

### Step 1 — Read the Intune Management Extension log

**Log folder:** `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`
**Log file:** `IntuneManagementExtension.log`

**Fast PowerShell command — open log directly:**
```powershell
notepad "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log"
```

**Fast PowerShell command — extract all relevant lines in one pass:**
```powershell
Select-String -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" `
  -Pattern "Map-FinBridgeDrives|SYSTEM account|Network path not accessible|Network name cannot be found|exitCode"
```

**Confirm this issue if ALL three of the following exact strings appear in the output:**

| # | Exact string to find | Meaning |
|---|---|---|
| 1 | `Script context: SYSTEM account` | Script ran as machine account, not as the signed-in user |
| 2 | `Network path not accessible from SYSTEM context` | Drive UNC path unreachable in machine context |
| 3 | `Network name cannot be found` | OS-level failure to resolve or reach the share |

Additional indicators that confirm the failure:
- Exit code `1` immediately after `Map-FinBridgeDrives.ps1` execution block
- No retry entry following the failure

---

### Step 2 — Confirm execution context mismatch (USER vs SYSTEM)

**Prior implementation:** GPO logon script running in **USER context** — script executed inside the interactive user session with the signed-in user's identity and token. Drive mapping succeeded because the user's session was already active.

**Current implementation:** Intune PowerShell script `Map-FinBridgeDrives.ps1` running in **SYSTEM context** — script executed as the local machine account, outside the user's interactive session. Mapped drives are user-scoped resources and cannot be created from this context.

**Fast PowerShell command — confirm current Intune script context setting from the endpoint:**
```powershell
Get-Content "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log" |
  Select-String "RunAsAccount|RunningAs|context" | Select-Object -Last 10
```
Expected output if this issue is active: line containing `SYSTEM` as the run context for `Map-FinBridgeDrives.ps1`.

---

### Step 3 — Confirm in Intune portal (if log access is unavailable)

- **Portal:** `https://intune.microsoft.com`
- **Path:** `Devices > Scripts and remediations > Platform scripts > Map-FinBridgeDrives.ps1 > Properties`
- **Indicator:** `Run this script using the logged on credentials = No` — confirms `SYSTEM` context execution

---

### Step 4 — Confirm drive mapping failure in Windows Event Viewer

**Fast PowerShell command — query both Event IDs in one pass:**
```powershell
Get-WinEvent -LogName System |
  Where-Object { $_.Id -in @(1500, 98) } |
  Select-Object TimeCreated, Id, ProviderName, Message |
  Format-List
```

| Event ID | Source | Interpretation |
|---|---|---|
| `1500` | `GroupPolicy` | GP processed successfully — GP is **not** the failure layer |
| `98` | `Ntfs` | Drive letter `S:` was not assigned — direct evidence of mapping failure |

Timestamp at incident for Event ID 98: `08:00:07`

---

### Step 5 — Cross-check migration change record

- **Change timestamp:** `2024-03-14 23:30`
- **Change detail:** Mapping method changed from GPO user logon script (`USER` context) to Intune PowerShell script (`SYSTEM` context). Script was not updated to handle the new execution model.

---

## Resolution

1. Open `https://intune.microsoft.com` and go to `Devices > Scripts and remediations > Platform scripts`.
   Expected result: Platform scripts list is visible.

2. Click `Map-FinBridgeDrives.ps1`, then click `Assignments`.
   Expected result: Current assignment groups for the script are shown.

3. `[ELEVATED]` Remove Finance target groups from the broken `SYSTEM`-context deployment and click `Save`.
   Expected result: Finance groups are no longer assigned to the broken mapping path.

4. `[ELEVATED]` Open `gpmc.msc` on a domain-admin workstation and navigate to the approved Finance drive mapping GPO.
   Expected result: The approved Finance GPO is selected in Group Policy Management Console.

5. `[ELEVATED]` In the GPO, open `User Configuration > Policies > Windows Settings > Scripts (Logon/Logoff) > Logon > Properties` and confirm the Finance mapping script is present and enabled.
   Expected result: User-context mapping script for drive `S:` is active in the GPO.

6. Instruct affected Finance users to log off and log back on once.
   Expected result: User-context logon script runs in each user's interactive session, creating drive `S:`.

7. Validate with one test user by running `net use` in Command Prompt after sign-in.
   Expected result: Output includes `S:` mapped to `\\finbridge-fs01\Finance`.

8. Ask the test user to open `S:` in File Explorer.
   Expected result: Finance share opens and folder contents are accessible.

---

## Verification

Complete all checks before closing the incident or knowledge article:

| Check | Pass Criteria |
|---|---|
| Intune script assignment | Finance groups removed from broken `SYSTEM`-context deployment in Intune portal |
| GPO user-context mapping | Approved mapping script present and enabled under `User Configuration > Policies > Windows Settings > Scripts (Logon/Logoff) > Logon` |
| Drive presence | Test user `net use` output includes `S:` mapped to `\\finbridge-fs01\Finance` |
| Drive access | Test user can open `S:` in File Explorer and browse contents |
| No new failures | IME log shows no further `exit code 1` entries for `Map-FinBridgeDrives.ps1` |
| User noise | No new Finance user reports of missing `S:` after session restart |

---

## Rollback

Use immediately if the resolution causes further issues or `S:` does not return after session restart.

1. `[ELEVATED]` In Intune portal (`https://intune.microsoft.com`), go to `Devices > Scripts and remediations > Platform scripts > Map-FinBridgeDrives.ps1 > Assignments`. Remove all Finance assignments and click `Save`.
   Expected result: Intune mapping script is fully unassigned for Finance.

2. `[ELEVATED]` In `gpmc.msc`, open the pre-migration Finance GPO and confirm `User Configuration > Policies > Windows Settings > Scripts (Logon/Logoff) > Logon` contains the original mapping script. If missing, re-add using the last known-good script from the change record.
   Expected result: Original user-context GPO mapping is active.

3. Instruct Finance users to log off and log back on.
   Expected result: GPO logon script runs in user context and maps `S:`.

4. Validate: run `net use` in the test user's Command Prompt and confirm `S:` maps to `\\finbridge-fs01\Finance`.
   Expected result: Drive `S:` present and accessible.

5. Escalate to Desktop Engineering lead with Intune log, Event Viewer evidence, and change record if rollback also fails.

---

## Preventive Actions

Controls are ordered by deployment phase. Each control states owner, timing, pass criteria, fail criteria, observable signal, log evidence, threshold, and automation status.

---

### PC-01 — Execution-context review gate for user-scoped script migrations
**Owner:** DWP Engineer | **Timing:** Before deployment | **Type:** Manual
**Automation Opportunity:** Could be enforced as a mandatory change form field in ITSM.
- Pass: Change record explicitly states execution context (`USER` or `SYSTEM`) and confirms it is valid for the resource type.
- Fail: Change record is silent on execution context, or states `SYSTEM` for a user-scoped mapped drive without a tested alternative design.
- Observable signal: Change record field populated and approved by DWP Engineer prior to CAB submission.
- Log evidence: Change record audit trail.
- Threshold: Zero tolerance — no migration change record approved without this field complete.

---

### PC-02 — Intune script deployment requires `Run as logged-on credentials = Yes` for user-scoped resources
**Owner:** Intune Administrator | **Timing:** Before deployment | **Type:** Manual
**Automation Opportunity:** Intune compliance policy or custom script assignment template could enforce this default.
- Pass: Intune script Properties show `Run this script using the logged on credentials = Yes` for any script targeting user-scoped resources.
- Fail: Setting is `No` (SYSTEM context) without a written, approved exception signed off by DWP Engineer.
- Observable signal: Intune portal — `Devices > Scripts and remediations > Platform scripts > <script> > Properties`.
- Log evidence: Intune audit log entry for script creation/modification.
- Threshold: Any `SYSTEM`-context deployment targeting user-scoped resources without an approved exception is a blocking failure.

---

### PC-03 — Change approval gate — GPO-to-Intune migration
**Owner:** Change Manager | **Timing:** Before deployment | **Type:** Manual
**[REQUIRES: CAB checklist item for execution-context sign-off]**
- Pass: Change Manager confirms DWP Engineer sign-off on execution context and pilot results before approving full deployment.
- Fail: Change approved without execution-context sign-off or without pilot evidence.
- Observable signal: Change record approval status with required sign-off checklist complete.
- Log evidence: ITSM change record approval audit trail.
- Threshold: Zero tolerance — full deployment not approved without both items.

---

### PC-04 — Pilot rollout validation before broad deployment
**Owner:** Release Engineer | **Timing:** Before deployment (broad rollout) | **Type:** Manual
**Automation Opportunity:** Intune deployment rings could enforce pilot-first sequencing automatically.
- Pass: Pilot group (minimum 3 Finance `DESKTOP-FB*` endpoints) shows drive `S:` mapped successfully after logon; no Ntfs Event ID 98 in System log; IME log shows exit code `0`.
- Fail: Any pilot device shows missing `S:`, IME exit code `1`, or Ntfs Event ID 98.
- Observable signal: `net use` output on pilot endpoints; IME log exit code; System Event ID 98 absence.
- Log evidence: `IntuneManagementExtension.log` — exit code `0` for `Map-FinBridgeDrives.ps1` on each pilot device.
- Threshold: 100% of pilot devices must pass before broad rollout proceeds.

---

### PC-05 — Success and failure logging standard for all Intune-delivered scripts
**Owner:** DWP Engineer | **Timing:** Before deployment | **Type:** Manual
**Automation Opportunity:** Shared PowerShell logging module could be enforced as a script template requirement.
- Pass: Script writes execution context, target path, retry count, and result code to `IntuneManagementExtension.log` at each run.
- Fail: Script produces no structured log entry, or omits context, path, or result code.
- Observable signal: `Select-String` against IME log returns structured entries for every script execution.
- Log evidence: `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\IntuneManagementExtension.log`.
- Threshold: Any script without compliant logging is blocked from production deployment.

---

### PC-06 — In-flight monitoring during deployment window
**Owner:** DWP Engineer | **Timing:** During deployment | **Type:** Manual
**[REQUIRES: Centralised event monitoring or SIEM alert rule for Ntfs Event ID 98]**
- Pass: No Ntfs Event ID 98 entries appear on Finance endpoints during the deployment window.
- Fail: One or more Finance endpoints log Ntfs Event ID 98 during or within 30 minutes of deployment completion.
- Observable signal: Event Viewer `Windows Logs > System` filtered on Event ID 98 across Finance endpoint scope.
- Log evidence: System log — Ntfs Event ID 98 with timestamp within deployment window.
- Threshold: Any single occurrence on a Finance endpoint triggers immediate hold and rollback evaluation.

---

### PC-07 — Post-deployment validation
**Owner:** Release Engineer | **Timing:** After deployment | **Type:** Manual
**Automation Opportunity:** Intune remediation script could run `net use` and report drive state as a compliance value.
- Pass: All Finance users can open `S:` in File Explorer after logon; no new Service Desk calls for missing `S:`; IME log shows no `exit code 1` for `Map-FinBridgeDrives.ps1`.
- Fail: Any Finance user reports missing `S:` within the 24-hour post-deployment monitoring window.
- Observable signal: Service Desk call volume for Finance drive issues; `net use` output on sampled endpoints.
- Log evidence: IME log exit codes; System log Ntfs Event ID 98 count = 0.
- Threshold: Zero user reports within 24 hours post-deployment; zero IME exit code `1` entries.

---

### PC-08 — Rollback trigger definition
**Owner:** Change Manager | **Timing:** Before deployment (defined), During/After deployment (actioned) | **Type:** Manual
**[REQUIRES: Rollback trigger criteria embedded in change record at approval time]**
- Pass: Change record contains explicit rollback trigger criteria and rollback instructions before deployment begins.
- Fail: Rollback criteria absent from change record; engineer must decide ad hoc during outage.
- Observable signal: Change record rollback section populated and signed off at CAB approval.
- Log evidence: ITSM change record audit trail showing rollback section completion before deployment start.
- Threshold: Rollback must be triggered within 15 minutes of any single Finance user reporting missing `S:` post-deployment.

---

### PC-09 — Knowledge update process after resolution
**Owner:** Service Desk Lead | **Timing:** After deployment | **Type:** Manual
**[REQUIRES: Defined KB review cycle tied to incident closure workflow]**
- Pass: L1, L2/L3 KB articles and runbook are reviewed and updated within 5 business days of incident closure; version numbers incremented; Status changed from `Draft` to `Approved`.
- Fail: KB articles remain in `Draft` status or reflect superseded procedures 5 business days after closure.
- Observable signal: KB article Status field; version number; last-modified date.
- Log evidence: Document version history or ITSM KB audit trail.
- Threshold: Any KB article older than 5 business days post-closure without a status update is flagged to Service Desk Lead.

---

## Related Knowledge Articles

| Document | Relevance |
|---|---|
| `KE-FinanceDriveMapping-Intune-ExecutionContext.md` | Primary knowledge entry for this execution context issue |
| `INC-FinanceDriveMapping-RCA-2026-08-07.md` | Verified RCA this article was built from |
| `RB-FinanceDriveMapping-Recovery-Runbook-2026-08-07.md` | Operational runbook for step-by-step recovery |
| `KB-L1-Finance-Drive-Access-Self-Service-2026-08-07.md` | L1 end-user self-service article for this incident type |
| `INC-GPO-Processing-Floor3-RCA-2024-03-15.md` | Separate GPO failure incident — different failure domain, useful for comparison |
