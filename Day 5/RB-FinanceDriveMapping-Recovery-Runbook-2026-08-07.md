Title: Finance Shared Drive Access Failure Runbook
Version: 1.0
Date: 07/08/2026
Author: Nikita
Reviewed By: Self
Status: Draft
Change Summary: Initial version created from verified RCA

# Runbook
## Finance Shared Drive Mapping Failure After Migration

## Purpose
Restore Finance mapped drive `S:` when mapping has failed due to migration from user-context GPO logon mapping to Intune `SYSTEM`-context script execution.

## Scope
- Department: Finance
- Affected devices: `DESKTOP-FB*`
- Affected mapped drive: `S:`
- Share path: `\\finbridge-fs01\Finance`

## Trigger Conditions
Use this runbook when all of the following are true:
- Finance users report missing drive `S:`.
- Incident timing aligns with drive-mapping migration/change activity.
- Intune-managed mapping script is in scope.

## Prerequisites
### What the engineer needs before starting
- Active incident ticket with incident commander or service owner assigned.
- Change record reference for the drive-mapping migration.
- At least one affected test user account in Finance.
- At least one affected endpoint name (example: `DESKTOP-FB041`).

### Required permissions
- `[ELEVATED]` Microsoft Intune admin rights sufficient to view and modify script assignments and execution settings.
- `[ELEVATED]` Access to Microsoft Intune Management Extension logs on affected endpoint(s).
- `[ELEVATED]` Permission to modify the active drive-mapping deployment method (Intune assignment and/or GPO logon mapping state).
- Read access to Windows Event Viewer on affected endpoint(s).

### Required portals/tools
- Microsoft Intune admin center: `https://intune.microsoft.com`
- Portal location for script scope check: `Devices > Scripts and remediations > Platform scripts`
- Windows Event Viewer (on affected endpoint): `Event Viewer > Windows Logs > System`
- Log source for Intune script execution: Intune Management Extension log (`IntuneManagementExtension.log`) on affected endpoint

### Required systems
- Finance file server path reachable in normal user context: `\\finbridge-fs01\Finance`
- One or more impacted Finance endpoints online
- Domain and endpoint management services operational

## Procedure
1. Open the incident ticket in your ITSM console and click `Edit`, then set `Status` to `In Progress`.
Expected result: Ticket status shows `In Progress` and your name appears as the active engineer.

2. Open a browser and go to `https://intune.microsoft.com`.
Expected result: The Microsoft Intune admin center home page loads without access errors.

3. In the left navigation, click `Devices`.
Expected result: The Devices blade opens and the device management menu is visible.

4. Under `Devices`, click `Scripts and remediations`.
Expected result: The Scripts and remediations page opens with script categories.

5. Click `Platform scripts`.
Expected result: A table of PowerShell platform scripts is displayed.

6. In the search box above the table, type `Map-FinBridgeDrives.ps1` and press `Enter`.
Expected result: The script list filters and shows `Map-FinBridgeDrives.ps1`.

7. Click the row for `Map-FinBridgeDrives.ps1`.
Expected result: The script details page opens.

8. Click `Properties` on the script details page.
Expected result: Script configuration fields are shown, including the run context setting.

9. Record the value shown for run context (for example `Run this script using the logged on credentials = No`, which indicates `SYSTEM`) in the incident notes.
Expected result: Incident notes contain the exact context setting text copied from Intune.

10. On an affected endpoint (example `DESKTOP-FB041`), open `File Explorer` and browse to `C:\ProgramData\Microsoft\IntuneManagementExtension\Logs`.
Expected result: The folder opens and `IntuneManagementExtension.log` is visible.

11. Right-click `IntuneManagementExtension.log`, click `Open with`, and select `Notepad`.
Expected result: The log file opens and text is readable.

12. Press `Ctrl+F`, enter `Map-FinBridgeDrives.ps1`, and click `Find Next` until you reach the most recent timestamp block.
Expected result: The latest script execution block for `Map-FinBridgeDrives.ps1` is highlighted.

13. Copy the exact exit code and error line (for example `exit code 1` and `Network name cannot be found`) into the incident notes.
Expected result: Incident notes include verbatim log evidence with timestamp, exit code, and error text.

14. On the same endpoint, press `Win+R`, type `eventvwr.msc`, and press `Enter`.
Expected result: Event Viewer opens.

15. In Event Viewer, click `Windows Logs`, then click `System`.
Expected result: System event list is visible.

16. In the right `Actions` pane, click `Filter Current Log...`, enter `1500` in `Event IDs`, and click `OK`.
Expected result: Filtered results show `GroupPolicy` Event ID `1500` entries for the incident window.

17. Open the relevant `GroupPolicy` Event ID `1500` entry and copy the event time and success message into the incident notes.
Expected result: Incident notes show proof that Group Policy processed successfully during the failure period.

18. In the right `Actions` pane, click `Filter Current Log...`, clear `Event IDs`, enter `98`, and click `OK`.
Expected result: Filtered results show `Ntfs` Event ID `98` entries (if present) for the incident window.

19. Open the relevant `Ntfs` Event ID `98` entry and copy the event time and message about drive `S:` not being assigned into the incident notes.
Expected result: Incident notes show direct evidence that drive-letter assignment failed.

20. `[ELEVATED]` In Intune script details for `Map-FinBridgeDrives.ps1`, click `Assignments`, remove Finance target groups from the broken deployment, and click `Save`.
Expected result: Assignment summary no longer includes the affected Finance groups for the broken path.

21. `[ELEVATED]` On a domain-admin workstation, press `Win+R`, type `gpmc.msc`, and press `Enter`.
Expected result: Group Policy Management Console opens.

22. `[ELEVATED]` In Group Policy Management, click the GPO named in the change record as the approved Finance user-context logon mapping policy.
Expected result: The correct GPO is selected and its details pane is visible.

23. `[ELEVATED]` In that GPO, click `User Configuration > Policies > Windows Settings > Scripts (Logon/Logoff) > Logon`, then click `Properties`.
Expected result: The Logon Properties window opens and the script list is visible.

24. `[ELEVATED]` In Logon Properties, add or enable the approved Finance mapping script entry for drive `S:`, then click `OK`.
Expected result: The user-context mapping script entry is present and enabled in the selected GPO.

25. In your ITSM ticket, open the user communication panel/template and send the instruction for affected Finance users to log off and log back on once.
Expected result: Communication is sent and ticket activity shows the outbound timestamp.

26. On one affected test user session after sign-in, open `Start > Windows Tools > Command Prompt`, run `net use`, and press `Enter`.
Expected result: Output includes drive `S:` mapped to `\\finbridge-fs01\Finance`.

27. In the same test user session, open `File Explorer > This PC`, then double-click drive `S:`.
Expected result: The Finance share opens and folder contents are accessible without error.

28. Open the incident ticket, click `Work Notes` (or equivalent), and paste Intune evidence, IME evidence, Event Viewer evidence, assignment change times, and user validation result.
Expected result: Ticket contains a complete, timestamped remediation record ready for formal verification and closure review.

## Verification
Complete all checks before closure:
- Intune check: The `SYSTEM`-context mapping deployment is disabled/unassigned for the affected scope.
- Mapping check: Affected test user can see `S:` after logoff/logon.
- Access check: Affected test user can browse `\\finbridge-fs01\Finance` through `S:`.
- Event/log check: No new script failure entries for `Map-FinBridgeDrives.ps1` in the active path.
- Noise check: No new user reports of missing `S:` for Finance during agreed monitoring window.

Closure gate:
- Do not close until all checks above are true and documented in the incident record.

## Rollback
Use this sequence immediately if post-fix behavior degrades. Target completion time: under 3 minutes.

1. `[ELEVATED]` Open the incident ticket, click `Edit`, set `Status` to `In Progress`, and add work note `ROLLBACK START <timestamp>`.
Expected result: Ticket shows rollback start timestamp and active rollback state.

2. `[ELEVATED]` In Microsoft Intune admin center (`https://intune.microsoft.com`), go to `Devices > Scripts and remediations > Platform scripts > Map-FinBridgeDrives.ps1 > Assignments`.
Expected result: Assignment page for the script is open.

3. `[ELEVATED]` In `Assignments`, remove the Finance target groups from `Map-FinBridgeDrives.ps1` and click `Save`.
Expected result: Finance groups no longer appear in assigned groups for the Intune mapping script.

4. `[ELEVATED]` On a domain-admin workstation, open `gpmc.msc` and go to `Forest > Domains > <your-domain> > Group Policy Objects > <approved Finance drive mapping GPO>`.
Expected result: The approved Finance mapping GPO is selected.

5. `[ELEVATED]` In the selected GPO, open `User Configuration > Policies > Windows Settings > Scripts (Logon/Logoff) > Logon > Properties`.
Expected result: Logon script list opens for the approved Finance mapping GPO.

6. `[ELEVATED]` In `Logon Properties`, confirm the approved Finance mapping script entry for drive `S:` is present and enabled, then click `OK`.
Expected result: GPO logon-script configuration shows the Finance mapping script active.

7. Send user message: `Please log off and log back on now to restore Finance drive mapping.`
Expected result: User acknowledges and starts session restart.

8. After user sign-in, open `Command Prompt` in the user session and run `net use`.
Expected result: Output contains `S:` mapped to `\\finbridge-fs01\Finance`.

9. In the same user session, open `File Explorer > This PC` and open `S:`.
Expected result: Finance share opens and folders are accessible with no error.

10. Update the incident ticket with rollback evidence: Intune unassignment screenshot/time, GPO path used, `net use` output result, and `S:` open test result.
Expected result: Rollback is fully validated and documented for handoff or closure decision.

Rollback validation gate:
- Rollback is successful only when all three are true: Intune Finance assignment removed, GPO user logon script active, and test user can open `S:`.

## Notes
### Edge cases
- Endpoint has not checked in to Intune recently: remediation may appear incomplete until next device sync/sign-in cycle.
- User can access UNC directly but `S:` is missing: treat as mapping mechanism issue, not share outage.
- Mixed state during transition: some users may recover earlier based on session restart timing.

### Warnings
- Do not run user-drive mapping logic in `SYSTEM` context unless redesigned and validated for that model.
- Do not assume Group Policy failure when GroupPolicy Event `1500` is successful.
- Do not close incident based on portal status alone; require end-user validation of `S:`.

### Similar incidents
- `INC-GPO-Processing-Floor3-RCA-2024-03-15.md` (separate failure domain; use for comparison only).
- `KE-FinanceDriveMapping-Intune-ExecutionContext.md` (knowledge base reference for context behavior).

### Operational considerations
- Require execution-context validation in all GPO-to-Intune script migrations.
- Require pilot ring before broad deployment for user-scoped resource mappings.
- Require explicit rollback steps in every migration change record.
- Capture script context, target path, and result code in standard incident evidence template.
