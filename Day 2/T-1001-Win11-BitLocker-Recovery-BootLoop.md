# Triage Note: T-1001

Summary (one line): New Windows 11 laptop is prompting for a BitLocker recovery key on every boot, indicating repeated BitLocker protector validation failure.

Impact (who/how many/business urgency):
- Affected user count: 1 confirmed (single new laptop user).
- User impact: User cannot reach normal desktop login flow without recovery-key entry each restart.
- Business urgency: Medium-High to-verify (productivity and onboarding disruption for a new device).

Known facts:
- Ticket ID: T-1001.
- Device type: New Windows 11 laptop.
- Symptom: BitLocker recovery key prompt appears every boot.
- Recurrence: Happens repeatedly, not a one-off event.
- Service context: Endpoint/access issue at boot stage.

Missing information to gather:
- Whether the recovery key entered is accepted every time or sometimes rejected.
- Whether this started immediately from first boot or after updates/firmware/policy changes.
- User identity, device hostname/asset ID, and support group ownership (to-verify and handle per data rules).
- Exact boot path: cold boot, restart, docking state, and external peripherals attached.
- Any recent BIOS/UEFI, TPM, Secure Boot, or boot-order changes (to-verify).
- Whether pre-boot PIN or other startup protectors are configured.
- Network state at boot and whether device has completed domain/MDM enrollment.
- Frequency pattern: every boot vs intermittent.
- Whether other newly issued laptops show same behavior (potential wider incident).

Likely catagory:
- Endpoint Security / BitLocker / Device Encryption (to-verify against local service taxonomy).

First diagnostic step:
- Confirm scope and reproducibility by collecting a short boot history from the user (last successful normal boot, whether recovery prompt occurs on every restart/cold boot, and any hardware/firmware changes), then verify the device recovery-key record exists and matches in the approved key escrow source before deeper endpoint diagnostics.