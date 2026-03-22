# review

Review an implementation against its specification or acceptance criteria.

## Variables

subject: $ARGUMENTS

## Workflow

1. **Identify the spec**: Find the relevant documentation, issue, or acceptance criteria for the subject.
2. **Read the implementation**: Read all files involved in the implementation.
3. **Run validation**:
   - `swift build`
   - `swift test`
4. **Evaluate against criteria**: Check each acceptance criterion or requirement.
5. **Classify issues** found:
   - `blocker`: Must be fixed before merge — correctness, security, data loss risk
   - `tech_debt`: Should be tracked — code quality, missing tests, documentation gaps
   - `skippable`: Nice to have — style preferences, minor improvements

## Report

Return a JSON object:

```json
{
  "success": true,
  "review_summary": "Brief summary of the review findings",
  "checks": {
    "build": "pass",
    "tests": "pass"
  },
  "review_issues": [
    {
      "issue_number": 1,
      "description": "Description of the issue",
      "resolution": "Suggested fix",
      "severity": "blocker|tech_debt|skippable",
      "file_path": "path/to/file.swift",
      "line": 42
    }
  ]
}
```
