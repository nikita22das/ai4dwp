# Known Error Record

| Field | Detail |
|---|---|
| **Title** | Known Error Record — Autopilot Enrolment Failure: Stale Legacy MDM Enrolment |
| **KER Reference** | KER-2026-08-001 |
| **Version** | 1.0 |
| **Date** | 07/08/2026 |
| **Author** | Nikita |
| **Status** | Draft |
| **Source RCA** | RCA-2026-08-11-AUTOPILOT-001 |
| **Review Date** | 07/09/2026 |

---

## 1. Symptom

A Windows 11 device fails Microsoft Autopilot enrolment at the OOBE enrolment phase. The device does not progress past enrolment. The Intune admin center shows:

- **Enrolment State:** Failed
- **Error Code:** `0x80180014`
- **Error Description:** *The device is already enrolled in MDM.*
- **Profiles Applied:** 0 of the expected number of Intune configuration profiles
- **Secondary Error:** `0x80070005` (Access Denied) recorded against all profile-write attempts

The device is Azure AD joined and all required licences (Intune P1, Autopilot) are present. Network connectivity to all Intune/Autopilot endpoints is healthy.

---

## 2. Scope

| Field | Detail |
|---|---|
| **Platform** | Windows 11, Intune MDM enrolled |
| **Deployment method** | Microsoft Autopilot (user-driven or pre-provisioning mode) |
| **Affected device state** | Devices previously enrolled via **legacy manual MDM enrolment** that have not been wiped or de-registered before being added to an Autopilot deployment group |
| **Trigger condition** | Autopilot initiated on a device that still holds an active MDM enrolment record |
| **Not in scope** | Devices that failed Autopilot for network, licensing, hardware hash, or Conditional Access reasons — those present different error codes |

---

## 3. Cause

The device carries a pre-existing active MDM enrolment from a prior management lifecycle. Autopilot requires the device to arrive at OOBE with no MDM registration. When an active enrolment is detected, the Microsoft enrolment service returns `MENROLL_E_DEVICE_ALREADY_ENROLLED` (`0x80180014`) and halts the Autopilot flow.

The `0x80070005` (Access Denied) errors on profile application are a **downstream consequence**: the existing enrolment's registry keys (`HKLM\SOFTWARE\Microsoft\Enrollments\<GUID>`) and MDM certificates block the new enrolment context from writing to the CSP policy store. They are not an independent fault.

**Root cause:** The device repurposing process did not include a mandatory MDM de-registration and device wipe step before the device was added to the Autopilot deployment group.

---

## 4. Detection

### Primary Indicators

| Indicator | Location | Value to look for |
|---|---|---|
| Enrolment error code | MDM diagnostic export / Intune → device → Device enrolment | `0x80180014` |
| Error description | MDM diagnostic export | *"The device is already enrolled in MDM"* |
| Active MDM enrolment | MDM diagnostic export — `MDMEnrolled` field | `Yes` with a date preceding the current Autopilot attempt |
| Enrolment source | MDM diagnostic export — `EnrolmentSource` field | `Legacy manual MDM enrolment` or any non-Autopilot source |
| Profiles applied | MDM diagnostic export — `ProfilesApplied` field | `0 of N` |
| Secondary error | MDM diagnostic export — `LastError` field | `0x80070005` |

### Log Locations

| Log | Path | What to look for |
|---|---|---|
| Autopilot / MDM enrolment events | Event Viewer → `Applications and Services Logs → Microsoft → Windows → DeviceManagement-Enterprise-Diagnostics-Provider → Admin` | Event IDs 72 (enrolment failure), 404, 406 (policy write access denied) |
| MDM diagnostic report | Run `MdmDiagnosticsTool.exe -out C:\MDMLogs` on the device, or collect via Intune → device → **Collect diagnostics** | `MDMEnrolled`, `EnrollmentState`, `ErrorCode`, `LastError` fields |
| Device enrolment state (Intune portal) | Intune → Devices → All devices → [device] → **Device enrolment** | State: Failed; error code visible inline |

### Confirming the Stale Enrolment on the Device

```
Settings → Accounts → Access work or school
```
A live Workplace Join or MDM entry from a prior management period will be visible. Cross-check in Intune: Devices → All devices — look for a duplicate device record bearing the legacy enrolment date.

---

## 5. Workaround

> Use this workaround to unblock the device immediately while the permanent fix (SOP update and process gate) is implemented.

**Step 1 — Remove the stale MDM enrolment from the device**

```
Settings → Accounts → Access work or school → [legacy account entry] → Disconnect
```

**Step 2 — Delete the orphaned Intune device record**

```
Intune admin center → Devices → All devices → [stale device record] → Delete
```

**Step 3 — Remove the duplicate AAD device object (if present)**

```
Azure Active Directory → Devices → [device with legacy enrolment date] → Delete
```

**Step 4 — Purge residual DMCLIENT artefacts (if Steps 1–3 do not fully clear the state)**

Run the following as SYSTEM or elevated administrator on the device:

```powershell
# Identify stale enrolment GUID
Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Enrollments" |
    Where-Object { (Get-ItemProperty $_.PSPath).EnrollmentType -ne $null } |
    Select-Object Name

# Remove the stale registry key — replace <STALE-GUID> with the value found above
Remove-Item -Path "HKLM:\SOFTWARE\Microsoft\Enrollments\<STALE-GUID>" -Recurse -Force

# Restart MDM services
Restart-Service -Name dmwappushsvc -Force
Restart-Service -Name DeviceManagementService -Force
```

Also remove stale MDM certificates: `certlm.msc → Personal → Certificates` — delete any certificate whose subject or friendly name references the old enrolment GUID.

**Step 5 — Re-trigger Autopilot**

After completing Steps 1–4, perform a full device reset before reattempting Autopilot enrolment (see Section 6 — Permanent Fix). Do not attempt to re-enrol without a reset; residual state may persist.

---

## 6. Permanent Fix

### For the Affected Device

Perform a full **Autopilot Reset** or factory wipe to return the device to a clean OOBE state, then allow Autopilot enrolment to complete normally:

| Method | When to use | Steps |
|---|---|---|
| **Autopilot Reset (preferred)** | Device is Intune-reachable | Intune → device → **Autopilot Reset** — initiates a platform-managed reset that clears MDM state, certificates, and DMCLIENT artefacts cleanly |
| **Local wipe** | Device is not reachable via Intune | Settings → System → Recovery → **Reset this PC → Remove everything** |

Before initiating the reset, confirm the device's Autopilot hardware hash is registered:
```
Intune → Devices → Enrol devices → Windows enrolment → Devices (Autopilot)
```
If the hash is absent, re-capture and upload it before the reset, or the device will not receive its Autopilot profile at OOBE.

### For Future Devices (Process Fix)

Update the device repurposing SOP to enforce the following mandatory pre-reassignment checklist before any device is added to an Autopilot deployment group:

1. Disconnect MDM enrolment on device (`Settings → Accounts → Access work or school → Disconnect`).
2. Delete Intune device object.
3. Delete AAD device object.
4. Confirm Autopilot hardware hash is registered.
5. Perform Autopilot Reset or full wipe.
6. Document completion in the device repurposing ticket before marking the task closed.

---

## 7. Verification

An engineer confirms resolution by validating all of the following after Autopilot completes:

| Check | Location | Expected Result |
|---|---|---|
| Enrolment state | Intune → Devices → All devices → [device] → **Device enrolment** | State: **Enrolled** |
| Profiles applied | Intune → Devices → All devices → [device] → **Device configuration** | All expected profiles show **Succeeded** |
| Compliance state | Intune → Devices → All devices → [device] → **Device compliance** | **Compliant** or **In grace period** (within 7-day window) |
| No stale device record | Intune → Devices → All devices | Only one device record for this hardware hash/serial — no legacy 2023 duplicate |
| No legacy MDM entry on device | `Settings → Accounts → Access work or school` | Only the current Intune/Autopilot account entry visible |
| HAS sync (BitLocker/Secure Boot) | Intune → device → **Hardware** tab → HAS report timestamp | Timestamp current; not absent or stale |
| Error codes absent | MDM diagnostic export or Event Viewer → DeviceManagement-Enterprise-Diagnostics-Provider | No `0x80180014` or `0x80070005` entries post-enrolment |

> **Note:** Allow up to 24 hours for the Health Attestation Service (HAS) report to sync after enrolment. BitLocker and Secure Boot compliance may show *In grace period* during this window — this is expected behaviour under the DWP 7-day grace period policy.

---

## 8. How to Identify Next Time

If a future Autopilot enrolment failure is reported, check for this known error first by confirming **all three of the following**:

1. **Error code is `0x80180014`** — visible in the MDM diagnostic export `ErrorCode` field or Intune device enrolment view.
2. **`MDMEnrolled: Yes`** with an enrolment date **predating** the current Autopilot attempt — visible in the MDM diagnostic export.
3. **`ProfilesApplied: 0 of N`** with `LastError: 0x80070005` — confirms the enrolment block caused the profile failure, not an independent permissions fault.

If all three are present, this is this known error. Proceed directly to Section 5 (Workaround) and Section 6 (Permanent Fix) without further investigation.

If only `0x80070005` is present without `0x80180014`, investigate independently — that combination indicates a different root cause (e.g. RBAC permissions, device object conflict, or certificate store issue unrelated to a stale enrolment).

---

## 9. Related Documents

| Document | Reference | Location |
|---|---|---|
| Root Cause Analysis | RCA-2026-08-11-AUTOPILOT-001 | Day 6/INC-Autopilot-EnrolmentFailure-0x80180014-RCA.md |
| Incident Analysis | INC-Autopilot-EnrolmentFailure-0x80180014 | Day 6/INC-Autopilot-EnrolmentFailure-0x80180014-Analysis.md |
| DWP Windows 11 Intune Compliance Policy | Security Baseline Translation | Day 6/DWP-Win11-Intune-Compliance-Policy.md |
| Microsoft Autopilot Troubleshooting Guide | External | [https://learn.microsoft.com/en-us/autopilot/troubleshooting](https://learn.microsoft.com/en-us/autopilot/troubleshooting) |
| Intune MDM Enrolment Error Reference | External | [https://learn.microsoft.com/en-us/intune/enrollment/troubleshoot-windows-enrollment-errors](https://learn.microsoft.com/en-us/intune/enrollment/troubleshoot-windows-enrollment-errors) |

---

*Known Error Record prepared by Nikita, DWP Endpoint Engineering — 07/08/2026. Review due 07/09/2026.*
