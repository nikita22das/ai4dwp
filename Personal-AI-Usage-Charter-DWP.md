# Personal AI Usage Charter (DWP Engineer, Public AI Assistants)

## Purpose
I use public AI assistants to improve speed and quality in desktop and endpoint engineering work, while protecting DWP people, systems, and data.

This charter defines what I will and will not use public AI for, and how I will verify AI outputs before any change.

## Scope
This applies to my day-to-day endpoint work, including Windows desktop support, device build and configuration, software packaging, scripting, troubleshooting, documentation, and user guidance.

## 1) Appropriate DWP Tasks for Public AI Help
I may use public AI for low-risk, non-sensitive engineering support where no protected information is shared.

1. Drafting and improving technical writing:
- Runbooks, SOPs, change summaries, known issue notes, and user-facing guidance.
- Rewriting for clarity, readability, and consistency.

2. Generic scripting support:
- Creating script templates in PowerShell, CMD, Bash, or Python using dummy values.
- Explaining command syntax, parameters, and likely side effects.
- Refactoring scripts for readability and error handling.

3. Troubleshooting patterns:
- Asking for likely causes of generic endpoint issues (for example, profile corruption, policy conflicts, patch failures).
- Building structured diagnostic checklists and decision trees.

4. Automation design (high-level):
- Comparing approaches for software deployment, patch orchestration, or configuration drift checks.
- Producing test plans and rollback plans.

5. Learning and validation support:
- Explaining Microsoft, Intune, Entra, Group Policy, SCCM/MECM, and endpoint concepts at a general level.
- Generating sample monitoring queries with placeholder fields.

Rule: prompts must be abstracted, sanitized, and free of real DWP identifiers or user data.

## 2) Tasks Not Appropriate for Public AI
I will not use public AI for activities that expose sensitive information, create uncontrolled operational risk, or require trusted internal context.

1. Any prompt containing sensitive or internal data:
- End-user personal data, case details, claimant information, staff records.
- Device names, hostnames, serials, IP ranges, tenant details, internal URLs, ticket content, or internal architecture specifics.
- Security incident details, vulnerabilities, exploit paths, or detection logic not already public.

2. Credentials and secrets:
- Passwords, MFA codes, API keys, certificates, tokens, private keys, recovery codes, or connection strings.

3. Production decision delegation:
- Letting AI decide change windows, security exceptions, or policy settings without human review.
- Accepting AI-generated registry, policy, firewall, or hardening changes directly into production.

4. Regulated or sensitive operational outputs:
- Drafting or validating approvals that require internal governance evidence.
- Producing content that could be interpreted as official DWP policy without internal review.

## 3) Data-Handling Rule (PII and Credentials)
I will follow a strict zero-secrets, zero-PII rule with public AI.

1. Never paste:
- Any end-user PII.
- Any credentials, tokens, keys, or authentication material.
- Any raw logs that may include usernames, machine identifiers, email addresses, or network details.

2. Always sanitize before prompting:
- Replace names with Person-A, Person-B.
- Replace device and tenant identifiers with generic placeholders.
- Remove timestamps, IDs, paths, and metadata that can re-identify users or systems.

3. If unsure, do not share:
- Treat uncertain data as sensitive by default.
- Move the task to approved internal tools or complete manually.

## 4) Personal Generate-Then-Verify Rule (Scripts and System Changes)
AI can generate; only I can approve. No AI output is trusted by default.

1. Generate
- Ask AI for draft scripts or change plans using placeholders and least-privilege assumptions.
- Request explicit pre-checks, logging, and rollback steps.

2. Review
- Read every line before execution.
- Check for destructive commands, privilege escalation, hidden downloads, external calls, and weak error handling.
- Confirm compatibility with DWP standards and endpoint baselines.

3. Test
- Run first in a non-production or isolated test context.
- Validate expected output, failure behavior, and rollback.
- Capture evidence: what was run, where, when, and result.

4. Approve and deploy
- Apply change control and peer review where required.
- Execute in production only after successful test and explicit human sign-off.

5. Post-change verification
- Confirm endpoint health, security posture, and user impact.
- Record lessons learned and update runbooks.

## Personal Commitment
I use public AI as a drafting assistant, not an authority.

I remain accountable for data protection, technical correctness, security impact, and operational outcomes of every script, recommendation, and change I implement.
