Developer: # Implement Sprint 8 Advanced Maps And Navigation

**Date:** 2026-03-29
**Prompt Level:** Level 2 (Workflow Prompt)
**Prompt Type:** Feature
**Complexity Classification:** Complex
**Complexity Justification:** Sprint 8 expands the existing Maps slice across multiple layers: Domain map models and protocols, SwiftData persistence for user-authored navigation artifacts, CoreLocation heading support, offline tile-region management, GPX export, navigation utilities, and focused test coverage. The work touches several seams but should still remain bounded to the existing Map tab, supporting services, and local-only data flows.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt: `/Enhance-prompt-workflow Sprint 8: Advanced Maps & Navigation` | The sprint goal is to turn the current map feature into a higher-value local navigation platform with offline tile management, GPS track recording, user waypoints, GPX export, a standalone compass, distance measurement, rescue-format coordinates, and a sun compass utility. |
| `AGENTS.md`, `CLAUDE.md`, `CONSTITUTION.md`, `DIRECTIVES.md` | Keep the app offline-first, local-first, minimally permissive, and evidence-backed. Do not widen safety-sensitive scope silently. Report blocked verification as `unverified`. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | Advanced geospatial functionality is post-MVP scope, so Sprint 8 must stay bounded and avoid turning OSA into a full route engine, sync product, or backend-backed mapping platform. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | The app already has a Map tab and stress-state UX expectations. New navigation utilities must remain easy to reach and usable offline without forcing a complex flow. |
| `docs/sdlc/05-technical-architecture.md` | The current architecture already contains `LocationService`, `OSMTileCacheService`, `BundledMapAnnotationProvider`, `MapScreen`, and domain-level map types. New work should preserve folder and protocol boundaries and keep persistence details out of feature views. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Location is when-in-use only, no background location is currently justified, and sensitive local data must remain device-local. Map features must not introduce hidden telemetry, remote routing, or background tracking. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Offline reliability, local-state correctness, and explicit test evidence remain first-order quality concerns. New map behavior needs focused unit coverage and clear command evidence. |
| `docs/prompt/enhanced/42-sprint-7-widgets-and-system-integration-enhanced-prompt.md` | Existing sprint prompts use a workflow-prompt structure with architecture context, bounded scope, phased instructions, pre-flight checks, and explicit verification criteria. |
| `OSA/Domain/Maps/Models/MapModels.swift` and `OSA/Domain/Maps/Repositories/MapRepositories.swift` | The map domain already defines `MapAnnotationItem`, `MapDisplayMode`, `CachedTileRegion`, `MapAnnotationProvider`, and a minimal `TileCacheService`. Sprint 8 should extend these seams rather than replace them. |
| `OSA/Networking/Location/LocationService.swift`, `OSA/Networking/Maps/OSMTileCacheService.swift`, and `OSA/Features/Maps/*.swift` | The current implementation supports user location, online or offline map display, bundled annotations, and opportunistic tile reads, but does not yet support saved offline regions, user-authored waypoints, track recording, export, or navigation utilities beyond MapKit's built-in compass control. |

## Classification Summary

- Core intent: evolve the existing Map feature into a bounded, local-first navigation surface with saved offline regions, user waypoints, recorded tracks, GPX export, rescue-oriented coordinates, and field-use orientation tools.
- In scope: offline tile-region management, foreground-only GPS track recording, user-created and persisted waypoints, persisted recorded tracks, GPX export for recorded tracks, distance measurement on map content, a standalone compass, a sun compass helper, rescue-oriented coordinate formatting, focused tests, and verification evidence.
- Out of scope: turn-by-turn routing, remote directions APIs, GPX import, shared or synced map data, CarPlay, watchOS, background location, geofencing, satellite imagery subscriptions, or widening the assistant into live map guidance.

## Assumptions

- The repository root is `/Users/etherealogic-mac-mini/Dev/OSA`.
- Sprint 8 should extend the existing Map tab instead of adding a new top-level app section.
- User-authored navigation artifacts should persist locally using the same Domain-plus-Persistence boundary style used elsewhere in OSA.
- GPS track recording should be explicit, foreground-only, and user-started. If the app backgrounds or location authorization is denied, recording stops or pauses cleanly rather than silently continuing.
- Rescue-format coordinate display should default to degrees and decimal minutes (DDM) because it is common in SAR and emergency handoff contexts, while also supporting decimal degrees for copy or share.
- The standalone compass and sun compass utility should use deterministic local calculations and device sensors only. No AR, camera, or network dependency belongs in this sprint.
- If simulator heading behavior is limited, device-only validation may still be required; any unverified behavior must be reported with the exact blocker.

## Mission Statement

Implement Sprint 8 as a bounded maps-and-navigation enhancement that adds explicit offline tile management, local waypoints and track recording, GPX export, distance measurement, rescue-oriented coordinate display, and compass utilities while preserving OSA's offline-first, privacy-first, and no-background-tracking constraints.

## Technical Context

OSA already has the beginnings of a map platform. The current `MapScreen` can display bundled safety annotations, switch between online and cached-tile modes, and center on the user's current location using `CLLocationManagerService`. The current map domain also already includes a `CachedTileRegion` type, but `TileCacheService` and `OSMTileCacheService` only support passive reads of previously stored tiles. There is no user-visible workflow for saving an offline region, naming it, pruning it, or understanding cache size. There is also no concept of user-authored spatial data such as waypoints or recorded tracks.

The correct implementation shape is to extend the existing map seams rather than bypass them. Domain contracts should continue to live under `OSA/Domain/Maps/`. Persistence implementations should live under `OSA/Persistence/`, not inside feature views. `LocationService` is already the app's CoreLocation boundary and should be extended or complemented in the smallest coherent way needed to support heading and foreground recording. `MapScreen` and its subviews should remain presentation-focused, consuming injected repositories and services through environment or explicit feature-owned state, not by importing SwiftData or reimplementing file management.

The sprint should be organized around seven bounded deliverables:

1. Extend the map domain to represent persisted waypoints, recorded tracks, coordinate-display formats, and offline-tile download metadata.
2. Add local persistence and repository implementations for user-authored waypoints and recorded tracks.
3. Upgrade offline tile caching from opportunistic storage into explicit region management with download, list, inspect, and delete behavior.
4. Extend the location boundary for heading updates and track-recording samples without adding background location.
5. Update the Maps UI with saved regions, waypoint creation, track controls, distance measurement, and rescue-oriented coordinate presentation.
6. Add GPX export and bounded navigation utilities, specifically a standalone compass and a sun compass helper.
7. Land focused tests and explicit verification evidence for persistence, math, tile-management behavior, and user flows.

This sprint must remain proportional. It should improve preparedness navigation and field utility, not become a generalized GIS stack. The preferred design is a local-first navigation toolkit centered on the current map feature, using deterministic calculations, explicit user action, bounded storage budgets, and export interoperability through GPX.

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| Offline tile experience | Cached tiles can be read if they already exist, but there is no explicit save-region workflow, region metadata management, or storage visibility. | Users can deliberately save, inspect, and delete bounded offline tile regions from the app, with local metadata and storage-aware limits. |
| User-authored map content | Only bundled annotations exist. Users cannot save their own waypoints or route notes. | Users can create, edit, view, and delete local waypoints with coordinate and note metadata kept on device. |
| GPS movement capture | The app reads current location but cannot record an outing, path, or breadcrumb trail. | Users can start, pause, resume, and stop a foreground-only recorded track and review its summary locally. |
| Export interoperability | No GPX or map-data export exists. | Recorded tracks can be exported as valid GPX using the app's existing share or export patterns. |
| Orientation tools | `OnlineMapView` exposes MapKit's embedded compass control only. There is no standalone compass or sun-based backup orientation helper. | Users can open a dedicated compass and a deterministic sun-compass utility that remain local-only and usable as bounded tools. |
| Coordinate handoff | Coordinates are not surfaced in a rescue-oriented format for quick sharing or verbal relay. | The map and waypoint surfaces show rescue-friendly coordinates, defaulting to DDM with decimal-degree copy support. |
| Distance measurement | The map can show annotations but does not measure distance between map points or along a simple path. | Users can enter a measurement mode, drop points, and see cumulative distance locally without invoking an online routing API. |
| Architecture boundary | Map logic is light and UI-centric, with no persistence or export layer for advanced navigation artifacts. | The sprint adds domain and persistence seams for navigation data while keeping SwiftData and file handling out of feature views. |
| Verification | Coverage currently includes bundled annotation loading only. | Focused tests cover waypoint persistence, track persistence, coordinate formatting, sun-compass math, tile-region behavior, and at least one UI flow through the Maps surface. |

## Pre-Flight Checks

1. **Verify that the current Maps seams exist before planning the implementation.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
test -f OSA/Domain/Maps/Models/MapModels.swift \
  && test -f OSA/Domain/Maps/Repositories/MapRepositories.swift \
  && test -f OSA/Networking/Location/LocationService.swift \
  && test -f OSA/Networking/Maps/OSMTileCacheService.swift \
  && test -f OSA/Features/Maps/MapScreen.swift \
  && echo "maps seams present"
# Expected: maps seams present
```

*Success signal: the current domain, service, and feature anchors for Sprint 8 are present before editing begins.*

1. **Confirm that advanced navigation artifacts are not already implemented under different names.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
rg -n "Waypoint|RecordedTrack|GPX|SunCompass|CoordinateFormat|MeasureDistance|HeadingStream" OSA OSATests OSAUITests
# Expected: no matches, or only incidental references outside the Maps implementation
```

*Success signal: Sprint 8 starts from a genuine feature gap rather than duplicating an existing implementation path.*

1. **Verify the current map anchors that the sprint must extend.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
rg -n "MapScreen|OnlineMapView|OfflineTileMapView|CachedTileRegion|MapAnnotationProvider|TileCacheService|CLLocationManagerService" OSA
# Expected: matches in Domain/Maps, Networking/Location, Networking/Maps, and Features/Maps
```

*Success signal: the planned work can reuse existing seams instead of inventing parallel infrastructure.*

1. **Verify that local build and test tooling is available before expanding the map feature.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
command -v xcodebuild
command -v snyk
# Expected: absolute paths, or a missing command that must be reported later as an exact blocker
```

*Success signal: verification tooling status is known before implementation starts.*

## Phased Instructions

### Phase 1: Investigation And Architecture Lock

1. **Read the current map, location, and export seams before editing.**

   Inspect these files in full before writing new code:
   `OSA/Domain/Maps/Models/MapModels.swift`
   `OSA/Domain/Maps/Repositories/MapRepositories.swift`
   `OSA/Networking/Location/LocationService.swift`
   `OSA/Networking/Maps/OSMTileCacheService.swift`
   `OSA/Networking/Maps/BundledMapAnnotationProvider.swift`
   `OSA/Features/Maps/MapScreen.swift`
   `OSA/Features/Maps/OnlineMapView.swift`
   `OSA/Features/Maps/OfflineTileMapView.swift`
   `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`
   `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift`
   `OSA/Shared/Support/Export/`

   *Success signal: the implementation plan names the current owning abstractions for location, tile caching, dependency injection, and export rather than treating Maps as a blank slate.*

2. **Lock the implementation shape before editing any files.**

   Adopt these design decisions up front:
   - keep the Map tab as the primary Sprint 8 entry point
   - persist waypoints and recorded tracks through new or extended `OSA/Domain/Maps/` protocols plus `OSA/Persistence/` implementations
   - keep measurement state ephemeral unless there is a strong user-facing reason to persist it
   - extend the existing location boundary for heading and track sampling rather than creating ad hoc CoreLocation calls inside views
   - keep track recording foreground-only and user-initiated
   - treat offline tile download as explicit viewport or bounded-region capture, not background crawling
   - default rescue coordinate display to DDM and offer decimal-degree copy support

   **Rationale:** this keeps the sprint coherent, local-first, and aligned with the current architecture instead of fragmenting behavior across feature views, helpers, and unmanaged files.

   *Success signal: there is one clear plan for domain ownership, persistence, sensor access, and feature scope before code changes begin.*

### Phase 2: Domain, Persistence, And Sensor Boundaries

1. **Extend the map domain to represent user-authored navigation data and coordinate presentation.**

   Add or extend files under `OSA/Domain/Maps/` so the map layer can express:
   - a persisted user waypoint model with ID, title, optional note, coordinate, created-at timestamp, and optional category or symbol
   - a recorded track model with ID, title, started-at, ended-at, optional duration, total distance, and a bounded collection or linked storage of points
   - a coordinate display format model or enum, at minimum supporting DDM and decimal degrees
   - tile-download planning metadata if `CachedTileRegion` needs companion types for request size, estimated tiles, or storage budget decisions

   Extend the repository layer with explicit protocols for waypoint and track CRUD, plus any needed tile-management operations that belong at the domain boundary.

   *Success signal: the map feature can talk about waypoints, tracks, coordinate formats, and region management entirely through domain types and protocols.*

2. **Implement local persistence for waypoints and recorded tracks under `OSA/Persistence/`.**

   Add SwiftData-backed models and repository implementations under `OSA/Persistence/SwiftData/Models/` and `OSA/Persistence/SwiftData/Repositories/` for the new map entities. Keep these details out of `OSA/Features/Maps/`.

   Wire the new repositories into `OSA/App/Bootstrap/Dependencies/AppDependencies.swift` and the SwiftUI environment in `RepositoryEnvironment.swift` or an equivalent existing dependency seam.

   *Success signal: the Maps UI can create, edit, query, and delete waypoints or tracks without importing SwiftData directly.*

3. **Upgrade the tile-cache contract from read-only lookup to explicit region management.**

   Extend `OSA/Domain/Maps/Repositories/MapRepositories.swift` and `OSA/Networking/Maps/OSMTileCacheService.swift` so the tile cache can:
   - plan a bounded offline-region save from a visible map region and zoom range
   - store region metadata that maps cleanly onto `CachedTileRegion`
   - report cached region size and tile count
   - delete a saved region cleanly
   - reject oversized requests before download begins

   Keep the budget explicit and conservative. A reasonable first implementation is a documented per-request tile cap and a documented total-cache size cap. Do not add background downloads, sync, or speculative prefetching.

   *Success signal: offline tiles are a deliberate, inspectable, user-controlled feature instead of an opaque cache side effect.*

4. **Extend the location boundary for heading and foreground recording.**

   Update `OSA/Networking/Location/LocationService.swift` and `CLLocationManagerService` so the app can consume heading updates and filtered location samples suitable for an explicit recording session. Keep the permission model at when-in-use only. If a separate protocol is needed for clarity, keep it adjacent to the current location boundary and inject it through existing dependency seams.

   Do not add background location, visit monitoring, geofencing, or silent recording. If heading data is unavailable, the UI should degrade clearly rather than guessing.

   *Success signal: compass and track-recording features consume a single app-owned sensor boundary, not raw CoreLocation calls sprinkled through views.*

### Phase 3: Maps Feature UI And Navigation Utilities

1. **Refactor the Maps UI into focused surfaces rather than overloading `MapScreen`.**

   Update `OSA/Features/Maps/MapScreen.swift` and add focused supporting views or screen-local models as needed so the map feature can present:
   - current map and annotation browsing
   - saved offline regions management
   - waypoint creation and editing
   - explicit start, pause, resume, and stop controls for track recording
   - distance-measurement mode with reset and cumulative distance display
   - rescue-oriented coordinate display for the user's current location and selected waypoints

   Prefer sheets, toolbar actions, or segmented subviews over adding a new top-level tab. Keep the file sizes and state ownership manageable.

   *Success signal: the Map feature gains Sprint 8 capability without collapsing into a single oversized view file or bypassing repository boundaries.*

2. **Implement user-created waypoint flows using the new repository seam.**

   Add the smallest coherent UI needed to create, inspect, edit, and delete waypoints. A practical flow is a map long-press or action button that captures the current or selected coordinate, opens a waypoint editor, and persists the result locally. Waypoints should be visually distinct from bundled annotations and must render in both online and offline map modes when appropriate.

   *Success signal: users can persist their own map points locally and see them again after relaunch.*

3. **Implement track recording as an explicit foreground session.**

   Add feature logic that starts recording only when the user chooses it, samples location updates through the app-owned location boundary, persists the final result locally, and surfaces clear session state while recording. Stop or pause recording cleanly if authorization is denied, the app backgrounds, or the session is explicitly ended.

   Recorded tracks should show a basic summary at minimum: title or generated label, elapsed time, point count, and total distance.

   *Success signal: the app can record and persist a local track without introducing background location or hidden state.*

4. **Add distance measurement and rescue coordinate presentation.**

   Implement a bounded measurement mode that lets the user place at least two points and view straight-line cumulative distance locally. Separately, add coordinate formatting utilities so the current location, selected map point, and waypoints can display DDM by default and decimal degrees as a secondary share or copy format.

   Use deterministic math utilities in a shared helper location such as `OSA/Shared/Support/Tools/` if the logic is non-trivial. Do not put geodesy or formatting math inline in SwiftUI views.

   **Rationale:** measurement and coordinate formatting are reusable navigation primitives that deserve testable, view-independent logic.

   *Success signal: users can measure distance and relay coordinates in a rescue-friendly format without online routing.*

5. **Add GPX export for recorded tracks using the repository's existing export patterns.**

   Add a focused export helper such as `OSA/Shared/Support/Export/GPXExporter.swift` and connect it to recorded-track detail or action flows using the same share-sheet or export style already used for checklist, inventory, note, or content export.

   Export valid GPX 1.1 with basic metadata, track segments, and timestamps where available. Keep the format deterministic and locally generated.

   *Success signal: a recorded track can be exported and shared as a standards-based GPX file without adding a third-party library.*

6. **Add a standalone compass and a deterministic sun compass utility.**

   Implement two bounded navigation utilities inside `OSA/Features/Maps/` or a nearby map-owned seam:
   - a standalone compass view driven by heading updates from the location boundary
   - a sun compass helper that calculates approximate sun azimuth from the current date, time, and coordinate, then explains orientation in plain local terms

   Keep both utilities local-only. Do not use the camera, augmented reality, or online ephemeris services in this sprint.

   *Success signal: users can open orientation tools directly from the Maps experience even when offline, with clear fallback messaging if heading is unavailable.*

### Phase 4: Verification And Regression Coverage

1. **Add focused tests for the new map-domain and utility seams.**

   Add the smallest focused test set that proves the sprint's new logic, for example:
   `OSATests/WaypointRepositoryTests.swift`
   `OSATests/TrackRepositoryTests.swift`
   `OSATests/OSMTileCacheServiceTests.swift`
   `OSATests/CoordinateFormatterTests.swift`
   `OSATests/SunCompassCalculatorTests.swift`
   `OSATests/TrackRecordingServiceTests.swift`

   If implementation shape differs, keep equivalent coverage for persistence, tile-region management, coordinate formatting, and sun-compass math.

   *Success signal: the most failure-prone new behavior has dedicated automated coverage instead of relying on manual map poking.*

2. **Add at least one UI or content-input path for the Maps experience.**

   Extend an existing UI suite such as `OSAUITests/OSAContentAndInputTests.swift` or add a focused map UI test that covers at least one end-to-end flow, for example waypoint creation, measurement-mode activation, or map utility navigation.

   *Success signal: the sprint has at least one automated user-flow check through the Maps surface, not just isolated unit tests.*

3. **Run focused verification for the new map work.**

   Execute:

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test \
  -only-testing:OSATests/MapAnnotationProviderTests \
  -only-testing:OSATests/WaypointRepositoryTests \
  -only-testing:OSATests/TrackRepositoryTests \
  -only-testing:OSATests/OSMTileCacheServiceTests \
  -only-testing:OSATests/CoordinateFormatterTests \
  -only-testing:OSATests/SunCompassCalculatorTests \
  -only-testing:OSAUITests/OSAContentAndInputTests
# Expected: targeted Maps and navigation tests pass
```

   If exact test names differ, update the command to the actual new test targets and report the final command used.

   *Success signal: the new persistence, utility, and UI behaviors have executable evidence rather than narrative claims.*

1. **Run a build pass for the app after the targeted tests.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
# Expected: Build succeeds with the expanded Maps feature integrated into the app target
```

   *Success signal: the app compiles cleanly after the Maps and navigation slice is integrated.*

### Phase 5: Security, Privacy, And Quality Gates

1. **Verify the location and privacy posture did not widen.**

   Check that the sprint still uses when-in-use authorization only, foreground-only recording, and no background location or remote telemetry. If any user-facing permission copy changed, update it only as needed to reflect truthful behavior.

   *Success signal: Sprint 8 adds navigation value without silently turning OSA into a background-tracking app.*

2. **Run first-party security scanning for the new code.**

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA
snyk code test --path="$PWD"
# Expected: no new high-severity issues introduced by the Sprint 8 implementation
```

   If `snyk` is unavailable, report the exact blocker and mark security verification `unverified`.

   *Success signal: the new first-party code has been checked with the repository's required security scan or explicitly reported as blocked.*

## Guardrails

- Do not add background location, geofencing, visit monitoring, or silent track recording.
- Do not add turn-by-turn routing, remote directions APIs, or any backend dependency.
- Do not add GPX import, collaborative maps, syncing, or cross-device sharing.
- Do not expose notes, Ask history, or other free-form personal content through the Maps feature unless the user explicitly created a map-specific waypoint note stored locally.
- Do not add a third-party geospatial or export dependency unless the existing Swift and Apple frameworks are demonstrably insufficient and the need is documented in the prompt execution report.
- Keep tile downloads bounded by explicit request and storage limits; reject oversize requests instead of trying to be clever.
- Keep SwiftData and file-system details inside `OSA/Persistence/` or service layers, never inside `OSA/Features/Maps/` views.
- Keep the implementation proportional: one improved Map feature with supporting utilities, not a generalized GIS platform.

## Verification Checklist

- [ ] Offline tile-region save, list, and delete flows exist and are bounded by explicit limits.
- [ ] Users can create, edit, and delete local waypoints that persist across relaunch.
- [ ] Users can start and stop a foreground-only recorded track and review its summary.
- [ ] Recorded tracks can export as valid GPX.
- [ ] The Maps feature shows rescue-oriented coordinates in DDM with decimal-degree support.
- [ ] Distance measurement works without online routing.
- [ ] Standalone compass and sun compass utilities are present with clear fallback behavior.
- [ ] Focused map-domain, tile, math, and persistence tests pass.
- [ ] App build succeeds, or the exact blocker is reported as `unverified`.
- [ ] `snyk code test --path="$PWD"` passes, or the exact blocker is reported as `unverified`.

## Error Handling

Use this section together with `## Verification Checklist` and the final report contract:

- Every verification or checklist item must be labeled `verified`, `unverified`, or `not applicable`.
- Only claim success when it is backed by command evidence or direct inspection evidence.
- During verification, run only the named verification commands unless a substitute is necessary; if you use a substitute, justify it explicitly in the report.
- If a blocker prevents full completion, preserve existing behavior, land the safest bounded subset, and mark the remainder `unverified` or as a bounded compromise in the report.

| Error Condition | Resolution |
| --- | --- |
| Tile-region request exceeds the storage or tile-count budget | Reject the request before download, show the user how to narrow the region or zoom range, keep the cache unchanged, and report any deferred work as a bounded compromise rather than expanding scope. |
| Location permission denied or restricted | Keep the map usable with bundled annotations and saved regions, disable recording or live compass features, show a clear permission explanation, and mark dependent verification `unverified` when permission-sensitive flows cannot be exercised. |
| Heading data unavailable in simulator or on a device | Surface a fallback state in the compass UI, keep sun-compass math available, report device-only verification requirements explicitly, and avoid claiming feature success without device or direct inspection evidence. |
| Track recording is interrupted by app backgrounding | Stop or pause the session deterministically, persist whatever portion is valid, make the stop reason visible to the user, and prefer the safe bounded behavior over speculative background extensions. |
| GPX export produces invalid or empty output | Add focused GPX format tests, verify timestamps and track points are serialized, block share if the export payload is invalid, and mark export results `unverified` if required validation cannot be completed. |
| Coordinate formatting is ambiguous or inconsistent | Centralize formatters in one helper, add golden-value tests for DDM and decimal degrees, and avoid ad hoc formatting in views. |
| `xcodebuild` fails because full Xcode is unavailable | Report the exact command, exact error text, and date; mark build or test verification `unverified`; describe the impact; and do not substitute ad hoc tooling unless the substitute is necessary and justified in the report. |
| `snyk` command is unavailable | Report the exact command, exact error text, and date; mark the security claim `unverified`; describe the impact; and keep any substitute check explicitly labeled as a justified substitute rather than equivalent verification. |
| Device-only capability, missing tool, or partial implementation risk blocks full delivery | Preserve existing behavior, ship the smallest safe subset that still fits scope, avoid risky last-minute expansion, and record the remainder in the report as `unverified` or a bounded compromise with clear user impact. |

## Out Of Scope

- Turn-by-turn directions, route snapping, or ETA calculation
- GPX import, KML import, or any other map-data ingestion format
- Background track recording, geofencing, or safety alerts tied to background location
- CarPlay, Apple Watch, iPad-specific layout work, or widget work for map navigation
- Syncing, backup, or any remote storage of waypoints or tracks
- Satellite imagery, topographic subscription layers, or commercial map-vendor SDK integration
- MGRS, UTM, or a large geodesy format matrix beyond the bounded rescue-oriented coordinate formats defined for this sprint

## Alternative Solutions

1. **Preferred:** Persist waypoints and tracks through SwiftData-backed repositories and keep tile metadata in the existing map-service seam.
   Pros: consistent with the rest of OSA, testable, durable across relaunch, and aligned with repository boundaries.
   Cons: requires schema and persistence work across multiple files.

2. **Fallback if schema expansion becomes too risky for one sprint:** Persist waypoints through SwiftData but store recorded-track exports as bounded local files with lightweight metadata until full track persistence lands.
   Pros: reduces migration surface while still delivering user value from recording and GPX export.
   Cons: introduces a split persistence model and should be treated as an explicit compromise, not the default.

3. **Fallback if heading support proves unreliable in simulator-heavy validation:** Ship the compass and sun-compass UI with robust device-only verification notes and automated math coverage, while keeping the sensor-facing portion thin and clearly degraded when heading is unavailable.
   Pros: preserves feature value without faking verification.
   Cons: requires more manual device validation before claiming the compass fully verified.

## Report Format

1. **Files changed:** list all created and modified files, grouped by domain, persistence, features, shared helpers, and tests.
2. **Architecture decisions applied:** summarize the final ownership of waypoints, tracks, tile management, export, and sensor access.
3. **Feature outcomes:** state which Sprint 8 capabilities landed and any bounded compromises made.
4. **Verification evidence:** list the exact build, test, and security commands run with pass or `unverified` status.
5. **Privacy and permissions check:** confirm whether location scope remained when-in-use and foreground-only.
6. **Open follow-up items:** note any intentionally deferred work, manual device checks, or blocked verification.
