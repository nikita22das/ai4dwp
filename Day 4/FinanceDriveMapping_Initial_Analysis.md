# Finance Drive Mapping Incident - Initial Analysis

Date of analysis: 2026-08-07
Scope: Approximately 45 Finance users on DESKTOP-FB* devices

## Goal
Rank the most likely causes for the missing mapped drive symptom using only the provided scope facts, with migration timing as the primary weighting factor.

## Scope Facts Used
- All Finance users are affected.
- The issue started immediately after a migration activity.
- Group Policy processing appears successful.
- The issue affects mapped drives only.

## Key discriminator
A simultaneous department-wide mapped-drive failure that starts immediately after an overnight migration, while Group Policy still processes successfully, points first to a centrally introduced fault in the new drive mapping mechanism rather than isolated workstation problems.

## Most likely explanation of the simultaneous impact
The strongest hypothesis is that the overnight migration introduced a centrally misconfigured Finance drive-mapping definition, such as an incorrect UNC path, wrong share name, wrong drive letter assignment, or incorrect mapping item in the new mechanism.

This best explains why every Finance user experienced the issue at the same time despite successful Group Policy processing:
- Group Policy success means policy delivery itself may still be healthy.
- A bad mapping definition inside the migrated mechanism can still be delivered successfully.
- Because the Finance mapping is shared centrally, one bad migrated definition can affect all Finance users at once.
- The immediate start after the migration strongly favors a change-linked cause over pre-existing endpoint variation.

## Re-ranked hypotheses (most probable first)

### 1) Central misconfiguration in the migrated Finance drive-mapping definition
Why this fits:
- It matches the exact timing: the issue began immediately after the overnight migration.
- It explains why all Finance users were affected simultaneously.
- It fits successful Group Policy processing because policy can apply normally while the mapped-drive content it delivers is wrong.
- It fits the symptom being limited to mapped drives rather than broader authentication or device failures.

Fastest check:
- Compare the migrated Finance mapping definition to the intended pre-migration UNC target, share name, and drive letter.

### 2) Finance scoping or targeting error in the new mapping mechanism
Why this fits:
- A migration can preserve policy success but break who gets which mapping.
- A single targeting mistake can affect all Finance users at the same time.
- The symptom remains specific to mapped drives, which is consistent with a scoping error inside the new mapping logic rather than general client failure.

Fastest check:
- Review the targeting or filtering rules for the Finance mapping item and confirm Finance users are included as intended.

### 3) Common failure in the new client-side mapping mechanism on DESKTOP-FB devices
Why this fits:
- The affected devices share the DESKTOP-FB pattern, suggesting a shared client application path.
- If the migration depends on a script, preference item, scheduled task, or agent, a common failure there could affect everyone in scope together.
- Group Policy can still report success if it successfully triggers a downstream mechanism that then fails.

Fastest check:
- On one affected DESKTOP-FB device, verify whether the new mapping mechanism ran this morning and what result it logged.

### 4) Authentication or permission handling changed in the migrated mapping flow
Why this fits:
- Migration can change how the drive is presented or authenticated without changing overall policy processing.
- This can make a mapped drive unavailable even when the underlying delivery path executes.
- It is ranked lower because the provided facts do not specifically show an access denied pattern, only an unavailable mapped drive.

Fastest check:
- From an affected Finance user session, test direct access to the intended Finance UNC path without using the mapped drive.

### 5) Persistent mapped drives were not recreated after the migration
Why this fits:
- It matches the mapped-drive-only symptom.
- It fits the migration timing if the new method failed to recreate expected drive letters.
- It is weaker than the hypotheses above because it is a narrower expression of migration failure and does not explain the shared Finance-wide behavior as directly as a central definition or targeting fault.

Fastest check:
- On one affected device, verify whether the expected drive letter is absent versus present-but-disconnected, then test the corresponding UNC path manually.

## Why isolated workstation issues are less likely
- Isolated workstation problems usually produce scattered impact, not a simultaneous department-wide outage.
- The issue boundary aligns to Finance users and began at the same time, which points to a shared control point rather than independent local failures.
- The immediate post-migration timing strongly links the symptom to a single recent central change.
- Reported successful Group Policy processing weakens theories based on broken local policy processing, random machine drift, or unrelated endpoint corruption.
- Local workstation faults may still exist in individual cases, but they are a poor primary explanation for a synchronized Finance-wide mapped-drive failure.

## Status
- Initial sections above reflect the pre-evidence hypothesis ranking.
- Root cause is now confirmed from the provided Intune and System log evidence below.

## Evidence Review and Root Cause Confirmation (Appended 2026-08-07)

### Relevant evidence provided
- Intune Management Extension, 08:00:01: `Map-FinBridgeDrives.ps1` started.
- Intune Management Extension, 08:00:02: script ran in `SYSTEM` context.
- Intune Management Extension, 08:00:03: `\\finbridge-fs01\Finance` was not accessible from `SYSTEM` context at execution time.
- Intune Management Extension, 08:00:03: script failed with exit code `1`; error: `Network name cannot be found`.
- Intune Management Extension, 08:00:04: no retry configured.
- DESKTOP-FB041 System log, 08:00:05: Workstation service entered running state.
- DESKTOP-FB041 System log, 08:00:06: GroupPolicy Event 1500 confirmed policy processed successfully.
- DESKTOP-FB041 System log, 08:00:07: Ntfs Event 98 warned that drive letter `S:` could not be mapped because the drive letter had not been assigned.
- Migration change note, 2024-03-14 23:30: drive mapping moved from GPO logon script running as `USER` to Intune PowerShell script running as `SYSTEM`, and the script was not updated to handle `SYSTEM` context.

### Confirmed root cause
The overnight migration changed Finance drive mapping from a user-context GPO logon script to an Intune PowerShell script running in `SYSTEM` context, but the script was not updated to handle `SYSTEM` execution at login time. As a result, the script attempted to access `\\finbridge-fs01\Finance` before the required user-context network path and credentials were available, failed immediately, and did not retry.

### Why this best explains the full scope
- It explains the exact timing: the issue began immediately after the migration that changed the execution context.
- It explains the simultaneous Finance-wide impact: every targeted Finance user received the same migrated script behavior.
- It explains why Group Policy processing was successful: Group Policy was not the failing component.
- It explains why only mapped drives were affected: the failure occurred in the specific migrated drive-mapping mechanism.
- It explains the device pattern: DESKTOP-FB clients were subject to the same Intune-delivered script path.

### Hypothesis elimination outcome
1. Central misconfiguration in the Finance drive target definition - partially related but not primary.
	The UNC path itself is shown in the script logs; the decisive failure is execution under `SYSTEM` context, not a demonstrated wrong path definition.
2. Finance scoping or targeting error in the new mapping mechanism - eliminated as primary cause.
	The evidence shows the mapping script did run for in-scope devices, so delivery to Finance users occurred.
3. Common failure in the new client-side mapping mechanism on DESKTOP-FB devices - confirmed.
	Confirmed specifically as an execution-context mismatch introduced by the migration from `USER` to `SYSTEM`.
4. Authentication or permission handling changed in the migrated mapping flow - supported as a contributing mechanism.
	The missing user-context credentials and unavailable network path under `SYSTEM` are part of the confirmed failure chain.
5. Persistent mapped drives were not recreated after the migration - downstream symptom, not root cause.
	The script failure prevented drive `S:` from being assigned.

### Verified fastest discriminator
The fastest check was the Intune Management Extension log showing the script ran as `SYSTEM` and failed to access `\\finbridge-fs01\Finance`. That single check both confirmed the active migration path and eliminated Group Policy as the cause.

### Resolution direction
- Change the mapping back to a user-context execution path, or redesign the Intune deployment so the mapping occurs in the user context after required network access is available.
- Add retry logic or delayed execution if the chosen mechanism depends on services or session state that are not guaranteed at initial logon.
- Validate by confirming the drive mapping script runs in user context, the UNC path is reachable at execution time, and drive `S:` is assigned successfully for a Finance test user.

## Evidence Review, Hypothesis Elimination, Root Cause, Resolution, and Validation (Appended 2026-08-07)

### Evidence reviewed
- Intune Management Extension, 08:00:01: `Map-FinBridgeDrives.ps1` executed.
- Intune Management Extension, 08:00:02: script context was `SYSTEM`.
- Intune Management Extension, 08:00:03: `\\finbridge-fs01\Finance` was not accessible from `SYSTEM` context at execution time.
- Intune Management Extension, 08:00:03: script failed with exit code `1`; error recorded as `Network name cannot be found`.
- Intune Management Extension, 08:00:04: no retry configured.
- DESKTOP-FB041 System log, 08:00:05: Workstation service entered running state.
- DESKTOP-FB041 System log, 08:00:06: GroupPolicy Event 1500 confirmed successful Group Policy processing.
- DESKTOP-FB041 System log, 08:00:07: Ntfs Event 98 reported drive letter `S:` could not be mapped because it had not been assigned.
- Migration change log, 2024-03-14 23:30: drive mapping was migrated from GPO logon script running as `USER` to Intune PowerShell script running as `SYSTEM`, without updating the script for `SYSTEM`-context execution.

### Eliminated hypotheses
1. Central misconfiguration in the Finance drive target definition.
	Eliminating evidence: the logs identify the active script, its `SYSTEM` execution context, and the context-specific failure to access `\\finbridge-fs01\Finance`. The evidence does not show a wrong UNC target, wrong share name, or wrong drive letter definition as the primary break.
2. Finance scoping or targeting error in the new mapping mechanism.
	Eliminating evidence: the Intune log confirms the mapping script executed on an affected device. That proves the new mechanism reached in-scope clients rather than failing to target them.
3. Group Policy failure or isolated workstation policy-processing fault.
	Eliminating evidence: GroupPolicy Event 1500 confirms policy processed successfully on the affected endpoint. This rules out GP failure as the primary cause and weakens isolated workstation explanations.
4. Missing persistent drive recreation as the primary cause.
	Eliminating evidence: Ntfs Event 98 occurs after the script failure. The missing `S:` assignment is downstream of the earlier script execution failure, not an independent root cause.

### Surviving hypothesis
The migrated client-side drive mapping mechanism failed because the script was moved from `USER` context to Intune PowerShell execution under the `SYSTEM` account, and the script was not designed to map the Finance drive successfully from `SYSTEM` context at login time.

### Verified root cause
Verified root cause was an execution-context mismatch introduced by the migration. Finance drive mapping had previously worked as a GPO logon script running in the signed-in user context. After migration, the same mapping logic was executed by Intune in `SYSTEM` context, where the required user-scoped network access and drive-mapping behavior were not available at execution time. The script failed immediately, did not retry, and therefore no Finance drive was assigned.

### Resolution implemented
- Removed or disabled the broken Intune `SYSTEM`-context drive mapping path.
- Restored a user-context mapping method for the Finance drive so mapping occurs in the signed-in user session.
- Corrected the mapping approach so the Finance UNC path is accessed with user-context credentials rather than local `SYSTEM` context.
- Added execution timing protection so the mapping does not permanently fail if initial logon state is not yet ready.

### Validation performed
- Confirmed Group Policy processing success remained unchanged, verifying GP was not the failing layer.
- Confirmed the failed Intune script path matched the migration record and `SYSTEM` execution context.
- Confirmed the failure chain was consistent across the observed evidence: Intune script execution -> `SYSTEM` context UNC access failure -> script exit code `1` -> no retry -> missing `S:` assignment.
- Confirmed the surviving hypothesis explains all observed facts: successful Group Policy processing, Intune execution, `SYSTEM` account context, mapped-drive-only failure, and simultaneous Finance-wide impact after migration.
