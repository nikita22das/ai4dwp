# Incident Communications - Finance Drive Mapping

## Audience 1: Finance Leadership
Finance shared drive access has been fully restored. This morning's issue was caused by a background change to the drive-mapping method, which has now been reversed to the stable version. Affected users signed out and back in, and access returned successfully. No further user reports have been received, and there is no indication of ongoing disruption.

## Audience 2: Finance Users
Your Finance shared drive access has now been restored. This morning, a background change affected how the `S:` drive was connected, so the drive did not appear for some users after sign-in. We have reversed that change, and the normal method is back in place. Please sign out and sign back in if you have not already done so. If `S:` still does not appear, contact the Service Desk and mention the Finance drive mapping incident.

## Audience 3: Infrastructure Engineering Team
Status: Resolved.

Root Cause:
- Finance drive mapping was migrated from a GPO logon script running in `USER` context to an Intune PowerShell script running in `SYSTEM` context.
- The script was not updated for `SYSTEM`-context execution and failed when attempting to access `\\finbridge-fs01\Finance` at logon.

Intune execution context:
- Intune Management Extension launched `Map-FinBridgeDrives.ps1` at 08:00:01.
- Log evidence recorded `SYSTEM` as the script context.
- The script then failed with `Network name cannot be found` and no retry configured.

`USER` vs `SYSTEM` difference:
- `USER` context runs in the signed-in user's interactive session and supports user-scoped mapped-drive behavior.
- `SYSTEM` context runs as the local machine account outside the user's identity context.
- That execution-model change broke the original mapping design even though the script path itself was deployed successfully.

Resolution:
- Reverted the drive mapping method to a user-context execution path.
- Removed or bypassed the broken `SYSTEM`-context mapping path.
- Had affected users log off and back on so the restored mapping process could run in-session.

Validation performed:
- Confirmed GroupPolicy Event 1500 still showed successful policy processing, ruling out GP failure.
- Confirmed Intune logs showed the failing `SYSTEM`-context script path.
- Confirmed post-reversion that mapped drive `S:` appeared successfully after user sign-in.
- Confirmed no further user reports after restoration.

Preventive controls:
- Add execution-context review to all GPO-to-Intune script migrations.
- Require pilot validation before broad deployment of user-resource mappings.
- Add logging standards for Intune scripts covering context, target path, result code, and retry behavior.
- Require rollback steps in change records for endpoint management migrations.
- Document that user mapped drives must remain user-context unless a different design is explicitly tested and approved.
