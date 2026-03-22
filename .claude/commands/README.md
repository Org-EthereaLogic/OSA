# .claude/commands

User-invocable slash commands for Claude Code. Trigger with `/<command-name>` in the chat interface.

## Commands

### Core Workflow

| File | Command | Purpose |
|------|---------|---------|
| `prime.md` | `/prime` | Prime Claude's context with project structure and key files |
| `implement.md` | `/implement` | Guided implementation workflow: plan, build, test cycle |
| `start.md` | `/start` | Build and run the Xcode project |
| `chore.md` | `/chore` | Run routine maintenance tasks |
| `cleanup_workspace.md` | `/cleanup_workspace` | Remove build artifacts, clear caches, clean DerivedData |
| `verify.md` | `/verify` | Examine and independently verify a subject with evidence |

### Git & Shipping

| File | Command | Purpose |
|------|---------|---------|
| `commit.md` | `/commit` | Generate conventional commit from staged changes |
| `git.md` | `/git` | Git operations with safety checks and conflict guidance |
| `pull-request.md` | `/pull-request` | Create a GitHub PR with quality checks |

### Testing & Review

| File | Command | Purpose |
|------|---------|---------|
| `test.md` | `/test` | Run validation test suite (build, lint, tests) |
| `review.md` | `/review` | Review implementation against spec or acceptance criteria |
| `audit.md` | `/audit` | Comprehensive project audit against documentation and architecture |

### Planning

| File | Command | Purpose |
|------|---------|---------|
| `plan.md` | `/plan` | Create structured implementation plan for any task |
| `feature.md` | `/feature` | Plan a new feature from an issue or description |
| `bug.md` | `/bug` | Plan a bug fix with root cause analysis |
| `patch.md` | `/patch` | Plan a focused, minimal patch for a specific issue |

### Documentation

| File | Command | Purpose |
|------|---------|---------|
| `document.md` | `/document` | Generate documentation from git diff analysis |
| `doc-maintain.md` | `/doc-maintain` | Audit and update existing docs for codebase drift |
| `sync.md` | `/sync` | Audit docs/artifacts, update for drift, commit and push |

## Notes

- Commands expand to full prompts when invoked — they are not shell scripts
- The `Skill` tool in Claude Code dispatches these commands
- To add a new command: create a `.md` file here with the prompt body
