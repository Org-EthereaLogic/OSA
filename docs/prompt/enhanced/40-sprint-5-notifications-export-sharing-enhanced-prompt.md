# Implement Sprint 5 Notifications, Export, Sharing, And Library Cross-Links

**Date:** 2026-03-29  
**Prompt Level:** Level 2  
**Prompt Type:** Feature  
**Complexity Classification:** Complex  
**Complexity Justification:** This sprint adds one new app-service seam for local notifications, several bounded export and sharing flows across existing detail screens, a family emergency plan template built on the current notes model, stronger related-content navigation, and clearer Library content-type filtering. It should stay inside the current app-shell, feature, and shared-component boundaries without introducing backend dependencies, but it will likely touch 10-16 Swift files plus focused tests.

## Inputs Consulted

| Source | Key Takeaways |
| --- | --- |
| Source prompt | Sprint 5 is a post-M5 feature slice for proactive local alerts and user-initiated sharing and export: expiring-inventory notifications, checklist PDF export, inventory CSV export, note markdown or plain-text export, quick-card and handbook sharing, family emergency plan templates, related-content cross-links, and Library filtering by content type. |
| `AGENTS.md`, `CONSTITUTION.md`, `DIRECTIVES.md`, `CLAUDE.md` | Keep the work offline-first, local-first, minimally scoped, evidence-backed, and safe. New networking, unverifiable claims, and speculative architecture are out of bounds. |
| `docs/sdlc/03-mvp-scope-roadmap.md` | Optional export and richer inventory alerts are appropriate as a bounded post-M5 enhancement. Core value must remain useful offline and must not depend on background services or remote infrastructure. |
| `docs/reference/2026-03-28-feature-adoption-recommendations.md` | The repository already identified local expiry alerts, family emergency plan templates, related-content links, and Library content-type filtering as natural follow-up work. |
| `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`, `OSA/App/Bootstrap/OSAApp.swift`, and `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift` | App-owned services are constructed in `AppDependencies`, injected through `EnvironmentValues`, and started from the app bootstrap. This is the correct seam for local notification scheduling. |
| `OSA/Domain/Inventory/Repositories/InventoryRepositories.swift` and `OSA/Domain/Inventory/Models/InventoryItem.swift` | `InventoryRepository` already exposes `itemsExpiringSoon(within:)`, and inventory items already carry expiry dates and reorder thresholds. Sprint 5 should reuse those contracts instead of widening the repository layer. |
| `OSA/Domain/Notes/Models/NoteRecord.swift` and `OSA/Domain/Notes/Repositories/NoteRepositories.swift` | Notes already support `NoteType.familyPlan` plus linked handbook-section and inventory-item IDs. The family emergency plan template should reuse this existing model rather than invent a new persistence type. |
| `OSA/Features/Inventory/InventoryScreen.swift` and `OSA/Features/Inventory/InventoryItemDetailView.swift` | Inventory CRUD and detail flows already exist and are the best user-entry points for CSV export and for rescheduling local alerts after item mutations. |
| `OSA/Features/Checklists/ChecklistRunView.swift` and `OSA/Features/Checklists/ChecklistTemplateDetailView.swift` | Checklist run and template detail screens already own the user-facing checklist representations and are the correct export-to-PDF entry points. |
| `OSA/Features/Notes/NoteDetailView.swift` and `OSA/Features/Notes/NoteEditorView.swift` | Notes already have a detail action menu and a markdown editor. Sprint 5 should add export and template conveniences here rather than redesigning the notes domain. |
| `OSA/Features/QuickCards/QuickCardDetailView.swift` and `OSA/Features/Library/HandbookSectionDetailView.swift` | These detail screens are already the right reading surfaces for share-sheet entry points and related-content links. |
| `OSA/Features/Library/LibraryScreen.swift` and `OSA/Features/Library/SearchResultsView.swift` | Library already has scenario and topic browse plus search-result kind filtering. Sprint 5 should strengthen and surface content-type filtering rather than rebuild Library navigation. |
| `OSA/Shared/Components/MessageComposeView.swift` | There is already a reusable UIKit wrapper pattern for system share UI. A share-sheet wrapper should follow the same style rather than being embedded ad hoc in feature views. |
| `OSATests/InventoryRepositoryTests.swift`, `OSATests/NoteRepositoryTests.swift`, `OSAUITests/OSAContentAndInputTests.swift`, and `OSAUITests/OSAAccessibilitySmokeTests.swift` | Existing tests provide the nearest coverage anchors. Sprint 5 should add focused tests around new formatters and notification scheduling and extend UI coverage only for visible wiring. |

## Assumptions

- Local alerts are user-opt-in, device-local notifications only. Do not add remote push, background fetch, or server-side reminder infrastructure.
- Inventory CSV export covers the currently visible inventory scope in `InventoryScreen` so the export respects the user's archived-item toggle.
- Checklist PDF export may support both template detail and active-run detail, but it should remain print-friendly and text-first rather than becoming a custom report designer.
- Notes export is per-note, initiated from `NoteDetailView`, with markdown and plain-text outputs generated from the existing stored fields.
- The family emergency plan template should be implemented as a prefilled note using `NoteType.familyPlan`, not as a new SwiftData entity or a checklist-template redesign.
- Related-content cross-links should stay limited to navigable local content types already supported by the app. Do not invent a new imported-knowledge reader in this sprint.

## Mission Statement

Add a bounded Sprint 5 slice that introduces user-opt-in local inventory-expiry notifications, user-initiated export and sharing flows for existing content surfaces, a reusable family emergency plan note template, stronger related-content navigation, and clearer Library content-type filtering without introducing backend dependencies, remote push, or new persistence architecture.

## Technical Context

This sprint should build on existing seams instead of broadening the architecture.

- Local notification scheduling is an app integration concern, so the service belongs in the app layer and should be wired through `AppDependencies` and `EnvironmentValues`, not hidden inside feature views or persistence repositories.
- Inventory already exposes the only repository query needed for expiry alerts. Keep scheduling logic above the repository layer and reschedule from app startup and the existing mutation entry points rather than changing persistence contracts.
- Export and share flows belong close to the surfaces users are already viewing: inventory list, checklist detail, note detail, quick-card detail, and handbook section detail.
- Reusable share or export helpers should stay small and format-focused. One lightweight `ActivityShareSheet` wrapper plus a few bounded formatter or renderer helpers is enough.
- The notes model already has the right `familyPlan` semantic type and linked-content fields. Use that instead of inventing a dedicated emergency-plan schema.
- Library already contains the beginnings of content-type filtering inside `SearchResultsView`. The right move is to make those filters clearer and more explicit, not to rebuild Library browsing from scratch.
- All export and sharing flows must be explicit user actions. Do not automatically move private data off device, and do not present sharing as background sync.

Use the smallest coherent implementation:

1. Add one local notification service for expiry reminders only.
2. Add one shared share-sheet wrapper and a few focused export builders.
3. Add export and share entry points only to the already-owned detail or list screens.
4. Reuse `NoteType.familyPlan` and existing note creation flows for the family emergency plan template.
5. Extend current related-content and search-filter behavior instead of creating a new discovery subsystem.

## Problem-State Table

| Surface | Current State | Target State |
| --- | --- | --- |
| Inventory expiry reminders | Inventory items show expiry dates in-app, but there are no proactive local alerts. | Users can opt into local expiry notifications with a bounded lead time and have reminders rescheduled from app-local data. |
| Inventory export | Inventory exists only inside the app UI. | Users can export the currently visible inventory list as a CSV file from the existing inventory surface. |
| Checklist export | Checklist templates and runs are readable only inside the app. | Users can export a checklist template or active run as a print-friendly PDF and share the generated file. |
| Note export | Notes can be read and edited, but not exported. | Users can export a note as markdown or plain text from the existing note-detail action menu. |
| Quick card and handbook sharing | Quick cards and handbook sections are readable locally but cannot be shared outward. | Users can open a share sheet for a quick card or handbook excerpt with clean local attribution text. |
| Family emergency plan | Notes support `familyPlan`, but there is no guided template creation flow. | Users can create a prefilled family emergency plan note that covers meeting points, contacts, medical info, and pet plans. |
| Related content | Handbook sections already link to related quick cards and sections, while other surfaces have limited cross-links. | Related-content links become more useful across current local content types without adding a new reader or search subsystem. |
| Library filtering | Search results have internal kind filtering, but content-type filtering is not a clear first-class Library affordance. | Library search exposes explicit content-type chips so users can quickly focus on handbook, quick cards, notes, checklists, inventory, or imported knowledge. |

## Pre-Flight Checks

1. Verify the app-service injection seam before adding notification code: `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`, `OSA/App/Bootstrap/OSAApp.swift`, and `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift`.
   *Success signal: there is one clear place to construct, inject, and start a local notification scheduling service before any feature edits begin.*

2. Verify the existing export and share owner surfaces: `OSA/Features/Inventory/InventoryScreen.swift`, `OSA/Features/Checklists/ChecklistRunView.swift`, `OSA/Features/Checklists/ChecklistTemplateDetailView.swift`, `OSA/Features/Notes/NoteDetailView.swift`, `OSA/Features/QuickCards/QuickCardDetailView.swift`, and `OSA/Features/Library/HandbookSectionDetailView.swift`.
   *Success signal: every requested user action has an existing screen that already owns the visible content.*

3. Verify the current family-plan and linked-content data shape in `OSA/Domain/Notes/Models/NoteRecord.swift` and `OSA/Domain/Notes/Repositories/NoteRepositories.swift`.
   *Success signal: the sprint can reuse `NoteType.familyPlan`, `linkedSectionIDs`, and `linkedInventoryItemIDs` without widening the persistence model.*

4. Verify the nearest test anchors up front.
   *Success signal: at least one new unit-test file and one existing UI-test file are identified before implementation starts.*

5. Decide the export-file strategy before coding.
   *Success signal: the plan explicitly chooses file-based sharing for CSV and PDF outputs and string-based sharing for note, quick-card, and handbook text exports.*

## Phased Instructions

### Phase 1: Add Local Inventory Expiry Notifications

1. Create one bounded local notification service under the app layer, for example `OSA/App/Notifications/InventoryExpiryNotificationService.swift`.
   The service should wrap `UNUserNotificationCenter`, expose authorization status, request permission only from an explicit user action, and schedule only local expiry reminders for inventory items.
   *Success signal: notification logic is isolated from feature views and persistence repositories, and no remote-push code or backend dependency is introduced.*

2. Add one small settings helper for alert preferences, for example `OSA/Domain/Settings/InventoryAlertSettings.swift`.
   Store a simple enabled flag plus one lead-time choice such as 7, 30, or 90 days using existing `@AppStorage` patterns.
   *Success signal: notification preferences live in one place and are not scattered across multiple screens.*

3. Wire the new service into `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`, `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift`, and `OSA/App/Bootstrap/OSAApp.swift`.
   Start the service from app bootstrap only after the dependency graph exists, and trigger an initial reschedule from the current inventory repository snapshot on launch.
   *Success signal: the app can refresh notification requests from local data without adding a singleton outside the current dependency pattern.*

4. Reuse `InventoryRepository.itemsExpiringSoon(within:)` for scheduling logic.
   Schedule one local notification per qualifying inventory item, identify requests by stable item ID, and clear or replace outdated requests during reschedule so alerts do not duplicate.
   *Success signal: alert scheduling is derived from existing repository data and remains idempotent across repeated app launches.*

5. Add a bounded notification-control section in `OSA/Features/Settings/SettingsScreen.swift`.
   Include the current authorization state, an enable or disable toggle, a lead-time picker, and copy that explains these are local device notifications only.
   *Success signal: users can opt in and control reminder timing from the current Settings surface without hidden permission prompts.*

6. Refresh expiry reminders from the existing inventory mutation entry points.
   After successful create, update, archive, unarchive, or delete actions in the current inventory flows, request a reschedule from the local notification service instead of altering repository contracts.
   *Success signal: saved inventory changes are reflected in pending reminder requests without adding persistence callbacks or background schedulers.*

### Phase 2: Add Shared Share-Sheet And Export Helpers

1. Add a reusable activity-share wrapper under `OSA/Shared/Components/`, for example `ActivityShareSheet.swift`.
   Follow the same representable style already used by `OSA/Shared/Components/MessageComposeView.swift`.
   *Success signal: feature views can present a system share sheet through one shared component rather than embedding UIKit code repeatedly.*

2. Add small, format-focused export helpers under a bounded shared-support folder, for example `OSA/Shared/Support/Export/`.
   Create only the helpers this sprint needs, such as:
   - `InventoryCSVExporter.swift`
   - `ChecklistPDFExporter.swift`
   - `NoteExportFormatter.swift`
   - `ContentShareFormatter.swift`
   Keep them deterministic, synchronous where practical, and free of SwiftUI dependencies.
   *Success signal: export logic is testable as pure formatting or rendering behavior and does not bloat feature views.*

3. Implement inventory CSV export from `OSA/Features/Inventory/InventoryScreen.swift`.
   Export the currently visible list so the CSV respects the `showArchived` toggle, include stable headers such as `Name`, `Category`, `Quantity`, `Unit`, `Location`, `Notes`, `Expiry Date`, `Reorder Threshold`, `Tags`, `Archived`, `Created At`, and `Updated At`, and present the result through the share sheet.
   *Success signal: a user can export the visible inventory slice as a CSV file without leaving the current inventory screen.*

4. Implement checklist PDF export from both `OSA/Features/Checklists/ChecklistRunView.swift` and `OSA/Features/Checklists/ChecklistTemplateDetailView.swift`.
   Use a text-first PDF layout generated with `UIGraphicsPDFRenderer` or another built-in renderer. Include the checklist title, status or presentation style, timestamps where relevant, item rows, and any context note for active runs.
   *Success signal: both checklist surfaces can generate a readable PDF and pass it into the share sheet without introducing third-party PDF tooling.*

5. Implement note export in `OSA/Features/Notes/NoteDetailView.swift`.
   Add menu actions for `Export as Markdown` and `Export as Plain Text`, using the current stored `bodyMarkdown` and `plainText` fields rather than re-parsing the editor state.
   *Success signal: note export is available from the existing detail action menu and preserves the note's actual stored content.*

6. Implement share-sheet actions in `OSA/Features/QuickCards/QuickCardDetailView.swift` and `OSA/Features/Library/HandbookSectionDetailView.swift`.
   Share a clean text payload containing title, summary or excerpt, and brief local provenance such as `Shared from OSA`. Do not leak hidden IDs, local file paths, or internal tags.
   *Success signal: both reading surfaces expose a simple outward share action without changing their current navigation structure.*

### Phase 3: Add Family Emergency Plan Template And Cross-Links

1. Add a reusable family emergency plan markdown template helper, for example under `OSA/Shared/Support/Export/` or `OSA/Shared/Support/Templates/` if a separate helper is justified.
   The template should include headings for household members, primary and backup meeting points, out-of-area contact, medical needs, pet plans, utility shutoffs, go-bag locations, and important documents.
   *Success signal: the family-plan content is generated from one canonical template instead of being copied into view code.*

2. Add a clear entry point for creating a family emergency plan note from the existing notes flow, most likely in `OSA/Features/Notes/NotesScreen.swift` and `OSA/Features/Notes/NoteEditorView.swift`.
   The created note should default to `NoteType.familyPlan`, prefill the template content, and remain editable like any other note.
   *Success signal: users can create a structured family-plan note without any new persistence model or wizard flow.*

3. Extend current related-content links using existing repositories and link fields rather than a new recommendation engine.
   At minimum:
   - extend `OSA/Features/Library/HandbookSectionDetailView.swift` to include notes linked to the current handbook section when present
   - extend `OSA/Features/Inventory/InventoryItemDetailView.swift` to show linked notes for the current inventory item when present
   - preserve the existing handbook-section and quick-card relationships already in place
   *Success signal: related-content links become more useful across current local content types while staying fully navigable and repository-backed.*

4. Keep cross-links bounded to content with an existing destination view.
   Do not create a new imported-knowledge detail reader in this sprint. If imported knowledge needs to appear in future related-content work, defer it explicitly.
   *Success signal: related-content additions stay small, navigable, and aligned with current screen ownership.*

### Phase 4: Strengthen Library Content-Type Filtering

1. Make content-type filtering in `OSA/Features/Library/SearchResultsView.swift` explicit and persistent.
   Always render chips for the supported result kinds instead of only the kinds present in the current result set, and keep the current selection obvious to the user.
   *Success signal: users can intentionally narrow results to handbook, quick cards, inventory, checklists, notes, or imported sources without needing the first search pass to reveal the chip.*

2. Surface the active content-type filter clearly from `OSA/Features/Library/LibraryScreen.swift` when the search overlay is visible.
   Keep chapter browsing, scenario browse, and topic browse intact. Do not redesign the library root into a new multi-pane explorer.
   *Success signal: Library filtering becomes a first-class refinement of the current search experience rather than an unrelated new navigation layer.*

3. Keep this work local-first.
   Content-type filtering must continue to operate over the current local search service and current repository data only.
   *Success signal: Library filtering remains fast, local, and independent of connectivity.*

### Phase 5: Verification And Quality

1. Add focused unit tests for the new notification service, for example `OSATests/InventoryExpiryNotificationServiceTests.swift`.
   Use a fake notification-center adapter so you can verify authorization handling, idempotent rescheduling, lead-time selection, and request cancellation without relying on live OS notification state.
   *Success signal: notification scheduling behavior is testable deterministically and does not depend on manual simulator inspection for core correctness.*

2. Add focused export and formatting tests, for example:
   - `OSATests/InventoryCSVExporterTests.swift`
   - `OSATests/ChecklistPDFExporterTests.swift`
   - `OSATests/NoteExportFormatterTests.swift`
   *Success signal: CSV headers and rows, checklist PDF content assembly, and note export strings are all verified with deterministic assertions.*

3. Extend the nearest existing repository or feature tests only where they directly support Sprint 5 behavior.
   Candidate anchors include `OSATests/InventoryRepositoryTests.swift` and `OSATests/NoteRepositoryTests.swift`.
   *Success signal: the sprint adds coverage for real new behavior without reopening unrelated repository contracts or bloating broad suites.*

4. Extend focused UI coverage in `OSAUITests/OSAContentAndInputTests.swift` and `OSAUITests/OSAAccessibilitySmokeTests.swift`.
   Cover at minimum:
   - visibility of the inventory export action
   - visibility of checklist export actions
   - visibility of note export actions
   - visibility of quick-card and handbook share actions
   - visibility of the family-plan creation entry point
   - visibility and selection behavior of Library content-type filters
   *Success signal: the new user-facing controls are wired into the visible app and remain accessible to UI automation.*

5. Run a simulator build after implementation completes.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
```

   *Success signal: the project builds successfully for the standard simulator destination.*

1. Run a focused test pass for Sprint 5 logic and visible UI wiring.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test -only-testing:OSATests/InventoryExpiryNotificationServiceTests -only-testing:OSATests/InventoryCSVExporterTests -only-testing:OSATests/ChecklistPDFExporterTests -only-testing:OSATests/NoteExportFormatterTests -only-testing:OSATests/InventoryRepositoryTests -only-testing:OSATests/NoteRepositoryTests -only-testing:OSAUITests/OSAContentAndInputTests -only-testing:OSAUITests/OSAAccessibilitySmokeTests
```

   *Success signal: the focused unit and UI coverage for Sprint 5 passes, or the exact blocker is reported.*

1. Run first-party security scanning if `snyk` is available.

```bash
cd /Users/etherealogic-mac-mini/Dev/OSA && snyk code test --path="$PWD"
```

   *Success signal: Snyk Code completes, or the exact environment blocker is reported as unverified.*

## Guardrails

<guardrails>
- Do not add remote push notifications, backend jobs, cloud sync, or account requirements.
- Do not add barcode scanning, camera capture, attachments, or photo export in this sprint.
- Do not create a new persistence model for family plans, exports, or reminder state unless a concrete blocker makes the current note and settings models insufficient.
- Do not widen repository protocols just to trigger notifications; keep scheduling above the repository layer.
- Do not automatically export, upload, or share user data. Every outward data flow must be explicitly user-initiated.
- Do not redesign Library navigation, checklist architecture, or notes CRUD while adding these features.
- Do not add third-party PDF, CSV, sharing, or notification libraries.
- Do not claim background reminder reliability beyond what the implemented local notification scheduling actually guarantees.
- Keep imported-knowledge related-content support out of this sprint unless a navigable local detail surface already exists.
</guardrails>

## Verification Checklist

- [ ] Inventory expiry alerts are local-only, user-opt-in, and configurable for 7, 30, or 90 days.
- [ ] Notification scheduling reuses existing inventory repository data and avoids duplicate pending requests.
- [ ] Inventory can be exported as CSV from the current inventory surface.
- [ ] Checklist templates and active runs can be exported as PDF.
- [ ] Notes can be exported as markdown and plain text.
- [ ] Quick-card and handbook detail screens expose share-sheet actions with clean local attribution text.
- [ ] Users can create a prefilled family emergency plan note without a new persistence model.
- [ ] Related-content links surface additional navigable local content without introducing a new reader.
- [ ] Library search exposes explicit content-type filtering.
- [ ] Focused build and test commands were run, or blockers were reported explicitly.
- [ ] Snyk Code was run if available, or the blocker was reported as unverified.

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| Notification authorization is denied or restricted | Keep the feature usable in-app, show the current permission state in Settings, and avoid repeated unsolicited prompts. |
| Inventory reminder rescheduling creates duplicates | Use stable notification request IDs keyed by inventory item ID and replace existing requests during every reschedule pass. |
| PDF export layout becomes brittle across template and run surfaces | Fall back to a text-first multi-page PDF with simple headings and rows rather than adding a complex rendering system. |
| CSV export breaks because fields contain commas or newlines | Escape fields using standard CSV quoting rules and add focused formatter tests for commas, quotes, and line breaks. |
| Plain-text note export strips too much information | Use the stored `plainText` field as the source of truth for plain-text export rather than ad hoc markdown stripping inside the detail view. |
| Family-plan template creation starts to require a custom schema | Stop and keep the first pass as a prefilled `NoteType.familyPlan` note; defer structured plan data to a separate prompt. |
| Related-content work starts to require imported-knowledge reading UI | Defer imported-knowledge destinations and keep the Sprint 5 cross-links limited to surfaces that already have destination views. |
| Focused tests cannot run because full Xcode or simulator services are unavailable | Report the exact command and failure mode and mark the affected verification as unverified rather than passed. |

## Out Of Scope

- Remote push notifications, Live Activities, widgets, or background refresh for reminders
- Barcode or QR scanning, camera-based item entry, or photo attachments for inventory
- Broad backup, sync, collaboration, or household sharing flows
- Rich imported-knowledge reading views or imported-knowledge sharing/export flows
- Supply readiness scoring, low-stock reminders, or broader Home dashboard redesign
- New checklist or notes data models beyond the bounded template and export work

## Alternative Solutions

1. **If notification injection feels too heavy for the first pass:** keep the app-layer service but expose it only through `SettingsScreen` and app launch plus explicit inventory save points. This preserves correctness without introducing repository observers or background scheduling complexity.
2. **If PDF export from both checklist surfaces proves too wide for one slice:** implement the shared PDF renderer first and wire it to `ChecklistRunView.swift`, then add `ChecklistTemplateDetailView.swift` only if the renderer remains small and deterministic.
3. **If Library-wide content-type filtering starts to churn root navigation:** keep the new filter UX scoped to `SearchResultsView.swift` and expose it more clearly during search without changing `LibraryScreen` browse sections.

## Report Format

<report-format>
1. **Scope completed:** which Sprint 5 capabilities were implemented versus explicitly deferred.
2. **Files changed:** grouped by app service, shared support, feature UI, and tests.
3. **Notification behavior:** authorization model, lead-time options, and how rescheduling is triggered.
4. **Export and share behavior:** which screens gained CSV, PDF, markdown, plain-text, or share-sheet actions.
5. **Family-plan and cross-link behavior:** how the template is created and where related-content links appear.
6. **Verification evidence:** exact build, test, and security commands run with pass, fail, or unverified status.
7. **Blockers or follow-up:** concrete constraints, if any, separated from implemented facts.
</report-format>
