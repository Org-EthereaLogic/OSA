# docs/prompt/enhanced

Curated prompts and prompt-derived documents.

## Current Contents

- `sdlc_doc_suite_prompt.md` preserves the source prompt used to generate the SDLC suite.
- `13-task-03-swiftdata-schema-and-repository-protocols-enhanced-prompt.md`, `14-milestone-1-phase-2-persistence-seed-import-and-tests-enhanced-prompt.md`, `15-milestone-1-exit-criteria-handbook-and-quick-card-browsing-ui-enhanced-prompt.md`, `16-milestone-3-grounded-ask-retrieval-pipeline-enhanced-prompt.md`, `17-milestone-3-capability-detection-and-model-adapter-enhanced-prompt.md`, and `18-milestone-3-assistant-policy-prompt-shaping-and-safety-guardrails-enhanced-prompt.md` are implementation-facing enhanced prompts.
- `19-mvp-handbook-and-quick-card-corpus-expansion-enhanced-prompt.md` expands the seeded handbook and quick-card corpus for the broader MVP library.
- `20-m3-polish-sprint-home-settings-ask-navigation-seed-manifest-enhanced-prompt.md` captures the M3 polish sprint focused on live Home data, Settings capability status, Ask scope/navigation, and seed-manifest integrity.
- `21-checklist-swiftdata-runtime-investigation-and-test-recovery-enhanced-prompt.md` captures the investigation and recovery plan for the checklist SwiftData runtime crash plus the remaining safety and UI test regressions.
- `22-checklist-swiftdata-container-lifetime-final-report-enhanced-prompt.md` preserves the verified final report showing that the checklist crash was caused by test-only `ModelContainer` lifetime loss, not a production SwiftData relationship-graph defect.
- `23-app-bundle-seed-content-packaging-and-full-launch-validation-enhanced-prompt.md` captures the immediate packaging fix for bundled seed content, the required cold-launch validation pass, and the preserved M4 dependency sequence that follows once the offline app baseline is stable.
- `24-coresimulator-restart-blocker-and-launch-validation-enhanced-prompt.md` preserves the simulator-service blocker that must be cleared before launch validation evidence can be trusted.
- `25-simulator-screen-audit-and-m4-parallel-start-enhanced-prompt.md` captures the screenshot-backed screen audit that determines whether OSA has a solid offline baseline or should do UI hardening before starting `M4P1 ConnectivityService` and `M4P2 import domain models` in parallel.
- `26-headless-sidebar-audit-blockers-final-report-enhanced-prompt.md` preserves the executed screen-audit limitations on a headless Mac mini, including the unverified `More` surfaces behind `.sidebarAdaptable` and the non-functional `AssetCatalogSimulatorAgent` asset-compilation issue.
- `27-m4p3-trusted-source-allowlist-and-http-client-enhanced-prompt.md` captures the first online-enrichment execution slice after M4P1 and M4P2: the launch trusted-source allowlist plus the minimal guarded HTTP client that knows who OSA may fetch from.
- `28-m4p5-refresh-and-retry-coordination-enhanced-prompt.md` captures stale-source detection, durable `PendingOperation` retry semantics, and automatic in-app refresh coordination for approved imported sources after M4P4.
- `30-m4p6-ask-online-offer-and-import-ux-enhanced-prompt.md` captures the Ask-side trusted-source import fallback that appears after insufficient local evidence, reuses the existing allowlist, HTTP client, import pipeline, and connectivity model, and proves imported content becomes available through local Ask retrieval and Library search.
- `31-milestone-5-hardening-and-launch-enhanced-prompt.md` captures the release-hardening slice after Milestone 4: migration tests, offline stress coverage, safety regression expansion, App Store materials, TestFlight feedback-loop artifacts, and the dated release-readiness evidence pack.
- `32-testflight-internal-alpha-rc-5-rc-6-device-validation-enhanced-prompt.md` captures the next bounded step after Milestone 5 hardening: Stage 1 internal alpha execution for RC-5 and RC-6, including device-backed performance and privacy validation, evidence capture, and narrow release-readiness updates.
- `33-m6p1-app-intents-foundation-enhanced-prompt.md` captures the first Apple Intelligence surface slice: a shared bootstrap seam for App Intents, `AskLanternIntent`, `AppShortcutsProvider`, compact citation-preserving Siri answers, and focused tests that prove Siri reuses the existing grounded Ask pipeline.
- `34-m6p2-app-entities-and-spotlight-indexing-enhanced-prompt.md` captures the next Apple Intelligence slice after M6P1: four App Entities, search-backed entity queries, Spotlight exposure through `IndexedEntity`, privacy-bounded inventory handling, and focused verification that keeps later M6 phases out of scope.
- `35-m6p3-fm-powered-inventory-completion-enhanced-prompt.md` captures the next Apple Intelligence slice after M6P2: a bounded inventory completion service using on-device Foundation Models structured output when available, deterministic heuristic fallback when unavailable, conservative merge rules in the shared inventory form, and focused verification that keeps later M6 phases and broader inventory redesign out of scope.
- `36-m6p4-assistant-schema-onscreen-content-and-navigation-intents-enhanced-prompt.md` captures the next Apple Intelligence slice after M6P3: AssistantSchema-aware `AskLanternIntent` metadata, deep-link navigation intents for quick cards and handbook sections, app-owned on-screen content publication for the currently viewed reading surface, and focused verification that keeps M6P5 and broader navigation redesign out of scope.
- `37-sprint-2-list-ergonomics-and-discovery-enhanced-prompt.md` captures the next UX-hardening slice for list-heavy surfaces: local search for Quick Cards, Notes, and Checklists, richer zero and no-results states, inventory and checklist swipe actions, quick-card and inventory context menus, and Library topic-browse plus recently viewed behavior implemented with existing local settings patterns.
- `38-sprint-3-motion-haptics-settings-polish-enhanced-prompt.md` captures the next UX-hardening slice for motion and polish: stress-friendly Home and Checklist transitions, centralized haptic reuse, lightweight in-app connectivity feedback based on the current state stream, and clearer Settings organization around accessibility, emergency contacts, and discovery status.
- `39-sprint-4-survival-tools-and-communication-utilities-enhanced-prompt.md` captures the next bounded utility slice: an offline `Tools` surface with Morse signaling, bright-screen SOS and signal mirror aids, whistle playback, timer and stopwatch utilities, unit conversion, radio reference data, and an approximate declination helper delivered without new permissions or online behavior.

## Rules

- Keep reusable prompt artifacts here after they are cleaned up from draft form.
- Do not assume numbered filenames in this folder are canonical; the directory location controls the role.
- If a document graduates into the living SDLC suite, move it to `../../sdlc/` and update links accordingly.

## Notes

- `sdlc_doc_suite_prompt.md` is preserved input material and may reference the original flat `docs/` layout.
- Keep new prompt files aligned with the current `docs/sdlc/` and `docs/adr/` structure.
