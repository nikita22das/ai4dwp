Resolved.

Cause:
Drive mapping was migrated from a user-context GPO logon script to an Intune PowerShell script running in SYSTEM context, and the script failed to access the Finance share in that execution context.

Action:
The drive mapping method was reverted to a user-context execution path, affected users logged off and back on, and mapped drive S: returned successfully.

Preventive:
Require execution-context validation and pilot testing for all GPO-to-Intune drive-mapping migrations before broad deployment.

Finance users verified drive access restored.
