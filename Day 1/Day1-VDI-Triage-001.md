# Triage Summary – VDI Connection Failure

## Summary
User unable to connect to VDI session from home; connection was working on Friday.

---

## Impact
- **Who:** Single end user (working from home)
- **How many:** 1 user affected (to confirm if wider outage)
- **Business urgency:** High – user has no access to their desktop/work environment; fully blocked from working

---

## Known Facts
- User cannot connect to VDI (Virtual Desktop Infrastructure)
- Error message displayed: "cannot connect"
- Connection was working successfully on Friday (last known good state)
- User is working from home on a Wi-Fi connection
- Issue started today (2026-08-04)

---

## Missing Information to Gather
- Full exact error message text (to confirm)
- VDI client name and version in use (e.g. Citrix Workspace, VMware Horizon, AVD client) (to confirm)
- User's device type and OS (managed DWP device or personal?) (to confirm)
- Whether any Windows updates or client software updates were applied over the weekend (to confirm)
- Whether other users on the same VDI platform are affected (to confirm – possible service-wide outage)
- Whether the user has tried restarting the VDI client and/or the device (to confirm)
- Whether the user's Wi-Fi connection is otherwise working (e.g. can they browse the internet?) (to confirm)
- Whether MFA/authentication prompt appeared or failed silently (to confirm)
- Any changes to home network or router over the weekend (to confirm)

---

## Likely Category
**VDI / Remote Access Connectivity**
Sub-categories to consider:
- VDI platform service disruption (check for known incidents first)
- VDI client software fault or update issue
- Home network / Wi-Fi connectivity or DNS issue
- Authentication / MFA failure
- Split-tunnel VPN or gateway issue (if applicable)

---

## Suggested First Diagnostic Step
**Check for a known incident or service alert on the VDI platform before troubleshooting the individual device.**

If no known incident:
Ask the user to confirm their internet connectivity is working (e.g. can they load a webpage?), then ask them to close and reopen the VDI client, attempt to reconnect, and provide the exact error message and any error code shown on screen.
