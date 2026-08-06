Symptom : User FINBRIDGE\cthompson was unable to complete login from approximately 08:40. Security logs showed repeated failed interactive sign-ins and a locked account state before service was restored.

Cause : Verified root cause was account lockout caused by repeated invalid credential submissions for FINBRIDGE\cthompson. A contributing factor in the same incident was continued wrong-password replay from source IP 10.10.8.112.

Scope : This incident affected FINBRIDGE\cthompson only. The primary observed endpoint in evidence was DESKTOP-FB022, with additional failed Kerberos attempts recorded from 10.10.8.112.

Workaround : Contain repeated bad-auth attempts from active credential sources, then restore account access state. In this incident, account re-enable at 09:08:14 (Event 4722) was followed by successful interactive logon at 09:09:01 (Event 4624).

Permanent fix: Apply the RCA preventive controls: use a lockout-response SOP that checks the 4625/4776/4771/4740 chain first and identifies all credential sources, then enforce stale-credential cleanup on endpoint and secondary sources. Add failed-auth burst alerting with source host/IP correlation and maintain periodic credential-hygiene review for user-credential service/task contexts.

How to spot it: Look for Event 4776 with error 0xC000006A (wrong password), repeated Event 4625 failures (unknown user name or bad password), and Event 4740 account lockout, followed by Event 4625 with reason account locked out. In this incident, Event 4771 failures with code 0x18 from 10.10.8.112 confirmed ongoing wrong-password replay from an additional source.
