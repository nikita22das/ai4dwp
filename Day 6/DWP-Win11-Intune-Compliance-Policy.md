# DWP Windows 11 – Intune Compliance Policy: Security Baseline Translation

**Author:** DWP Endpoint Engineer  
**Date:** 2026-08-10  
**Policy Scope:** Windows 11 – Managed Devices (Intune MDM enrolled)  
**Grace Period:** 7 days applied to all settings  

---

## How to Apply the Grace Period

In Intune, grace periods are set at the **compliance policy level**, not per setting.  
**Path:** Intune admin center → Devices → Compliance policies → [Policy] → Properties → **Actions for noncompliance**  
Set the "Mark device noncompliant" action to **7 days** after noncompliance is detected.

---

## Requirement 1 – BitLocker Must Be Enabled on the OS Drive

| Field | Detail |
|---|---|
| **Setting Name** | Require BitLocker |
| **Value** | Require |
| **Intune UI Path** | Devices → Compliance policies → [Policy] → **Device Health** → BitLocker → **Require** |

**Effect:**  
Intune queries the Windows Health Attestation Service (HAS) to confirm the OS drive is protected by BitLocker. A device reports non-compliant if the OS volume is unencrypted or encryption is suspended.

**False-Positive Risk:**  
- BitLocker is enabled but the **Health Attestation report has not yet synced** (common on newly enrolled or recently reimaged devices — can take up to 24 hours).  
- BitLocker encryption is **in progress** (encrypting) at the time of compliance evaluation.  
- Devices where BitLocker was enabled via SCCM/co-management but HAS reporting is not yet configured.  
- Virtual machines (e.g. AVD session hosts) — HAS may not report BitLocker correctly on some hypervisors.

**Recommendation:**  
Pair this with a **BitLocker configuration profile** (Endpoint Security → Disk Encryption) to silently enforce BitLocker before compliance is evaluated. The 7-day grace period absorbs the HAS sync delay on new enrolments.

**Validation Steps — After Policy Sync:**

*Where to check compliance status:*  
- **From the device:** Intune admin center → Devices → All devices → [device] → **Device compliance** → select this policy → per-setting results are listed individually.  
- **From the policy:** Devices → Compliance policies → [this policy] → **Device status** → [device] → same per-setting view.

*Compliance state and Conditional Access impact:*

| State | Meaning | Conditional Access effect |
|---|---|---|
| **Compliant** | All settings met; HAS confirmed device health | Access to CA-protected resources is permitted |
| **Not compliant** | One or more settings not met AND grace period has expired | Access blocked; user sees "Device is not compliant" error |
| **In grace period** | Setting(s) not met but within the 7-day grace window | Access still permitted; grace clock starts at first non-compliance detection, not enrolment |

*If the device shows non-compliant on BitLocker despite BitLocker being enabled:*

| Cause | Why it happens | Fastest check |
|---|---|---|
| **HAS report not yet synced** | Health Attestation Service report has not been submitted or processed — common on newly enrolled or upgraded devices (up to 24 h delay) | Intune → device → **Hardware** tab → check HAS report timestamp. If absent or stale, trigger a manual sync: Intune → device → **Sync** and wait up to 24 hours |
| **Encryption still in progress** | Intune/HAS will not confirm BitLocker until the volume is 100% encrypted, not just encryption-started | On the device run `manage-bde -status C:` — if **Percentage Encrypted** is below 100% or status shows *Encryption In Progress*, wait for completion before re-evaluating |
| **BitLocker enforced via SCCM, not Intune** | Legacy SCCM-managed BitLocker does not configure the device to report encryption state to HAS; Intune receives no confirmation | Intune → Devices → Monitor → **Encryption report** — if device shows *Not ready* or *Profile state: Error* while `manage-bde` confirms encryption, HAS pipeline is broken. Fix: deploy a BitLocker configuration profile via Intune (Endpoint security → Disk Encryption) to take ownership and establish HAS reporting |

---

## Requirement 2 – Secure Boot Must Be Enabled

| Field | Detail |
|---|---|
| **Setting Name** | Require Secure Boot to be enabled on the device |
| **Value** | Require |
| **Intune UI Path** | Devices → Compliance policies → [Policy] → **Device Health** → Secure Boot → **Require** |

**Effect:**  
Enforces that UEFI Secure Boot is active. Prevents bootkit and rootkit malware from loading before the OS. Reported via the Windows Health Attestation Service.

**False-Positive Risk:**  
- Older hardware (pre-2012) that does not support Secure Boot at all.  
- Devices dual-booting Linux — Secure Boot may be disabled or unsigned kernel modules in use.  
- Some older Dell/HP devices where Secure Boot is present but BIOS reporting to HAS is unreliable.  
- VMware Workstation VMs without vTPM configured.

**Recommendation:**  
Exclude known legacy hardware groups via an AAD dynamic device group scoped to hardware model. If dual-boot devices are in scope, raise a separate exception request — Secure Boot should not be weakened for them.

> ⚠️ **UI Path Note:** As of mid-2024 Microsoft began migrating compliance policies into the **"New compliance policy experience"** under Devices → Compliance. The Secure Boot setting remains under Device Health in both the legacy and new UI, but the navigation steps may differ slightly if your tenant has been updated to the new experience. Verify the current path in your tenant.

---

## Requirement 3 – Minimum OS Build (N-1 = 22621.2861)

| Field | Detail |
|---|---|
| **Setting Name** | Minimum OS version |
| **Value** | `10.0.22621.2861` |
| **Intune UI Path** | Devices → Compliance policies → [Policy] → **Device Properties** → Operating System version → Minimum OS version |

**Effect:**  
Devices running a build older than `10.0.22621.2861` (Windows 11 22H2, KB5034123 approximately) are flagged non-compliant. Ensures a known-patched baseline and excludes devices that missed critical cumulative updates.

**False-Positive Risk:**  
- **Patch Tuesday lag** — devices that have downloaded but not yet installed the latest CU will temporarily fall below the minimum during the patching window (typically the first 2 weeks of the month).  
- Devices on a **Windows Update for Business deferral ring** may legitimately be behind by design.  
- Build string format must be exact: Intune expects `10.0.XXXXX.YYYY` — entering `22621.2861` without the `10.0.` prefix will cause a validation error.

**Recommendation:**  
Align this value with your **slowest WUfB deferral ring** (e.g. if your pilot ring defers 14 days, set the minimum to the build that was current 14+ days ago). Review and update this value monthly after Patch Tuesday. The N-1 strategy (`22621.2861`) already provides one release of tolerance.

---

## Requirement 4 – Windows Defender Real-Time Protection Must Be On

| Field | Detail |
|---|---|
| **Setting Name** | Require real-time protection |
| **Value** | Require |
| **Intune UI Path** | Devices → Compliance policies → [Policy] → **System Security** → Windows Defender Antimalware → Real-time protection → **Require** |

**Effect:**  
Confirms that Microsoft Defender Antivirus real-time protection (the resident shield) is active. Devices with RTP disabled or tampered are marked non-compliant.

**False-Positive Risk:**  
- **Third-party AV** (e.g. CrowdStrike Falcon, Symantec) registered as the primary AV in Windows Security Center causes Defender to enter **passive mode**, which may be reported as RTP off.  
- Tamper protection temporarily reporting a stale state immediately after a Defender engine update.  
- Microsoft Defender for Endpoint (MDE) onboarded devices — if MDE is the primary sensor and Defender is in EDR block mode, RTP reporting can vary.

**Recommendation:**  
If a third-party EDR (e.g. CrowdStrike) is deployed organisation-wide, confirm whether it registers itself correctly with Windows Security Center. If Defender is intentionally passive, use the **MDE risk score** compliance connector instead of the Defender RTP setting to avoid systematic false positives.

> ⚠️ **UI Path Note:** In the newer Intune compliance policy UI the Windows Defender settings may appear under **"Microsoft Defender Antivirus"** rather than "Windows Defender Antimalware". The underlying CSP is the same.

---

## Requirement 5 – Firewall Must Be Enabled for All Profiles

| Field | Detail |
|---|---|
| **Setting Name** | Microsoft Defender Firewall – Domain / Private / Public |
| **Value** | Require (all three profiles) |
| **Intune UI Path** | Devices → Compliance policies → [Policy] → **System Security** → Windows Firewall → Domain Networks / Private Networks / Public Networks → **Require** |

**Effect:**  
Enforces that Windows Firewall is active on all three network profiles (Domain, Private, Public). A device is non-compliant if any single profile has the firewall disabled.

**False-Positive Risk:**  
- Third-party firewall products (e.g. Cisco AnyConnect host firewall, Symantec Endpoint Protection firewall) can **replace** the Windows Firewall service; Windows may then report WF as off even though the device is protected.  
- Group Policy from on-prem GPO that **disables** Windows Firewall on domain-joined devices (a legacy practice sometimes used for "trusted" corporate networks).  
- VPN software that temporarily disables the public profile firewall during connection establishment.

**Recommendation:**  
Audit legacy GPOs for any `Computer Configuration → Windows Settings → Security Settings → Windows Firewall` policies that disable profiles. Remove these or migrate to Intune Firewall profiles. If a third-party firewall is in use, raise an exception and use that product's compliance API if available.

---

## Requirement 6 – A PIN or Password Must Be Configured

| Field | Detail |
|---|---|
| **Setting Name** | Require a password to unlock mobile devices |
| **Value** | Require |
| **Supporting Settings** | Minimum password length: 6 (recommended) / Password type: At least numeric (PIN) or Alphanumeric |
| **Intune UI Path** | Devices → Compliance policies → [Policy] → **System Security** → Password → Require a password to unlock mobile devices → **Require** |

**Effect:**  
Enforces that the device has a local logon credential (PIN, password, or Windows Hello PIN) configured. Prevents unattended access to unlocked devices.

**False-Positive Risk:**  
- **Kiosk / shared devices** configured with auto-logon (no interactive password) — these will always be non-compliant under this setting.  
- **Windows Hello for Business** provisioning in progress — the device may not yet have a PIN registered at first enrolment.  
- Service accounts or break-glass accounts configured with no password (should not exist on compliant endpoints).

**Recommendation:**  
Exclude kiosk and shared-device groups from this compliance policy and apply a separate, dedicated kiosk compliance profile. For WHfB rollouts, the 7-day grace period covers the provisioning window.

> ⚠️ **UI Path Note:** For Windows 10/11 PCs managed as "PC" (not mobile), the password compliance settings appear under **System Security** rather than "Device Security" — the label has changed between Intune UI versions. The CSP path (`./Vendor/MSFT/PolicyManager/My/DeviceLock/...`) is consistent regardless of UI label changes.

---

## Requirement 7 – Device Integrity Must Not Be Compromised

> **Note:** The terms "jailbroken" and "rooted" are mobile platform concepts (iOS and Android respectively) and do not apply to Windows. On Windows 11, the equivalent control is enforcement of **device integrity** — detecting tampered security controls, suspicious boot-chain activity, or active threat presence — via the mechanisms below.

| Field | Detail |
|---|---|
| **Setting Name** | Require the device to be at or under the machine risk score |
| **Value** | Low |
| **Intune UI Path (MDE integrated)** | Devices → Compliance policies → [Policy] → **Microsoft Defender for Endpoint** → Require the device to be at or under the machine risk score → **Low** |
| **Intune UI Path (basic)** | Devices → Compliance policies → [Policy] → **Device Health** → Code integrity → **Require** |

**Effect:**  
Windows 11 device integrity is enforced via two mechanisms:  
- **MDE risk score:** Flags devices where Defender for Endpoint has detected active threats, tampered security controls, or suspicious boot-chain activity. Setting this to **Low** ensures only clean, uncompromised devices are compliant.  
- **Code Integrity (Device Health):** Validates via the Windows Health Attestation Service that kernel-level code integrity (HVCI / Windows Defender Credential Guard) is active and that the boot chain has not been tampered with. This is the closest Windows-native equivalent to the integrity checks performed on mobile platforms.

**False-Positive Risk:**  
- Penetration testing tools (e.g. Metasploit, Sysinternals with unsigned drivers) present on developer or security-team machines may trigger MDE risk elevation.  
- Unsigned kernel drivers (older hardware drivers not yet WHQL-signed) can cause Code Integrity attestation failures.  
- MDE onboarding latency — newly enrolled devices may show an elevated risk score until the first full MDE scan completes.

**Recommendation:**  
Use the **MDE risk score connector** (set to "Low") rather than relying solely on the basic "Rooted devices" toggle, which has limited Windows-specific detection. Exclude security and dev teams via a scoped AAD group with a separate policy permitting "Medium" risk score where justified and documented.

> ⚠️ **UI Path Note:** The MDE risk score compliance integration requires the **Microsoft Defender for Endpoint connector** to be active in Intune (Tenant Administration → Connectors and tokens → Microsoft Defender for Endpoint). If MDE is not licensed or connected, this setting will not appear. This integration path has been updated multiple times; verify connector status in your tenant before relying on this control.

---

## Summary Table

| # | Requirement | Setting Name | Value | Grace Period |
|---|---|---|---|---|
| 1 | BitLocker on OS drive | Require BitLocker | Require | 7 days |
| 2 | Secure Boot enabled | Require Secure Boot | Require | 7 days |
| 3 | Minimum OS build (N-1) | Minimum OS version | `10.0.22621.2861` | 7 days |
| 4 | Defender real-time protection | Require real-time protection | Require | 7 days |
| 5 | Firewall – all profiles | Windows Firewall (Domain/Private/Public) | Require | 7 days |
| 6 | PIN or password configured | Require password to unlock | Require | 7 days |
| 7 | Device integrity not compromised | MDE Machine Risk Score | Low | 7 days |

---

## Settings Flagged for Potential UI Path Changes

| Setting | Risk Level | Note |
|---|---|---|
| Secure Boot | Medium | New compliance policy experience may reorganise Device Health section |
| Defender RTP | Medium | Label may show "Microsoft Defender Antivirus" vs "Windows Defender Antimalware" |
| Password / PIN | Medium | Label differs between PC and mobile policy views; underlying CSP unchanged |
| Device Integrity / MDE Risk Score | High | Requires active MDE connector; UI path changes with connector version and licensing |

**Recommended action:** Before deploying, walk through each setting in your tenant's Intune admin center at [https://intune.microsoft.com](https://intune.microsoft.com) and confirm the current label and path matches the above. Microsoft updates the Intune UI frequently; the CSP values are stable but the UI navigation can shift between releases.

---

*Document prepared by DWP Endpoint Engineering — review before production deployment.*
