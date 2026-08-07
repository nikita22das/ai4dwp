Symptom
On affected Floor 3 Finance endpoints, Group Policy processing failed during startup with GroupPolicy Event IDs 1058, 1030, and 1129. Netlogon Event 5719 and DNS Client Event 1014 were also observed, indicating domain controller lookup/connectivity failure.

Cause
The Floor 3 DHCP scope Option 006 distributed decommissioned DNS servers after migration. With invalid DNS, clients could not resolve FINBRIDGE-DC01.finbridge.local, which led to domain controller discovery failure and downstream Group Policy processing failure.

Scope
Impacted devices were FB055, FB056, and FB057 on the Floor 3 Finance scope. FB058 in the same OU was unaffected because it had correct DNS assignment and recorded GroupPolicy Event 1500 success.

Workaround
Before DHCP correction, set affected clients to use the correct DNS server temporarily, then renew network configuration. This restores DC name resolution and allows Group Policy processing to complete.

Permanent Fix
At 09:10 AM, the Floor 3 DHCP scope was corrected to remove decommissioned DNS entries and provide the approved current DNS server configuration. Affected machines renewed IP configuration, received correct DNS, and Group Policy processing was verified successfully.

How To Spot It
Look for startup sequence indicators: Netlogon 5719, DNS Client 1014, then GroupPolicy 1058/1030/1129 on affected clients. Confirm DHCP Client Event 50036 shows old DNS assignment on failing devices versus correct DNS on healthy comparison devices, and verify loss of access to \\FINBRIDGE-DC01\sysvol\...\gpt.ini.
