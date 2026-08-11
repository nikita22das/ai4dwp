# Incident Communication — Autopilot Enrolment Failure

| Field | Detail |
|---|---|
| **Version** | 1.0 |
| **Date** | 07/08/2026 |
| **Status** | Draft |
| **Author** | Nikita, DWP Endpoint Engineering |
| **Incident Reference** | INC-Autopilot-EnrolmentFailure-0x80180014 |
| **RCA Reference** | RCA-2026-08-11-AUTOPILOT-001 |

---

## Audience 1 — Business Leadership

**Subject: Device Setup Delay — Resolved**

A Windows 11 device failed to complete its automated setup process, leaving it temporarily unavailable for the assigned user. No data was lost and no business systems were compromised. The cause was an outdated configuration record from 2023 that had not been cleared before the device was reissued. The issue has been resolved and the device is being re-provisioned. A process update is being implemented to prevent recurrence on any future reissued devices.

**Current status: Resolved. Device re-provisioning in progress.**

---

## Audience 2 — Affected Users

**Subject: Update on your device setup**

Hi,

Thank you for your patience. We are aware that your new device did not complete its setup correctly and was unavailable for use. This happened because an old management record from a previous user was still attached to the device — our automated setup tool detected this and stopped to prevent a conflict.

We have cleared the old record and your device is being fully reset and reconfigured. You do not need to do anything at this stage — our team will contact you directly when your device is ready.

If you continue to see a setup error screen or are unable to log in once we have been in touch, please contact the DWP Service Desk and reference **INC-Autopilot-EnrolmentFailure-0x80180014** so we can prioritise your call.

Thank you,
DWP IT Support

---

## Audience 3 — Technical Stakeholders

**Subject: Technical Incident Summary — Autopilot Enrolment Failure (0x80180014 / 0x80070005)**

---

### Root Cause

A Windows 11 device failed Autopilot enrolment because a legacy manual MDM enrolment from 2023-11-04 was still active on the device at the point the Autopilot flow was initiated. Autopilot requires a clean device state with no prior MDM registration. The presence of the stale enrolment caused the Microsoft Enrolment Service to return `MENROLL_E_DEVICE_ALREADY_ENROLLED` (`0x80180014`) and halt the flow.

The `0x80070005` (Access Denied) errors recorded against all 4 profile-write attempts are confirmed downstream consequences: the existing enrolment's registry artefacts (`HKLM\SOFTWARE\Microsoft\Enrollments\<GUID>`) and MDM certificates blocked the new enrolment context from writing to the CSP policy store. They are not an independent fault.

**Root cause statement:** The device repurposing process did not enforce MDM de-registration or a device wipe before the device was added to the Autopilot deployment group.

---

### Supporting Evidence

| Evidence | Value |
|---|---|
| Enrolment State | Failed |
| Primary error | `0x80180014` — MENROLL_E_DEVICE_ALREADY_ENROLLED |
| Active legacy enrolment | `MDMEnrolled: Yes` — dated 2023-11-04, source: Legacy manual MDM |
| Profiles applied | 0 of 4 |
| Secondary error | `0x80070005` — Access Denied (policy write) |
| Azure AD Joined | Yes |
| Intune P1 Licence | Present and valid |
| Autopilot Licence | Present and valid |
| Network connectivity | All endpoints reachable; no proxy |

Licensing, network, and Azure AD join state were each confirmed healthy. The failure was isolated entirely to the stale enrolment condition.

---

### Resolution Implemented

1. Stale MDM enrolment disconnected from device via `Settings → Accounts → Access work or school → Disconnect`.
2. Orphaned Intune device record (2023-11-04) deleted from Intune admin center → Devices → All devices.
3. Duplicate AAD device object removed from Azure Active Directory → Devices.
4. Autopilot hardware hash confirmed present in Intune → Devices → Enrol devices → Windows enrolment → Devices.
5. Full Autopilot Reset initiated to return device to clean OOBE state.
6. Autopilot enrolment flow re-triggered; all 4 configuration profiles targeted for application.

---

### Verification Results

| Check | Expected | Status |
|---|---|---|
| Enrolment state | Enrolled | Pending — Autopilot reset in progress |
| Profiles applied | All N profiles: Succeeded | Pending |
| Compliance state | Compliant or In grace period | Pending — HAS sync may take up to 24 h |
| No duplicate device record in Intune | Single record only | Confirmed — legacy record deleted |
| No legacy MDM entry on device | Access work or school shows current enrolment only | Confirmed — legacy entry disconnected |
| Error codes absent post-enrolment | No `0x80180014` or `0x80070005` | Pending — to be validated after reset completes |

> BitLocker and Secure Boot compliance may show *In grace period* for up to 24 hours post-enrolment due to Health Attestation Service sync latency. This is expected under the DWP 7-day grace period policy.

---

### Preventive Actions

| Ref | Action | Owner | Target Date |
|---|---|---|---|
| PA-01 | Update device repurposing SOP to mandate a pre-reassignment checklist: MDM disconnect, Intune object deletion, AAD object deletion, Autopilot hash verification, and full wipe before reassignment is closed | DWP Endpoint Engineering — SOP Owner | Within 14 days of RCA sign-off |
| PA-02 | Implement automated stale-enrolment detection: weekly report of devices in Autopilot deployment groups with enrolment dates older than 18 months | DWP Intune Administrator | Within 21 days of RCA sign-off |
| PA-03 | Mandate Autopilot Reset (via Intune) as the standard repurposing method for all currently Intune-managed devices; manual wipes reserved only for unreachable devices | DWP Endpoint Engineering | Incorporated into PA-01 SOP revision |
| PA-04 | Deliver targeted briefing to all device repurposing staff covering Autopilot prerequisites, updated SOP, and Autopilot Reset procedure | DWP Endpoint Engineering Lead | Within 21 days of RCA sign-off |
| PA-05 | Establish a standing platform-change SOP review trigger: any new device management platform or deployment method adoption must initiate a formal SOP review within 30 days | DWP Endpoint Engineering Lead / Change Manager | Within 30 days of RCA sign-off |

---

*Incident Communication prepared by Nikita, DWP Endpoint Engineering — 07/08/2026.*  
*All content based on verified RCA-2026-08-11-AUTOPILOT-001 facts only. No assumptions introduced.*
