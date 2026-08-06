# Triage Note: T-1006

Summary (one line): User reports broad performance degradation ('everything is slow') beginning two days after upgrading to Windows 11.

Impact (who/how many/business urgency):
- Affected user count: 1 confirmed user/device to-verify if broader post-upgrade trend.
- User impact: General slowdown across daily tasks, likely reducing throughput and response times.
- Business urgency: Medium to-verify (can become High if widespread or role-critical workload).

Known facts:
- Ticket ID: T-1006.
- Device OS: Windows 11.
- Timing: Upgrade occurred two days ago.
- Symptom: Non-specific global slowness across activities.
- No single app/failure point identified yet.

Missing information to gather:
- Whether slowness is constant or time-of-day/intermittent.
- Which tasks/apps are most affected (startup, browser, Office, line-of-business apps, file access).
- Device resource behavior at symptom time (CPU, memory, disk, network) to-verify.
- Free disk space and recent update/install activity post-upgrade.
- Presence of background scans/indexing/sync tasks since upgrade.
- Whether issue occurs on battery, AC, docking, or all states.
- Whether other upgraded users/devices show similar symptoms.
- Any peripherals/drivers changed around upgrade window (to-verify).

Likely catagory:
- Endpoint Performance / Windows 11 Post-Upgrade (to-verify against local service taxonomy).

First diagnostic step:
- Narrow the symptom by reproducing a slow task with the user while capturing basic resource utilization snapshot (CPU, memory, disk, network) to identify whether slowdown is compute, storage, network, or app-specific.