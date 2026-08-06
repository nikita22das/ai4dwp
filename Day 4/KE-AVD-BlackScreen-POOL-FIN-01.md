# Known Error Record - AVD POOL-FIN-01 Black Screen

Symptom : Users on POOL-FIN-01 may see a black screen after sign-in and experience repeated session disconnects. During the incident window, some users recovered after reconnect, while others remained unable to complete sign-in normally.

Cause : A GPU/display driver regression introduced by the overnight POOL-FIN-01 image update caused dwm.exe to crash in Intel module igdumd64.dll during session initialization. DWM termination then led to black screen behavior and disconnect loops.

Scope : Impact was limited to POOL-FIN-01 during the incident and affected approximately 40% of users based on host assignment. POOL-FIN-02 remained unaffected in the same period.

Workaround : Immediately route users away from symptomatic POOL-FIN-01 hosts and drain active sessions from those hosts. Restore service by moving affected hosts to the known-good image/driver baseline and restarting them.

Permanent fix: Revert affected hosts to the known-good image/driver state and keep the validated display driver pinned in the production image baseline. Prevent recurrence by blocking unvalidated driver drift and using staged rollout gates tied to crash telemetry.

How to spot it: On affected hosts, look for Event 21 (logon succeeded) followed by Application Error Event 1000 showing faulting application dwm.exe and faulting module igdumd64.dll with exception 0xc0000005, then Event 40 disconnect and Event 9009 DWM exit (0x40010004). On unaffected comparison hosts, Event 9011 shows DWM started successfully and there are no corresponding Event 1000 entries in the same window.
