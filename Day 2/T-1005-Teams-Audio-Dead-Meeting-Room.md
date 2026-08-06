# Triage Note: T-1005

Summary (one line): Teams audio is non-functional on three machines in the same meeting room, suggesting a shared room-level audio path or configuration issue.

Impact (who/how many/business urgency):
- Affected user count: At least 3 machines in one meeting room; user count varies by meeting occupancy.
- User impact: Participants cannot use audio in Teams meetings from that room.
- Business urgency: High to-verify (meeting disruption and collaboration impact).

Known facts:
- Ticket ID: T-1005.
- Application: Microsoft Teams.
- Symptom: Audio dead/non-functional.
- Scope clue: Three machines in the same room are affected.
- Pattern suggests potential shared environmental dependency.

Missing information to gather:
- Whether issue is input, output, or both.
- Whether failure occurs in Teams only or system-wide audio too.
- Which audio devices are selected in Teams and OS on each machine.
- Whether room docking station, USB audio interface, or display hub is common across all three machines.
- Whether headsets work when connected directly to each machine.
- Recent room hardware or cabling changes (to-verify).
- Whether issue reproduces in test call and at OS sound test level.
- Whether this affects only one meeting room or multiple rooms.

Likely catagory:
- Collaboration / Teams / Meeting Room Audio (to-verify against local service taxonomy).

First diagnostic step:
- Run a controlled isolation check in the room: test one affected machine with a known-good headset directly connected (bypassing shared room peripherals) to determine if the fault is endpoint-local or shared room hardware/path.