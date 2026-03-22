# doc-maintain

Audit and update existing documentation for codebase drift.

## Workflow

### Phase 1: Discover
- Inventory all documentation in `docs/`
- Categorize: SDLC docs, ADRs, plans, generated docs

### Phase 2: Drift Detection
- Compare documentation claims against current code
- Check for:
  - Stale file path references
  - Outdated architecture descriptions
  - Requirements that have been implemented but not marked done
  - Code that exists but isn't documented
  - Contradictions between documents

### Phase 3: Update
- Fix stale references and outdated descriptions
- Update requirement statuses
- Add missing documentation for new code
- ADRs are append-only — add new decisions, don't modify old ones

### Phase 4: Validate
- Run `swift build` and `swift test` to ensure nothing was broken
- Verify cross-references between documents are valid

### Phase 5: Report

Return a JSON object:

```json
{
  "files_audited": 0,
  "files_updated": 0,
  "drift_issues_found": 0,
  "drift_issues_fixed": 0,
  "unfixable_issues": [],
  "validation_passed": true
}
```
