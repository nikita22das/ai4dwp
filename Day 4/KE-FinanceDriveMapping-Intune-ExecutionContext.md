Symptom
Finance users on DESKTOP-FB* devices did not receive mapped drive S: after sign-in following the drive-mapping migration. On affected systems, GroupPolicy Event 1500 still showed successful Group Policy processing, while Ntfs Event 98 reported that drive letter S: had not been assigned.

Cause
The Finance drive mapping was migrated from a GPO logon script running in USER context to an Intune PowerShell script running in SYSTEM context. Intune Management Extension logs showed `Map-FinBridgeDrives.ps1` executed as SYSTEM, failed to access `\\finbridge-fs01\Finance`, and exited with code 1 with `Network name cannot be found`.

Scope
The incident affected approximately 45 Finance users on DESKTOP-FB* devices. The symptom was limited to the Finance mapped drive workflow and began immediately after the overnight migration change.

Workaround
Service was restored by reverting the drive mapping back to a user-context execution method. After affected users logged off and back on, mapped drive S: appeared successfully.

Permanent Fix
Keep Finance mapped-drive delivery in a user-context execution path for this workflow. Future GPO-to-Intune migrations for user-mapped drives must include execution-context validation and pilot testing before broad deployment.

How To Spot It
Look for Intune Management Extension entries showing `Map-FinBridgeDrives.ps1` running in SYSTEM context, followed by failure to access `\\finbridge-fs01\Finance`, exit code 1, and `Network name cannot be found`. Correlate that with GroupPolicy Event 1500 success and Ntfs Event 98 indicating drive S: was not assigned.
