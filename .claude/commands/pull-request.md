# pull-request

Create a GitHub pull request with quality checks.

## Variables

description: $ARGUMENTS

## Workflow

1. **Pre-flight checks**:
   - Run `git diff origin/main...HEAD --stat` to see what's included
   - Run `git log origin/main..HEAD --oneline` to see commit history
   - Run `swift build` to ensure the project compiles
   - Run `swift test` to ensure all tests pass

2. **Prepare**:
   - Ensure current branch is pushed to remote: `git push -u origin HEAD`
   - Generate PR title from branch name or commit messages (< 70 chars)
   - Generate PR body with:
     - Summary of changes
     - Testing performed
     - Architecture decisions (if any)

3. **Create PR**:
   ```
   gh pr create --title "<title>" --body "<body>"
   ```

4. **Report**: Return the PR URL only.
