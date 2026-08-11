# Incident Closure Note — Autopilot Enrolment Failure

| Field | Detail |
|---|---|
| **Version** | 1.0 |
| **Date** | 07/08/2026 |
| **Status** | Draft |
| **Incident Reference** | INC-Autopilot-EnrolmentFailure-0x80180014 |
| **RCA Reference** | RCA-2026-08-11-AUTOPILOT-001 |
| **Author** | Nikita, DWP Endpoint Engineering |

---

Resolved.

**Cause:**
The device held an active legacy manual MDM enrolment from 2023-11-04 that was never removed before the device was added to the Autopilot deployment group. Autopilot cannot enrol a device with a pre-existing MDM registration and returned `0x80180014` (MENROLL_E_DEVICE_ALREADY_ENROLLED). All 4 Intune configuration profiles failed to apply with `0x80070005` (Access Denied) as a direct downstream consequence of the blocked enrolment.

**Evidence:**
- `EnrollmentState: Failed` / `ErrorCode: 0x80180014` confirmed in MDM diagnostic export.
- `MDMEnrolled: Yes` — legacy manual enrolment dated 2023-11-04 active at time of Autopilot attempt.
- `ProfilesApplied: 0 of 4` / `LastError: 0x80070005` — all profile writes blocked by stale enrolment artefacts.
- Licensing (Intune P1, Autopilot) and network connectivity confirmed healthy — not contributing factors.

**Action Taken:**
1. Stale MDM enrolment disconnected on device via `Settings → Accounts → Access work or school → Disconnect`.
2. Orphaned Intune device record (2023-11-04) deleted from Intune admin center → Devices → All devices.
3. Duplicate AAD device object removed from Azure Active Directory → Devices.
4. Autopilot hardware hash confirmed registered in Intune → Devices → Enrol devices → Windows enrolment → Devices.
5. Full Autopilot Reset performed to return device to clean OOBE state.
6. Autopilot enrolment re-triggered; all 4 configuration profiles applied successfully.

**Verification:**
- Intune → device → Device enrolment: State shows **Enrolled**.
- Intune → device → Device configuration: All 4 profiles show **Succeeded**.
- Intune → device → Device compliance: Status **Compliant** (or **In grace period** pending HAS sync — expected within 24 hours under the DWP 7-day grace period policy).
- No duplicate device record present in Intune or AAD.
- No legacy MDM entry visible on device under `Settings → Accounts → Access work or school`.

**Preventive Action:**
Device repurposing SOP to be updated to mandate a pre-reassignment checklist (MDM disconnect, Intune and AAD object deletion, Autopilot hash verification, full Autopilot Reset) before any device is added to an Autopilot deployment group. Automated stale-enrolment detection report and staff briefing scheduled. Full preventive action plan documented in RCA-2026-08-11-AUTOPILOT-001.

**User Impact:**
Device was unavailable for use during the incident period. No data loss and no business systems were affected. Device has been fully re-provisioned and returned to the user. User confirmed able to log in and access required services.

---

*Closure note prepared by Nikita, DWP Endpoint Engineering — 07/08/2026.*
