# bug

Plan a bug fix with root cause analysis.

## Variables

description: $ARGUMENTS

## Instructions

1. Read the bug description and gather context.
2. Identify the affected files and modules.
3. Analyze the root cause before proposing a fix.
4. Create the plan in `docs/plans/bug-{name}.md`.

## Bug Plan Format

```markdown
# Bug: {name}

**Created**: {date}
**Status**: draft
**Severity**: critical | high | medium | low

## Description
What the bug is and how it manifests.

## Steps to Reproduce
1. Step 1
2. Step 2
3. Expected: ...
4. Actual: ...

## Root Cause Analysis
Why the bug occurs — trace from symptoms to root cause.

## Solution Approach
The minimal fix that addresses the root cause.

## Relevant Files
- `path/to/file.swift` — why

## Implementation Steps
1. Step with acceptance criterion
2. Step with acceptance criterion

## Regression Prevention
- Test(s) to add that would catch this bug if it recurs

## Acceptance Criteria
- [ ] Bug no longer reproduces
- [ ] Regression test added
- [ ] No other tests broken

## Validation
- `swift build`
- `swift test`
```
