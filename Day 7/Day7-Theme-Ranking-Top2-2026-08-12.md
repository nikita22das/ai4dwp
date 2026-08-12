# FinBridge Win11 Post-Migration: Top 2 Themes to Act On Today
Date: 2026-08-12
Analyst: DWP Analyst

---

## Theme Analysis Summary

| Theme | Count | Severity |
|---|---|---|
| Credentials Vault Inaccessibility | 3 | Blocker |
| Admin Console Lockouts | 2 | Blocker |
| Test VM Access Loss | 2 | Blocker |
| Minor UI and Cosmetic Changes | 3 | Minor |
| Performance and Responsiveness | 1 | Minor |
| Positive Feedback | 4 | Positive |

---

## Ranking Methodology

- **Primary weight:** Severity — Blocker > Friction > Minor > Positive. All Blocker themes outrank all Minor and Positive themes regardless of count.
- **Secondary weight:** Volume within the same severity band.
- **Tertiary weight:** Urgency signals in comment language — duration of issue, team-wide spread, escalation to management.

---

## Initial Ranking Note (Volume-Weighted — Corrected)

A volume-first approach would have surfaced Minor UI and Cosmetic Changes (Count 3) alongside Credentials Vault Inaccessibility as joint top themes due to equal count. This is incorrect because a cosmetic display issue does not carry the same operational risk as a full access outage. Severity must be applied as the primary filter before volume is considered.

---

## Corrected Ranking (Severity-First)

### #1 — Credentials Vault Inaccessibility
**Count:** 3 | **Severity:** Blocker

**Why it ranks #1:**
- All three comments describe a complete access outage affecting a whole team, not individual users.
- The issue has persisted for at least three consecutive days, indicating no spontaneous recovery.
- One user has already escalated to their manager, signalling this is entering formal incident territory.
- Duration, team-wide scope, and active escalation elevate it above the other Blocker themes.

**Manager update sentence:**
"Credentials vault inaccessibility is our highest priority today because it has been blocking an entire team for three days and is already escalating to management, making it an active service continuity risk requiring immediate incident response."

---

### #2 — Admin Console Lockouts
**Count:** 2 | **Severity:** Blocker

**Why it ranks #2:**
- Two comments confirm a lockout pattern that has escalated from one individual engineer to the whole team within a single week.
- The active spread pattern distinguishes this from a contained fault — it is growing.
- It ranks above Test VM Access Loss (also Blocker, Count 2) because the language signals systemic expansion rather than a single persistent user fault.

**Manager update sentence:**
"Admin console lockouts are second priority because they are actively spreading across the team, suggesting a systemic access control failure that will generate further reports and operational disruption if not contained today."

---

## Why the Order Changed

The initial volume-weighted instinct treated count as the primary sorting factor. Under that logic, Minor UI Changes (Count 3) would appear alongside Credentials Vault as a tied top theme, and Admin Console Lockouts (Count 2) might have ranked below it.

Once severity is applied first, the ranking resets entirely:

- All three Blocker themes are separated from Minor and Positive themes before count is considered.
- Within the Blocker band, Credentials Vault ranks above Admin Console Lockouts because its comments show greater duration, wider team impact, and a formal escalation signal.
- Minor UI Changes (Count 3) drops out of the top 2 entirely — its count is irrelevant once it is correctly classified as a low-severity cosmetic issue.

The core principle: a small number of Blockers outrank a larger number of Minor issues. Volume is a tiebreaker within a severity band, not a substitute for severity assessment.

---

*Prepared by: DWP Analyst — 2026-08-12*
