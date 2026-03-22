# patch

Plan a focused, minimal patch for a specific issue.

## Variables

description: $ARGUMENTS

## Instructions

1. Read the issue description.
2. Identify the minimal set of files to modify.
3. If scope grows beyond a single logical diff, escalate to `/implement`.
4. Create the plan in `docs/plans/patch-{name}.md`.

## Patch Plan Format

```markdown
# Patch: {name}

**Created**: {date}
**Status**: draft

## Issue Summary
One-line description of what needs to change.

## Files to Modify
- `path/to/file.swift` — what changes

## Implementation Steps
1. Specific change
2. Specific change

## Validation
- `swift build`
- `swift test`

## Scope
- **Estimated LOC**: ~N lines changed
- **Risk level**: low | medium
- **Escalation**: If scope exceeds a single diff, use `/implement` instead
```
