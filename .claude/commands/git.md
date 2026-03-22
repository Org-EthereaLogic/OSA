# git

Perform git operations with safety checks and clear reporting.

## Variables

operation: $ARGUMENTS

## Supported Operations

- **status**: Show working tree status
- **add**: Stage files for commit
- **commit**: Create a commit (delegates to `/commit`)
- **push**: Push to remote
- **pull**: Pull from remote
- **fetch**: Fetch from remote
- **sync**: Pull then push (fetch + rebase + push)
- **branch**: Create, list, switch, or delete branches
- **merge**: Merge branches
- **rebase**: Rebase current branch
- **diff**: Show differences
- **log**: Show commit history

## Safety Rules

1. Never use `--no-verify` — if a hook fails, fix the issue
2. Never force push without explicit user confirmation
3. Never perform destructive resets without user confirmation
4. Protected branches (`main`, `master`) block direct commits — use feature branches
5. Always show what will happen before executing destructive operations

## Conventional Commits

When committing, use the format: `<type>(<scope>): <description>`

Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `perf`, `ci`, `style`

## Report

Return:
- **Operation**: What was performed
- **Outcome**: Success or failure with details
- **Actions taken**: Specific git commands executed
- **Next steps**: Suggested follow-up actions (if any)
