# Start

Build and prepare the OSA project for development.

## Steps

1. Resolve dependencies:
   ```
   swift package resolve
   ```

2. Build the project:
   ```
   swift build
   ```

3. Run tests to verify the build:
   ```
   swift test
   ```

4. If an Xcode project exists, open it:
   ```
   open *.xcodeproj 2>/dev/null || open *.xcworkspace 2>/dev/null || echo "No Xcode project found — use swift build"
   ```

## Report

Return:
- Build status (success/failure with errors)
- Test results (pass count, fail count)
- Any warnings or issues to address
