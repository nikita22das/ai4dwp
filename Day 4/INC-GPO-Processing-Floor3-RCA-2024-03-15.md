# Root Cause Analysis (RCA)

## Incident
Group Policy Processing Failure - Floor 3 Finance Endpoints

## Document Control
- Incident date: 2024-03-15
- RCA authored: 2026-08-07
- Scope: Floor 3 Finance endpoints
- Affected machines: FB055, FB056, FB057
- Comparison machine (unaffected): FB058

## Executive Summary
On 2024-03-15, three Floor 3 Windows 11 endpoints in the Finance OU failed Group Policy processing during startup. Investigation confirmed that the Floor 3 DHCP scope was still distributing decommissioned DNS server addresses after a migration change. Because affected clients could not resolve the domain controller FQDN reliably, they could not access SYSVOL and failed Group Policy processing. Remediation was completed successfully: DHCP scope was corrected at 09:10 AM, affected machines renewed network configuration, received correct DNS, and Group Policy processing was verified as successful.

## Impact Assessment
- Service impacted: Active Directory Group Policy processing at startup.
- User/device impact: 3 of 4 in-scope Floor 3 Finance machines failed policy application during the incident window.
- Business impact: Security and configuration baselines linked to Group Policy were not reliably applied on affected endpoints until remediation.
- Geographic/logical impact: Floor 3 subnet/scope population relying on outdated DNS from DHCP.
- Duration: From first observed startup failures in the 07:40 window until remediation completion after 09:10 AM.

## Timeline
- 07:40:02 - DESKTOP-FB031: Service Control Manager 7036, Network Location Awareness entered running state.
- 07:40:08 - DESKTOP-FB031: Netlogon 5719, no domain controller available; DNS query for FINBRIDGE-DC01.finbridge.local returned no response.
- 07:40:09 - DESKTOP-FB031: GroupPolicy 1058, failed to access \\FINBRIDGE-DC01\sysvol\finbridge.local\Policies\{3A1B2C4D-E5F6-7890-ABCD-EF1234567890}\gpt.ini, error 0x3.
- 07:40:10 - DESKTOP-FB031: GroupPolicy 1030, cannot query list of GPOs, error 0x546.
- 07:40:11 - DESKTOP-FB031: GroupPolicy 1058 repeated.
- 07:40:12 - DESKTOP-FB031: GroupPolicy 1129, no network connectivity to a domain controller.
- 07:41:05 - DESKTOP-FB031: DNS Client 1014, FINBRIDGE-DC01.finbridge.local resolution timed out; configured DNS servers did not respond.
- 07:42:18 - DESKTOP-FB031: DHCP Client 50036, lease obtained; DNS assigned 10.10.3.250 (old/decommissioned).
- 07:44:01 - DESKTOP-FB031: GroupPolicy 1129 repeated, no DC connectivity.
- 07:40:05 - DESKTOP-FB058 (comparison): DHCP Client 50036, DNS assigned 10.10.0.10 (correct).
- 07:40:11 - DESKTOP-FB058 (comparison): GroupPolicy 1500, policy processed successfully.
- 09:10 AM - Remediation change implemented: Floor 3 DHCP scope corrected to distribute current DNS server configuration.
- Post-09:10 AM - Affected machines renewed IP configuration, received correct DNS, and Group Policy processing was validated as successful.

## Evidence Reviewed
- System event log sequence from affected endpoint DESKTOP-FB031 during 07:40-07:55 startup window.
- System event comparison from unaffected same-OU endpoint DESKTOP-FB058.
- DHCP assignment comparison indicating affected hosts received decommissioned DNS while unaffected host had correct DNS.
- Confirmed remediation status from operations update:
  - DHCP scope corrected at 09:10 AM.
  - Affected machines renewed IP configuration.
  - Correct DNS assignment confirmed.
  - Group Policy processing verified successfully.

## Root Cause Analysis
Primary root cause:
- Floor 3 DHCP scope Option 006 still referenced decommissioned DNS server entries after migration, causing affected clients to use invalid DNS infrastructure.

Causal chain:
1. Client receives old DNS from DHCP.
2. Client cannot resolve FINBRIDGE-DC01.finbridge.local consistently.
3. Netlogon fails DC discovery/secure channel setup at startup.
4. Group Policy client cannot reach SYSVOL gpt.ini and cannot enumerate GPO list.
5. Group Policy processing fails with 1058/1030/1129 sequence.

Why same OU had mixed outcomes:
- FB058 received correct DNS (10.10.0.10) and processed policy successfully, proving OU-linked policy objects were not broadly corrupt and that network naming path was the differentiator.

## Technical Findings
- Netlogon 5719 and DNS Client 1014 establish direct DNS/DC discovery failure on affected machine(s).
- GroupPolicy 1058 with path \\FINBRIDGE-DC01\sysvol\...\gpt.ini and GroupPolicy 1030 indicate inability to retrieve policy metadata from SYSVOL.
- GroupPolicy 1129 confirms failure condition as no connectivity to a domain controller during policy processing.
- DHCP 50036 on affected host showed old DNS assignment; DHCP 50036 on unaffected host showed correct DNS assignment.
- The unaffected same-OU host successful GroupPolicy 1500 event reduces likelihood of OU policy object corruption and strengthens configuration-path root cause.

## Resolution Steps
1. Corrected Floor 3 DHCP scope DNS option to current DNS server set at 09:10 AM.
2. Removed decommissioned DNS entries from scope configuration.
3. Renewed IP configuration on affected endpoints.
4. Confirmed affected clients received corrected DNS assignment.
5. Triggered/verified Group Policy processing post-change.

## Validation Results
- DHCP state validation: Affected endpoints obtained updated lease information with correct DNS server.
- DNS path validation: Domain controller name resolution restored on affected clients after DHCP correction.
- Group Policy validation: Policy processing succeeded on previously affected endpoints.
- Outcome validation: Incident symptoms (DC lookup failures and GP processing errors) no longer reproduced after remediation.

## Five Why Analysis
1. Why did Group Policy fail on FB055-FB057?
Because clients could not contact a domain controller and access SYSVOL during policy processing.

2. Why could clients not contact the domain controller?
Because DC FQDN resolution failed and DNS queries timed out.

3. Why did DNS resolution fail on affected clients?
Because affected clients were using decommissioned DNS servers.

4. Why were affected clients using decommissioned DNS servers?
Because Floor 3 DHCP scope still distributed legacy DNS entries after migration.

5. Why did legacy DNS entries remain in DHCP scope?
Because DHCP scope update/validation was incomplete during migration cutover governance.

## Preventive Action
- Implement mandatory pre-cutover and post-cutover DHCP Option 006 checklist for each subnet.
- Add automated drift detection for DHCP scopes against approved DNS baseline.
- Enforce change gate requiring evidence of lease-test validation from at least one pilot endpoint per impacted subnet.
- Add monitoring alert for spikes in Event IDs 5719, 1014, 1058, 1030, and 1129 after network/DNS migrations.
- Maintain rollback-ready DHCP configuration snapshots for rapid restoration.

## Lessons Learned
- DNS dependency for Group Policy is operationally critical; DHCP scope hygiene must be treated as a release-critical control.
- Same-OU success/failure comparison is a high-value triage discriminator for separating policy content issues from infrastructure path issues.
- Migration runbooks must include explicit ownership and sign-off for DHCP scope updates, not only DNS server decommission tasks.
- Fastest recovery path in similar incidents is to restore correct client DNS path first, then validate DC discovery and GP processing.
