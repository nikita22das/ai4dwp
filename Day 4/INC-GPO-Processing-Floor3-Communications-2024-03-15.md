# Incident Communications - Group Policy Processing (Floor 3)

## Audience 1: Business Leadership
Service has been fully restored for the Floor 3 policy processing incident. The affected devices are now receiving correct network settings, and policy application is operating normally again. We have validated recovery and put follow-up controls in place to reduce recurrence risk during future infrastructure changes. There is no ongoing user disruption from this incident.

## Audience 2: Affected Users
We have completed the fix for this morning's device policy issue on Floor 3. A network setting in the background was pointing some devices to an old system, which caused sign-in policy checks to fail. That setting has been corrected, devices have refreshed, and policy processing is now working normally. If you still notice unusual behavior, please contact the DWP Service Desk through the standard IT support channel and mention the Floor 3 Group Policy incident.

## Audience 3: Infrastructure Engineers
Root Cause:
- Floor 3 DHCP scope Option 006 contained decommissioned DNS server entries after migration.

DHCP Scope Issue:
- Affected clients (FB055-FB057) received legacy DNS via DHCP.
- Comparison host (FB058) had correct DNS and processed GP successfully.

DNS Impact:
- Clients could not reliably resolve FINBRIDGE-DC01.finbridge.local.
- Observed DNS timeout/no-response pattern aligned with old DNS assignment.

GP Processing Impact:
- Netlogon DC discovery/secure channel failed at startup.
- GP failed to access SYSVOL gpt.ini and to enumerate GPO list.
- Failure sequence matched 5719 -> 1058/1030 -> 1129 pattern.

Resolution:
- Updated Floor 3 DHCP scope Option 006 to approved current DNS set at 09:10.
- Removed decommissioned DNS entries.
- Renewed impacted client leases and refreshed policy processing.

Verification:
- Affected clients received corrected DNS after renew.
- DC name resolution and discovery succeeded.
- GP processing validated successfully on previously affected endpoints.

Preventive Action:
- Add mandatory pre/post-cutover DHCP Option 006 validation checklist.
- Implement DHCP scope drift checks against approved DNS baseline.
- Add post-change alerting for spikes in 5719, 1014, 1058, 1030, and 1129.
- Require pilot lease-test evidence per impacted subnet before migration closure.
