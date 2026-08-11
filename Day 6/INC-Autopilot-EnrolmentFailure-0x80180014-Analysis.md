# INC – Autopilot Enrolment Failure: 0x80180014 / 0x80070005

**Author:** DWP Endpoint Engineer  
**Date:** 2026-08-11  
**Status:** Resolved  
**Severity:** Medium  
**Affected Device:** *(device identifier to be substituted from asset register)*  
**Analyst:** DWP Analyst  

---

## 1. Incident Summary

A Windows 11 device failed Microsoft Autopilot enrolment with error `0x80180014` ("The device is already enrolled in MDM"). The device had a pre-existing legacy manual MDM enrolment dating from 2023-11-04 that was never removed prior to the Autopilot flow being initiated. As a downstream consequence, 0 of 4 Intune configuration profiles were applied, with each policy-write attempt returning `0x80070005` (Access Denied). Network connectivity and licensing were confirmed healthy throughout.

---

## 2. Scope Facts (Extracted from MDM Diagnostic Export)

| Field | Value |
|---|---|
| **Enrolment State** | Failed |
| **Primary Error Code** | `0x80180014` — The device is already enrolled in MDM |
| **Azure AD Joined** | Yes |
| **Existing MDM Enrolment** | Yes — legacy manual enrolment, dated 2023-11-04 |
| **Enrolment Source** | Legacy manual MDM enrolment |
| **Profiles Applied** | 0 of 4 |
| **Policy Error Code** | `0x80070005` — Access Denied |
| **Intune P1 Licence** | Present and valid |
| **Autopilot Licence** | Present and valid |
| **Network Connectivity** | All endpoints reachable; no proxy issues |

**Scope conclusions:**
- Enrolment failure is not a licensing or network problem.
- The primary block is the stale 2023 MDM enrolment.
- Policy failure (`0x80070005`) is a downstream consequence of the stale enrolment, not an independent fault.

---

## 3. Hypothesis Ranking

### Cause 1 — Stale legacy MDM enrolment blocking Autopilot re-enrolment *(confirmed primary cause)*

**Why it fits the evidence:**  
`0x80180014` is the definitive "device already enrolled" error (`MENROLL_E_DEVICE_ALREADY_ENROLLED`). The diagnostic export confirms an active MDM enrolment from 2023-11-04 under a legacy manual enrolment source. Autopilot cannot enrol a device that already holds an MDM enrolment record — it requires the device to arrive at OOBE with no prior enrolment state.

**Fastest check:**  
On the device: `Settings → Accounts → Access work or school` — a live Workplace Join or MDM entry will be visible.  
In Intune: Devices → All devices — look for a duplicate device record with the same hardware hash or serial number bearing an enrolment date of 2023-11-04.

**Remediation:**
1. Remove the stale enrolment from the device: `Settings → Accounts → Access work or school → [account] → Disconnect`.
2. Delete the orphaned device object from Intune admin center (Devices → All devices → [stale record] → Delete).
3. If a duplicate AAD device object exists, remove it from Azure Active Directory → Devices.
4. Re-trigger Autopilot (see Section 5).

---

### Cause 2 — Device not wiped or reset before the Autopilot flow was initiated *(confirmed contributing cause)*

**Why it fits the evidence:**  
The presence of a 2023 legacy manual enrolment indicates the device was previously under standard MDM management and was repurposed or reassigned without a factory reset. Autopilot is designed to be initiated from a clean OOBE state. Skipping the reset step is the process failure that allowed the stale enrolment in Cause 1 to persist.

**Fastest check:**  
In Intune: Devices → All devices → [device] → Overview — if the Management name reflects the legacy profile rather than the Autopilot deployment profile, or if the enrolment date predates the current Autopilot attempt, the device was not reset.  
Confirm the device's Autopilot hardware hash is registered: Devices → Enrol devices → Windows enrolment → Devices (Autopilot).

**Remediation:**  
Before re-enrolment, perform a full Autopilot reset:
- **Remotely (preferred):** Intune → device → **Autopilot Reset** (requires device to be reachable).
- **Locally:** Settings → System → Recovery → **Reset this PC → Remove everything**.
- Do not proceed with Autopilot until the device presents the OOBE welcome screen cleanly.

---

### Cause 3 — Stale enrolment artefacts causing `0x80070005` on policy write *(downstream consequence)*

**Why it fits the evidence:**  
`0x80070005` is the standard Windows `ERROR_ACCESS_DENIED`. With 0 of 4 profiles applied, the MDM client reached the policy-write phase but was denied at each attempt. In the context of a stale enrolment, the most probable mechanism is that the existing enrolment's registry hive entries (`HKLM\SOFTWARE\Microsoft\Enrollments\<GUID>`) and MDM certificates are locking the policy store, preventing the new enrolment from writing CSP values.

**Fastest check:**  
On the device, open Event Viewer → `Applications and Services Logs → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostics-Provider → Admin`. Filter for event IDs 404 and 406 to identify which CSP path is being denied and whether the block originates from an existing certificate or registry lock.

**Remediation:**  
Resolving Causes 1 and 2 (removing the stale enrolment and performing a full reset) will eliminate the artefacts causing this error. If the `0x80070005` persists after re-enrolment on a clean device, manually purge residual state:
```
# Remove stale MDM registry keys (run as SYSTEM or elevated)
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Enrollments\<stale-GUID>" -Recurse -Force

# Remove stale MDM certificates
certlm.msc → Personal → Certificates → remove any certificate issued to the old MDM enrolment GUID
```
Restart services after manual purge:
```powershell
Restart-Service -Name dmwappushsvc -Force
Restart-Service -Name DeviceManagementService -Force
```

---

## 4. Root Cause

The device was repurposed and assigned to the Autopilot deployment group without first being wiped. The legacy manual MDM enrolment from 2023-11-04 was never removed. When Autopilot attempted to enrol the device, it encountered the live MDM registration and returned `0x80180014`. The Autopilot flow halted at enrolment; no profiles were applied. The `0x80070005` errors on profile application are a direct consequence of the blocked enrolment — not an independent permissions fault.

**Contributing process failure:** No device wipe or Autopilot reset was performed before the device was re-assigned and the Autopilot flow initiated.

---

## 5. Resolution Steps (Ordered)

| Step | Action | Owner | Notes |
|---|---|---|---|
| 1 | Confirm stale enrolment in `Settings → Accounts → Access work or school` | On-site technician / remote session | Validates Cause 1 before destructive action |
| 2 | Delete orphaned device record from Intune (Devices → All devices → Delete) | Intune Admin | Remove the 2023-11-04 record |
| 3 | Remove duplicate AAD device object if present (AAD → Devices) | Intune Admin | Prevents hash conflict on re-enrolment |
| 4 | Perform full **Autopilot Reset** or wipe (Remove everything) | Technician / Intune Admin | Must complete before re-enrolment attempt |
| 5 | Confirm device hardware hash is registered in Autopilot device list | Intune Admin | Devices → Enrol devices → Windows enrolment → Devices |
| 6 | Allow device to complete OOBE and Autopilot enrolment flow | Unattended / user | Monitor via Enrolment status page |
| 7 | Validate all 4 profiles applied in Intune → device → Device configuration | Intune Admin | Confirm no residual `0x80070005` |
| 8 | Confirm compliance state once HAS sync completes (up to 24 h) | Intune Admin | BitLocker/Secure Boot HAS reporting may lag |

---

## 6. Compliance Impact During Resolution

Per the DWP Windows 11 Intune Compliance Policy (grace period: 7 days):

| Compliance Setting | Expected State During Resolution | Risk |
|---|---|---|
| BitLocker | In grace period until HAS sync completes post-reset | Low — 7-day grace covers HAS sync delay |
| Secure Boot | Compliant immediately if UEFI is configured correctly | None |
| Minimum OS Build | Dependent on image version used for reset | Check image build against `10.0.22621.2861` minimum |
| Defender RTP | Should apply via profile once enrolment succeeds | Resolved by Step 6 |
| Firewall | Should apply via profile once enrolment succeeds | Resolved by Step 6 |
| PIN / Password | WHfB provisioning during OOBE — grace period covers this | Low |
| Device Integrity (MDE) | MDE onboarding latency may temporarily elevate risk score | Low — grace period covers initial scan |

---

## 7. Prevention Recommendations

1. **Add a wipe checkpoint to the device repurposing SOP.** Before any device is reassigned to an Autopilot deployment group, require documented confirmation that a full reset (Remove everything) has been performed and the old Intune/AAD device objects have been deleted.

2. **Automate stale enrolment detection.** Use an Intune Device Filter or Azure AD dynamic group to flag devices with an enrolment date older than 12 months that have been re-added to an Autopilot group, triggering a review workflow.

3. **Use Autopilot Reset as the standard repurposing method** rather than manual wipes where devices are already Intune-managed — this ensures DMCLIENT state, MDM certificates, and registry artefacts are fully cleared by the platform.

4. **Monitor Autopilot enrolment failures centrally.** Intune → Devices → Monitor → **Autopilot deployments** — review failure trends weekly; `0x80180014` appearing repeatedly indicates a systemic process gap in the device repurposing workflow.

---

## 8. Related Documentation

| Document | Location |
|---|---|
| DWP Windows 11 – Intune Compliance Policy: Security Baseline Translation | Day 6/DWP-Win11-Intune-Compliance-Policy.md |
| Intune Compliance Policy – Grace Period Configuration | Day 6/DWP-Win11-Intune-Compliance-Policy.md § How to Apply the Grace Period |

---

*Document prepared by DWP Endpoint Engineering — 2026-08-11*
