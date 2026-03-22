# Commit

Generate and execute a git commit with a properly formatted conventional commit message.

## Variables

message_hint: $ARGUMENTS

## Instructions

- Run `git diff HEAD` to understand what changes have been made
- Generate a concise commit message using conventional commit format: `<type>(<scope>): <description>`
- Types: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `perf`, `ci`, `style`
- Scope is optional but encouraged (e.g., `persistence`, `retrieval`, `assistant`, `ui`, `hooks`)
- The description must be:
  - Present tense ("add", "fix", "update" — not "added", "fixed", "updated")
  - 50 characters or less
  - Descriptive of the actual changes
  - No period at the end
- If `message_hint` is provided, use it as context for the commit message
- Do not include "Generated with" or "Authored by" boilerplate

## Run

1. Run `git diff HEAD` to review changes
2. Run `git add -A` to stage all changes
3. Run `git commit -m "<generated_commit_message>"` to create the commit

## Report

Return ONLY the commit message that was used.
