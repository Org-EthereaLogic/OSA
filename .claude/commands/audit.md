# audit

Comprehensive project audit against documentation and architectural constraints.

## Workflow

### Phase 1: Context
- Read `CLAUDE.md`, `README.md`, and key `docs/` files
- Identify the project's current state and constraints

### Phase 2: Architecture Compliance
- Verify module boundaries match `docs/sdlc/05-technical-architecture.md`
- Check ADR compliance (offline-first, grounded assistant, local persistence)
- Verify no prohibited patterns (network calls in offline paths, ungrounded AI responses)

### Phase 3: Code Quality
- Run `swift build` — check for warnings and errors
- Run `swift test` — check test results and coverage
- Run `swiftlint` (if configured) — check for style violations
- Scan for placeholder markers (`TODO`, `FIXME`, `TBD`, `XXX`, `HACK`, `PLACEHOLDER`)
- Check for hardcoded secrets or API keys

### Phase 4: Documentation Alignment
- Verify docs match current implementation
- Check for stale references in `docs/`
- Verify ADRs are up to date

### Phase 5: Report

Return a JSON object:

```json
{
  "overall_status": "pass|warn|fail",
  "architecture": {
    "status": "pass|warn|fail",
    "issues": []
  },
  "code_quality": {
    "build_status": "pass|fail",
    "test_status": "pass|fail",
    "lint_status": "pass|fail|skipped",
    "placeholder_count": 0,
    "issues": []
  },
  "documentation": {
    "status": "pass|warn|fail",
    "drift_issues": []
  },
  "issues": [
    {
      "severity": "blocker|warning|info",
      "category": "architecture|quality|docs",
      "description": "...",
      "file_path": "...",
      "recommendation": "..."
    }
  ]
}
```
