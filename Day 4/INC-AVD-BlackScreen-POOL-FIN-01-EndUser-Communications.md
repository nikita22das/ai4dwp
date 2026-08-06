# AVD Incident Communications Pack - POOL-FIN-01

## Shared Facts Used in All Versions

- During 07:00-10:00 AM on 2024-03-15, some users on POOL-FIN-01 experienced a black screen and disconnects after sign-in.
- Impact was limited to about 40% of users, based on which host they landed on.
- POOL-FIN-02 was unaffected.
- Root cause was a display driver issue introduced by the overnight POOL-FIN-01 image update.
- Action taken: affected hosts were contained, then moved back to a known-good image/driver state and restarted.
- Verification: by 10:00 AM, users were logging in normally to POOL-FIN-01 and no further issues were reported.
- Access and data remained safe.

---

## Audience 1 - Non-technical Executive

Your team’s access is restored and company data remained safe throughout this incident. Between 07:00 and 10:00 AM on 2024-03-15, some POOL-FIN-01 users saw a black screen and were disconnected after sign-in (about 40% affected); POOL-FIN-02 was not affected. The issue came from an overnight update on POOL-FIN-01, and we fixed it by moving affected systems back to a stable version and restarting them. By 10:00 AM, logins were normal with no new reports. No action is required.

---

## Audience 2 - Affected End-User Team (10 People)

Good news: your access is restored and your data stayed safe. From 07:00 to 10:00 AM on 2024-03-15, some people in POOL-FIN-01 (about 40%) saw a black screen and got disconnected after signing in, while POOL-FIN-02 users were unaffected. This happened because an overnight POOL-FIN-01 update included a display component problem; we fixed it by moving affected systems back to a stable version and restarting them. By 10:00 AM, logins were normal and no new issues were reported. If you see this again, contact the Service Desk immediately and mention POOL-FIN-01 black-screen incident.

---

## Audience 3 - Engineer-to-Engineer Internal Note

Status: Resolved.

Incident facts
- Window: 2024-03-15, 07:00-10:00 local.
- Scope: POOL-FIN-01 only; ~40% user impact depending on host assignment.
- Symptom: post-auth black screen + disconnect loop.
- Control group: POOL-FIN-02 unaffected.

Root cause
- Display driver regression in the updated POOL-FIN-01 image.
- Affected-host evidence chain on SHFIN-01-A:
  - Event 21 (LSM): logon succeeded.
  - Event 1000 (Application Error): dwm.exe faulting igdumd64.dll, exception 0xc0000005.
  - Event 40 (LSM): session disconnected.
  - Event 9009 (DWM): compositor exited.
  - Pattern repeated across reconnect attempts and another user session.
- Unaffected-host comparison on SHFIN-02-A:
  - Event 9011 (DWM started successfully), no Event 1000 in same window.

Exact action taken
- Contained blast radius by restricting session placement away from symptomatic POOL-FIN-01 hosts.
- Drained affected hosts.
- Reverted affected hosts to known-good image/driver baseline.
- Restarted remediated hosts.

Config detail
- Defective state tied to overnight POOL-FIN-01 image update.
- Known-good target state is pre-regression image/driver baseline used by stable hosts.

Verification step
- Post-remediation checks showed no fresh Event 1000 dwm.exe/igdumd64.dll crashes and no Event 9009 reconnect/disconnect chain on remediated hosts.
- Service validation at 10:00 AM: users logging in normally to POOL-FIN-01; no further reports.
- Access and data remained safe.

Preventive action needed
- Pin validated display driver in image baseline.
- Block unvalidated driver drift during image build/deploy.
- Enforce staged rollout with halt criteria on:
  - Event 1000 bursts (dwm.exe + igdumd64.dll), and
  - Event 21 followed by Event 40/9009 correlation.
- Keep last known-good image immediately available for rollback.
- Add pre-prod AVD graphics stability tests (multi-user sign-in/sign-out, reconnect, DWM stability).