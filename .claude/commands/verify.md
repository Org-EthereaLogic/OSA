# verify

Examine and independently verify a subject with evidence. This is a non-destructive operation — read and run, never modify.

## Variables

subject: $ARGUMENTS

## Workflow

1. **Identify scope**: What exactly needs to be verified?
2. **Read primary sources**: Read the relevant source files, documentation, and tests.
3. **Trace dependencies**: Follow imports, relationships, and data flow.
4. **Independent verification**: Run commands to gather evidence:
   - `swift build` — does it compile?
   - `swift test` — do tests pass?
   - `git log` — what changed recently?
   - `git diff` — any uncommitted changes?
5. **Check for contradictions**: Does the code match the documentation? Do tests match the implementation?
6. **Report findings**:

## Report Format

```
=== Verification Report: {subject} ===

### Verified
- [items confirmed as correct with evidence]

### Issues Found
- [items that contradict or have problems]

### Inconclusive
- [items that couldn't be verified with available evidence]

### Evidence
- [commands run and their output summaries]
```
