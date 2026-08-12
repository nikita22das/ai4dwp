# DEX Startup Performance Drop: Most Likely Causes (Ranked)
Date: 2026-08-12
Scope basis: Finance-Win11 only (215 devices) degraded immediately after 2026-08-04 02:00 config deployment; IT-Win11 (40 devices) not targeted by change stayed stable.

## 1) Added startup compliance logging script increased logon path time
Why this fits the evidence:
- Timing aligns exactly: degradation starts on 2026-08-04, immediately after the profile introducing the startup script.
- Scope aligns cleanly: only Finance-Win11 received the change and only that group regressed.
- Pattern aligns: startup time jumped from ~17-18s baseline to ~41-44s and then stayed elevated, consistent with deterministic work added at each startup.

Fastest check to confirm or eliminate:
- On 3-5 affected Finance devices, measure script runtime from startup/logon logs and compare startup traces before/after 2026-08-04.
- Temporarily exclude a small pilot subset from the script assignment and check whether their median startup returns toward baseline within 24 hours.

## 2) New Defender scan policy introduced heavy startup-time scan activity
Why this fits the evidence:
- Timing matches the same 2026-08-04 profile deployment that included additional Defender policy.
- Clean control evidence: IT-Win11 had no such policy change and did not show the startup-time increase.
- Sustained impact pattern (multiple days) matches recurring scan behavior at boot/logon rather than a one-off event.

Fastest check to confirm or eliminate:
- Pull Defender operational telemetry for affected devices at boot/logon windows and quantify CPU/disk impact from scan-related processes.
- Temporarily relax only the new startup-adjacent scan setting for a limited pilot and compare next-day startup medians against still-targeted devices.

## 3) Combined profile processing overhead (script + security policy) delayed user-ready desktop
Why this fits the evidence:
- Evidence supports a profile-level effect starting exactly when the new baseline was applied.
- The unaffected group acts as a clean comparator, reducing likelihood of platform-wide external causes.
- The magnitude and persistence suggest additive overhead in the startup chain, not random variance.

Fastest check to confirm or eliminate:
- Run an A/B pilot inside Finance-Win11: one subset with full new profile, one subset with startup script and new scan policy removed, then compare 24-hour startup medians.
- Correlate profile processing timestamps against user-ready desktop timestamps to quantify added delay segment-by-segment.
