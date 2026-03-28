Date: 2026-03-28
Subject: Home Spotlight / RSS Feed verification and reporting correction
Status: Verified

## Summary

This audit corrected stale reporting around the Home Spotlight changes landed in commit `c316b95`.

Verified facts:

- The current Home screen shows a randomized selection of 3 quick cards from the full local repository set on load and pull-to-refresh.
- The Home Spotlight segmented picker switches between `Quick Cards` and `Feed`.
- The Feed tab loads the 5 most recent RSS-discovered articles sorted by publish date descending.
- Feed rows display the article title, source host, and publish date when available.
- Feed article taps use the system URL handler (`openURL`) rather than a Safari-specific integration.
- The bundled `SeedContent` directory currently loads successfully from the app bundle, which validates the manifest content hashes against the shipped files.

## Current Verification Evidence

### Full test run

Command run on 2026-03-28:

```bash
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test -resultBundlePath /tmp/OSA-home-spotlight-fix.xcresult
```

Result:

- `TEST SUCCEEDED`
- `423` total tests
- `399` unit tests
- `24` UI tests
- `0` failures

Breakdown:

- `338` XCTest unit tests in `OSATests.xctest`
- `61` Swift Testing unit tests in `OSATests/`
- `24` UI tests in `OSAUITests/`

Artifact:

- `/tmp/OSA-home-spotlight-fix.xcresult`

### Bundled seed-content integrity

Verification path:

- `SeedContentLoader.bundled(in:)` validates every pack content hash before decoding.
- `AppModelContainer.makeShared(bundle:)` uses that loader during normal app startup and would fail startup on a bundled hash mismatch.
- `OSATests/SeedContentRepositoryTests.swift` now includes a regression test that loads the shipped `SeedContent` directory from the app bundle.

Additional shell verification run on 2026-03-28:

```bash
shasum -a 256 OSA/Resources/SeedContent/handbook-foundations-v1.json
```

Observed hash:

- `acc6c8298b6d83a0a994f3b6e4bc418e4588fe3eaad5b966f7cf367625cdca11`

This matches the current manifest entry in `OSA/Resources/SeedContent/SeedManifest.json`.

## Corrected File List For Commit c316b95

The complete file list changed in `HEAD~1..HEAD` is:

- `CLAUDE.md`
- `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`
- `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift`
- `OSA/App/Bootstrap/OSAApp.swift`
- `OSA/Features/Home/HomeScreen.swift`
- `OSA/Resources/SeedContent/SeedManifest.json`
- `OSATests/AppEntityQueryTests.swift`
- `OSAUITests/OSAContentAndInputTests.swift`
- `OSAUITests/OSAFullE2EVisualTests.swift`
- `docs/sdlc/04-information-architecture-and-ux-flows.md`
- `docs/sdlc/05-technical-architecture.md`
- `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md`
- `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md`

## Reporting Corrections

- Replace `All 84 tests pass (61 unit + 23 UI, 0 failures)` with the current full-suite result: `423 tests total (399 unit, 24 UI), 0 failures` for the 2026-03-28 verification run.
- Describe the Feed rows as showing source host and publish date when available.
- Describe article opening as using the system URL handler, not Safari specifically.
- Treat the stale handbook hash as a now-covered startup regression: the shipped bundle currently validates, and a regression test now protects the bundled resource path.
