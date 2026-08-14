# DWP macOS Security Baseline - JAMF Configuration Translation

**Author:** DWP Endpoint Engineer  
**Date:** 2026-08-13  
**Policy Scope:** macOS - Design Team Fleet (25 managed devices)  
**Deployment Model:** Pilot-first (5 devices), then full ring (25 devices)

---

## Verification Discipline (Day 6 Intune Standard Applied)

JAMF Pro UI labels, payload containers, and option names can change between JAMF versions and Apple payload schema revisions.  
Where this document says **Verify label in JAMF**, validate the exact control name and path in your own JAMF tenant before production rollout.

Do not trust exact label text from this document as authoritative when your tenant shows different naming.

---

## Requirement 1 - FileVault Disk Encryption Must Be Enabled

| Field | Detail |
|---|---|
| **Payload type** | Security & Privacy -> FileVault (**Verify label in JAMF**) |
| **Value** | FileVault = On (enforced), escrow personal recovery key to JAMF, use institutional recovery key if required by DWP standard |
| **Scope note** | Apply to all 25 Design devices; do not exclude laptops used for external travel |

**Effect:**  
Enforces full-disk encryption at rest so local data is unreadable without valid credentials or recovery key material.

**False-positive risk:**  
- Encryption is enabled but still progressing, so compliance check runs before completion.  
- User deferral window is still active and encryption has not started.  
- Recovery key escrow succeeded locally but has not yet checked into JAMF inventory.  
- Device recently enrolled and has stale inventory state.

**Recommendation:**  
Set inventory update cadence to ensure key escrow and encryption state update quickly after enablement. Use a temporary grace workflow for first-time enrollments.

**Validation steps:**
1. Confirm profile is installed on target device.
2. Validate FileVault state on endpoint is On.
3. Confirm recovery key escrow record appears in JAMF.
4. Re-run inventory update and confirm Smart Group compliance reflects final state.

---

## Requirement 2 - Gatekeeper Must Be Enabled (Identified Developers Only)

| Field | Detail |
|---|---|
| **Payload type** | Restrictions or Security & Privacy -> Gatekeeper (JAMF-version dependent, **Verify label in JAMF**) |
| **Value** | Allow apps from App Store and identified developers only; do not allow unsigned/unidentified apps |
| **Scope note** | Include all Design devices, including shared lab Macs |

**Effect:**  
Prevents execution of unsigned or untrusted binaries and reduces malware risk from ad-hoc downloads.

**False-positive risk:**  
- Internal creative tooling may be signed incorrectly or not notarized yet.  
- New versions of legitimate apps can trigger first-run prompts before trust chain is evaluated.  
- Local troubleshooting scripts may be flagged as noncompliant behavior even when device health is otherwise good.

**Recommendation:**  
Implement a temporary exception workflow for approved business tools while vendors complete proper notarization/signing.

**Validation steps:**
1. Confirm Gatekeeper policy applies to the device.
2. Test a known notarized app launch (should succeed).
3. Test an unsigned sample binary (should be blocked).
4. Confirm Smart Group or compliance query marks endpoint as expected.

---

## Requirement 3 - Minimum macOS Version Must Be Current Stable Minus One Point Release

| Field | Detail |
|---|---|
| **Payload type** | Software Update payload plus Smart Group compliance criteria for OS version (**Verify label in JAMF**) |
| **Value** | Minimum OS version = N-1 relative to current stable release maintained by DWP monthly patch governance |
| **Example logic** | If current approved stable is N, enforce macOS version >= N-1 |

**Effect:**  
Flags or restricts devices below the approved floor, keeping the fleet within a supportable and patched baseline.

**False-positive risk:**  
- Devices in planned staged update windows may be temporarily below target.  
- Apple update catalog propagation delays may postpone visibility of new point releases.  
- Smart Group comparator errors (string vs numeric interpretation) can misclassify healthy devices.

**Recommendation:**  
Review and update the minimum-version value monthly. Tie rollout windows to Design production schedules to reduce disruption.

**Validation steps:**
1. Record current stable release N in change ticket.
2. Set compliance floor to N-1.
3. Validate Smart Group includes a known out-of-date test device and excludes compliant devices.
4. Re-check after update ring completion.

---

## Requirement 4 - Firewall Must Be Enabled

| Field | Detail |
|---|---|
| **Payload type** | Security & Privacy -> Firewall (**Verify label in JAMF**) |
| **Value** | Firewall = On; optional hardening: stealth mode enabled and stricter inbound controls per DWP risk acceptance |
| **Scope note** | Apply to all Design endpoints, including devices used on public networks |

**Effect:**  
Reduces endpoint exposure to unsolicited inbound traffic and common lateral movement vectors.

**False-positive risk:**  
- Short-lived status drift during reboot or early login state transitions.  
- Third-party endpoint/network agents can alter observed firewall state reporting.  
- Inventory not refreshed after policy change can show outdated posture.

**Recommendation:**  
Pair firewall policy with routine inventory refresh and exception tracking for devices that run approved alternative network security stacks.

**Validation steps:**
1. Verify firewall payload installation.
2. Confirm firewall state is enabled on endpoint.
3. Validate inbound test behavior aligns with policy intent.
4. Confirm compliance reporting after inventory update.

---

## Requirement 5 - Login Password Required After Sleep/Screen Saver

| Field | Detail |
|---|---|
| **Payload type** | Security & Privacy controls for password-after-sleep/screen saver, with possible Login Window/Restrictions dependency (**Verify label in JAMF**) |
| **Value** | Require password immediately after sleep or screen saver begins (grace period = 0, or approved minimum where business-justified) |
| **Scope note** | Mandatory for all user-assigned Design devices |

**Effect:**  
Prevents walk-up access when devices are unattended, lowering risk of unauthorized local or cached-session access.

**False-positive risk:**  
- Profile applied but user session has not yet consumed all security preferences.  
- Compliance checked before first sleep/screensaver event post-enrollment.  
- Manual checks that do not reproduce true sleep/screensaver behavior can produce inconsistent results.

**Recommendation:**  
Validate after forced sleep and wake test. Document approved grace exceptions only for specialist kiosk-style devices (if any exist in Design labs).

**Validation steps:**
1. Confirm payload assignment and installation.
2. Trigger screen lock via screen saver and via sleep.
3. Wake device and confirm immediate credential prompt.
4. Confirm compliance status update in JAMF inventory.

---

## Requirement 6 - Automatic Security Updates Must Be Enabled

| Field | Detail |
|---|---|
| **Payload type** | Software Update (**Verify label in JAMF**) |
| **Value** | Enable automatic checking, downloading, and installation of security updates and critical system data files |
| **Scheduling note** | Stage installation timing outside core Design production windows |

**Effect:**  
Improves patch velocity and shrinks vulnerability exposure windows by reducing user dependency for update actions.

**False-positive risk:**  
- Device offline during scheduled update windows.  
- User deferral rules are active and compliant device appears delayed.  
- Inventory lag after successful background installation and reboot pending state.

**Recommendation:**  
Combine update automation with restart communications and clear maintenance windows to avoid missed patch cycles.

**Validation steps:**
1. Confirm update payload is deployed.
2. Verify automatic update settings on endpoint.
3. Track one patch cycle and confirm device receives applicable security updates.
4. Confirm compliance state after reboot and inventory submission.

---

## Operational Rollout Plan (25 Devices)

1. Pilot ring: 5 devices for 3 to 5 business days.
2. Validate all six controls and collect false-positive patterns.
3. Full ring: remaining 20 devices after pilot sign-off.
4. Run post-deployment audit at day 7 and day 30.

## Monitoring and Triage Model

1. Separate profile assignment from compliance Smart Group logic to simplify troubleshooting.
2. Require inventory refresh before opening compliance incidents.
3. Track every exception with owner, reason, and expiry date.
4. Escalate repeated false positives to JAMF schema/path verification task.

## Summary Table

| # | Requirement | Payload type | Value | Primary false-positive pattern |
|---|---|---|---|---|
| 1 | FileVault enabled | Security & Privacy -> FileVault | Enforce On + key escrow | Encryption/key escrow state lag |
| 2 | Gatekeeper enabled | Restrictions or Security & Privacy -> Gatekeeper | App Store + identified developers only | Legitimate but unsigned/notarization-gap tools |
| 3 | Minimum macOS N-1 | Software Update + Smart Group criteria | Version >= N-1 | Staged rollout and comparator logic errors |
| 4 | Firewall enabled | Security & Privacy -> Firewall | Firewall On | Startup/reporting drift and third-party tooling |
| 5 | Password after sleep/screensaver | Security & Privacy (+ possible Login Window dependency) | Immediate password required | Session timing and test-method inconsistency |
| 6 | Automatic security updates | Software Update | Auto check/download/install enabled | Offline/deferral/reporting lag |

---

## Settings Flagged for Potential JAMF UI Path Changes

| Setting | Risk level | Why verification is required |
|---|---|---|
| FileVault payload naming | Medium | Container naming differs by JAMF version and Apple payload updates |
| Gatekeeper payload location | High | Frequently appears under different payload categories |
| OS version compliance path | High | Often implemented through combined profile + Smart Group logic |
| Firewall label text | Medium | Option text and sub-options can shift between UI revisions |
| Password-after-sleep controls | High | May split across Security & Privacy, Restrictions, or Login Window areas |
| Software update automation labels | Medium | Automatic update wording varies by macOS generation and JAMF release |

**Required action before production:**  
Walk each control in your own JAMF tenant and verify payload name, setting label, and enforceable value.  
If your UI differs, trust the tenant UI and payload behavior, not exact wording in this document.

---

*Document prepared by DWP Endpoint Engineering - verify in-tenant labels before production deployment.*
