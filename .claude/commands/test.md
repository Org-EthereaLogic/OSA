# test

Run the validation test suite for OSA.

## Workflow

Run these checks in sequence:

1. **Build check**:
   ```
   swift build
   ```

2. **Lint check** (if SwiftLint is configured):
   ```
   swiftlint lint --quiet
   ```

3. **Test suite**:
   ```
   swift test
   ```

## Report

Return a JSON array with results:

```json
[
  {
    "test_name": "build",
    "passed": true,
    "execution_command": "swift build",
    "test_purpose": "Verify project compiles without errors or warnings",
    "error": null
  },
  {
    "test_name": "lint",
    "passed": true,
    "execution_command": "swiftlint lint --quiet",
    "test_purpose": "Verify code style compliance",
    "error": null
  },
  {
    "test_name": "tests",
    "passed": true,
    "execution_command": "swift test",
    "test_purpose": "Verify all unit and integration tests pass",
    "error": null
  }
]
```
