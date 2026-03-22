# document

Generate documentation from recent changes.

## Variables

subject: $ARGUMENTS

## Workflow

1. Analyze changes:
   ```
   git diff origin/main
   ```
2. Read the changed files and their context.
3. Generate documentation covering:
   - **Overview**: What was built or changed
   - **Technical Implementation**: Files modified, key changes, architectural decisions
   - **How to Use**: Usage instructions or API examples
   - **Validation**: How to verify the changes work

## Output

Create `docs/doc-{subject}.md` with:

```markdown
# {Subject}

**Created**: {date}
**Based on**: git diff from {commit range}

## Overview
What was built and why.

## What Changed
Summary of changes with file references.

## Technical Implementation
### Files Modified
- `path/to/file.swift` — description of changes

### Key Changes
Detailed explanation of significant changes.

## How to Use
Usage instructions or examples.

## Validation
How to verify the changes work correctly.
```
