# Root Cause Analysis (RCA)

## Incident
Finance Shared Drive Mapping Failure After Migration

## Document Control
- Incident date: 2024-03-15
- RCA authored: 2026-08-07
- Scope: Finance users on DESKTOP-FB* devices
- Affected population: Approximately 45 Finance users
- Affected service: Finance mapped drive `S:`
- Status: Resolved

## Executive Summary
Following an overnight migration of the Finance drive mapping method, Finance users were unable to access their mapped shared drive. Investigation confirmed that the mapping mechanism had been changed from a GPO logon script running in the signed-in user context to an Intune PowerShell script running in the local `SYSTEM` context. The script was not updated to handle `SYSTEM`-context execution and therefore failed when attempting to access `\\finbridge-fs01\Finance` at logon time. Group Policy processing remained successful throughout, which ruled out GP as the failing layer and narrowed the issue to the migrated drive-mapping path.

Service was restored by reverting the drive mapping script to a user-context execution method. Affected users logged off and back on, the Finance mapped drive `S:` appeared successfully, and no further user reports were received.

## Technical Summary
The failure was caused by an execution-context mismatch introduced during migration. Before the change, drive mapping ran as a user logon script and used the signed-in user's session and access token. After the change, the same mapping logic was delivered through Intune and ran as `SYSTEM`. In that context, the script could not access the Finance UNC path at execution time, failed with `Network name cannot be found`, and had no retry configured. Because the script failed before assigning the drive letter, users experienced a missing mapped drive while other platform services, including Group Policy, continued to function normally.

## Business Impact
- Service impacted: Access to the Finance shared drive via mapped drive `S:`.
- User impact: Approximately 45 Finance users could not access their mapped shared drive.
- Functional impact: Finance users lost expected access to department file shares through the mapped-drive workflow.
- Scope pattern: All Finance users were affected simultaneously, indicating a shared central failure rather than isolated endpoint issues.
- Duration: Began at 08:00 after the overnight migration and continued until the user-context mapping method was restored and users signed in again.

## Timeline
- 2024-03-14 23:30 - Change log records migration of drive mapping from GPO logon script running as `USER` to Intune PowerShell script running as `SYSTEM`.
- 08:00:01 - Intune Management Extension: `Map-FinBridgeDrives.ps1` execution started.
- 08:00:02 - Intune Management Extension: script context recorded as `SYSTEM`.
- 08:00:03 - Intune Management Extension: `\\finbridge-fs01\Finance` not accessible from `SYSTEM` context at execution time.
- 08:00:03 - Intune Management Extension: script failed with exit code `1`; error `Network name cannot be found`.
- 08:00:04 - Intune Management Extension: no retry configured.
- 08:00:05 - DESKTOP-FB041 System log: Workstation service entered running state.
- 08:00:06 - DESKTOP-FB041 System log: GroupPolicy Event 1500, policy processed successfully.
- 08:00:07 - DESKTOP-FB041 System log: Ntfs Event 98, drive letter `S:` could not be mapped because it had not been assigned.
- Post-remediation - Mapping method reverted to user-context execution.
- Post-remediation - Affected users logged off and back on.
- Post-remediation - Drive `S:` appeared successfully and no further user reports were received.

## Evidence Reviewed
- Intune Management Extension log entries showing:
  - `Map-FinBridgeDrives.ps1` executed.
  - Script execution occurred under `SYSTEM` context.
  - Access to `\\finbridge-fs01\Finance` failed from `SYSTEM` context.
  - Script ended with exit code `1` and `Network name cannot be found`.
  - No retry was configured.
- DESKTOP-FB041 System log entries showing:
  - Workstation service entered running state after the script failure sequence began.
  - GroupPolicy Event 1500 confirmed successful Group Policy processing.
  - Ntfs Event 98 confirmed drive `S:` was not assigned.
- Migration change note showing:
  - The mapping method was changed from GPO logon script in `USER` context to Intune PowerShell script in `SYSTEM` context.
  - The script was not updated to handle `SYSTEM`-context execution.
- Post-remediation service verification showing:
  - Drive mapping reverted to user-context execution.
  - Affected users logged off and back on.
  - Drive `S:` appeared successfully.
  - No further user reports were received.

## Root Cause Analysis
### Verified root cause
The verified root cause was migration of the Finance drive mapping process from a user-context GPO logon script to an Intune PowerShell script running in the `SYSTEM` account, without redesigning the script for `SYSTEM`-context execution.

### Why the migrated implementation failed
The script attempted to map `\\finbridge-fs01\Finance` in the local machine `SYSTEM` context rather than the signed-in user context. The available evidence shows that the Finance UNC path was not accessible from `SYSTEM` at execution time, the script failed immediately, and no retry occurred. Because drive assignment depended on that script completing successfully, the `S:` drive was never created.

### Why `SYSTEM` context differs from `USER` context
A user logon script runs inside the interactive user session and can use the signed-in user's token and session-scoped access for user resources such as mapped drives. A `SYSTEM`-context Intune script runs as the local machine account, outside the user's interactive identity context. That means the script does not behave like a user logon mapping process and may not have the same effective access path or session behavior required to create the user's mapped drive at logon.

### Eliminated alternatives
- Group Policy failure was eliminated because GroupPolicy Event 1500 confirmed successful policy processing.
- Targeting failure was eliminated because the Intune script executed on an affected device.
- Isolated workstation failure was eliminated because all Finance users were affected simultaneously immediately after the same migration change.
- Missing drive persistence as a primary cause was eliminated because the absent `S:` drive followed directly from the earlier script execution failure.

### Why the verified root cause fits all observed facts
- It fits successful Group Policy processing because the failure occurred in Intune-delivered drive mapping, not GP.
- It fits the migration timing because the issue began immediately after the execution method changed.
- It fits simultaneous impact because a single centrally deployed script behavior affected all targeted Finance users.
- It fits the mapped-drive-only symptom because the failing component was the drive-mapping script itself.
- It fits the recorded logs because the script failed specifically in `SYSTEM` context before `S:` could be assigned.

## Resolution Details
### Temporary restoration
- The broken Intune `SYSTEM`-context drive mapping path was removed or bypassed.
- The previous user-context drive mapping method was restored.
- Users were instructed to log off and back on so the corrected user-context mapping process could run in their session.

### Permanent corrective direction
- Maintain Finance drive mapping in a user-context execution model for user-scoped mapped drives.
- Do not reuse user logon mapping logic in `SYSTEM` context without redesigning it for that execution model.
- Require explicit execution-context validation in future GPO-to-Intune migrations.
- Include retry or delayed execution design where login-time network readiness can affect mapping reliability.

## Validation Results
- Group Policy validation: GroupPolicy Event 1500 confirmed GP remained healthy during the incident, supporting root cause isolation away from policy processing.
- Execution-path validation: Intune logs confirmed the active migrated script path and the `SYSTEM` execution context failure.
- Symptom validation: Ntfs Event 98 confirmed the drive letter was not assigned during the failure state.
- Service restoration validation: After reverting to user-context execution and having affected users log off and back on, mapped drive `S:` appeared successfully.
- Stability validation: No further user reports were received after restoration.

## Five Why Analysis
1. Why could Finance users not access the shared drive?
Because mapped drive `S:` was not being created successfully at logon.

2. Why was mapped drive `S:` not being created?
Because the Finance drive mapping script failed before assigning the drive.

3. Why did the script fail?
Because it attempted to access `\\finbridge-fs01\Finance` while running as `SYSTEM`, and that context could not access the path at execution time.

4. Why was the script running as `SYSTEM`?
Because the mapping process had been migrated from a GPO user logon script to an Intune PowerShell deployment configured to run in `SYSTEM` context.

5. Why did the migration introduce a failure?
Because the migration changed the execution context without updating the script design or validating that user-mapped drive logic still worked correctly under the new execution model.

## Preventive Actions
- Add an execution-context review gate to all script migrations involving user-scoped resources.
- Require pilot validation for GPO-to-Intune migrations before broad deployment.
- Add success and failure logging standards for Intune-delivered scripts, including context, target path, retry state, and result code.
- Require rollback criteria and rollback instructions in migration change records.
- Introduce post-change monitoring for mapped-drive failures after endpoint management migrations.
- Document that user drive mappings must be implemented in user context unless a fully tested alternative design exists.

## Lessons Learned
- Successful Group Policy processing does not prove the mapped-drive mechanism is healthy when the mapping path has been moved out of GP.
- Execution context is a first-order design dependency for drive-mapping migrations.
- Department-wide simultaneous failure immediately after a migration strongly indicates a shared central mechanism failure rather than isolated endpoint issues.
- Change records must capture not only what moved, but also whether the new execution context changes the resource access model.
- Fast restoration came from reverting to the last known-good user-context method rather than continuing to troubleshoot the broken `SYSTEM`-context design during the outage.
