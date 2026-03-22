# OSA Snyk Rules

Security-analysis guidance for AI coding agents and local operators working in OSA.

## Purpose

Use Snyk to catch newly introduced security issues in first-party code and security-sensitive configuration. This file exists because OSA task prompts and governance workflows reference a local Snyk policy file.

## When To Run Snyk

Run Snyk after:

- substantive new or edited first-party Swift, SwiftUI, persistence, retrieval, assistant, or networking code
- changes to trusted-source import logic, storage, file handling, ATS behavior, or permissions
- changes that could affect secret handling or data leaving the device
- dependency or manifest changes, when supported dependency manifests exist

## Preferred Commands

Run from the repository root:

```bash
snyk code test --path="$PWD"
```

If a supported dependency manifest is added later, also run the matching dependency scan required by that ecosystem.

## Required Behavior

- Never commit Snyk auth tokens, exported scan logs with secrets, or copied environment credentials.
- Treat findings tied to edited code as blocking until fixed or explicitly reported as residual risk.
- If `snyk` is unavailable or not authenticated, report the blocker plainly and do not claim a clean scan.
- If the scan is skipped because the environment cannot run it, keep the related security claim `unverified`.

## OSA-Specific Focus Areas

Give special attention to:

- hard-coded credentials, endpoints, or unsafe transport exceptions
- remote content ingestion and normalization of untrusted data
- storage of notes, inventory, prompts, or other sensitive user data
- accidental data exfiltration or analytics drift
- unsafe HTML, Markdown, or file-rendering paths for imported content
- permission creep beyond the minimum documented product need

## Reporting Expectations

When Snyk is run, report:

- the exact command
- the date of the scan
- whether the result was clean, blocked, or produced findings
- the file paths or areas affected by any finding tied to the task
