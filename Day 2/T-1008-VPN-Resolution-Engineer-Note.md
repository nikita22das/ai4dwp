Engineer note:
Root cause:
- Win11 upgrade removed legacy VPN client.
- Intune did not re-deploy new VPN client due to detection-rule gap.

Exact action taken:
- Manually removed stale VPN registry entries under HKLM\SOFTWARE\<vendor>.
- Force-triggered Intune sync.
- New VPN client deployed.
- Split-tunnel config applied.

Config detail:
- Registry cleanup path: HKLM\SOFTWARE\<vendor> (stale VPN entries removed).
- Post-deploy policy state: split-tunnel configuration in effect.

Verification:
- Connectivity confirmed to all internal subnets.
- No data loss.

Preventive action needed:
- Close the Intune detection-rule gap so Win11 upgrade scenarios reliably trigger re-deployment of the new VPN client.
