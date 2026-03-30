Developer: # Sprint 11 Advanced Device Capabilities Enhanced Prompt

**Date:** 2026-03-29  
**Prompt Level:** Level 2  
**Prompt Type:** Feature  
**Complexity Classification:** Complex  
**Complexity Justification:** Sprint 11 extends existing inventory, settings, secure-storage, import, and search seams with camera-driven capture, on-device recognition, file-backed local media, encrypted document storage, and curated knowledge-pack installation. The work spans multiple domain, persistence, networking, UI, permissions, and test surfaces while preserving offline-first behavior, privacy boundaries, and current navigation structure.

## Inputs Consulted

| Source | Key takeaways for this task |
| --- | --- |
| Source prompt | Sprint 11 must leverage on-device hardware and secure storage for image recognition, barcode or QR inventory scanning, inventory photo documentation, an encrypted document vault, and downloadable curated knowledge packs. |
| `AGENTS.md` | Follow Plan -> Act -> Verify -> Report; preserve feature, domain, persistence, retrieval, and networking boundaries; keep verification evidence explicit; mark blocked checks as `unverified`. |
| `DIRECTIVES.md` | Keep OSA offline-first, grounded, privacy-preserving, and verification-backed; do not widen sensitive scopes or mix SwiftData into feature-layer code. |
| `.github/instructions/codacy.instructions.md` | The repo is `Org-EthereaLogic/OSA`; run Codacy analysis when tooling is available. |
| `docs/sdlc/04-information-architecture-and-ux-flows.md` | Do not add a new primary tab; extend existing Inventory, Settings, and More navigation seams. |
| `docs/sdlc/05-technical-architecture.md` | Reuse current inventory, import, keychain, and search infrastructure; do not push binary assets directly through feature views or introduce broad new subsystems. |
| `docs/sdlc/06-data-model-local-storage.md` | Keep editorial content, user state, and binary/file-backed assets separated; use SwiftData metadata plus file-backed stores where appropriate. |
| `docs/sdlc/07-sync-connectivity-and-web-knowledge-refresh.md` | Online behavior remains optional; imported or downloaded knowledge must become local, validated, and searchable before Ask can use it. |
| `docs/sdlc/10-security-privacy-and-safety.md` | Sensitive records stay on-device; secrets belong in Keychain; no hidden uploads; private data must not silently flow into Ask, Spotlight, widgets, or web requests. |
| `docs/sdlc/11-quality-strategy-test-plan-and-acceptance.md` | Add focused repository, security, import, and UI verification; keep camera and device-only logic behind thin adapters with testable pure logic. |
| `docs/reference/2026-03-28-feature-adoption-recommendations.md` | The repo already recommends barcode scanning, photo documentation, a document vault, and knowledge packs as future bounded follow-ons. |
| `OSA/Features/Inventory/InventoryItemFormView.swift` | Inventory item creation and editing already provide the main user seam for capture, scan, and suggestion entry points. |
| `OSA/Networking/Discovery/BraveSearchClient.swift` | `BraveSearchCredentialStore` is the current Keychain storage precedent and should shape any secure-key handling for the vault. |
| `OSA/Persistence/SeedImport/SeedContentLoader.swift` and `SeedContentImporter.swift` | Seed-pack validation, manifest hashing, and deterministic local import already exist and should be reused for curated downloadable knowledge packs. |

## Classification Summary

- Core intent: add bounded on-device capture and secure local storage capabilities that make inventory, personal preparedness records, and optional curated content more useful without turning OSA into a cloud service, generic document manager, or unrestricted scanner app.
- In scope: on-device barcode or QR scanning for inventory entry, on-device text or label recognition to prefill inventory fields, local inventory photo attachments, a secure encrypted document vault, curated downloadable knowledge packs, permissions and file-protection updates, and focused tests.
- Out of scope: cloud sync, server-side OCR, generalized product lookup, automatic remote enrichment from unknown domains, Ask access to private vault contents, or any new always-on background dependency.

## Key Constraints

- Keep all new core behavior useful offline after local capture or download completes.
- Keep `SwiftData` and file-system details out of `OSA/Features/`.
- Keep private vault content out of Ask, Spotlight, widgets, exports, and trusted-source import flows unless a later prompt explicitly widens that boundary.
- Reuse `LocalInventoryCompletionService` for conservative field suggestion when scan or OCR text can help; do not create a second free-form AI path.
- Reuse `SeedContentLoader`, `SeedContentImporter`, and search-index rebuild seams for curated pack installation instead of inventing a parallel content system.
- Keep navigation bounded: extend `Inventory`, `Settings`, and the existing More list instead of adding a new primary tab.
- Store secrets or encryption keys in Keychain with a device-only accessibility class; do not store raw keys in SwiftData or `UserDefaults`.
- Keep binary photos and documents file-backed; persist metadata and stable identifiers separately.
- Run `xcodegen generate` if `project.yml` changes and run the matching build or test commands afterward.
- Run `snyk code test --path="$PWD"` if available because this sprint adds new first-party capture and security-sensitive code.

## Mission Statement

Implement Sprint 11 by extending OSA with offline on-device capture, recognition, secure document storage, and curated knowledge-pack downloads while preserving local-first privacy, current navigation seams, and the grounded assistant boundary.

&lt;technical_context&gt;

## Technical Context

Sprint 11 should build directly on four seams that already exist in the repository:

1. **Inventory capture should extend the existing inventory flow, not bypass it.** `InventoryScreen`, `InventoryItemFormView`, and `InventoryItemDetailView` already own item creation and review. `LocalInventoryCompletionService` already converts partial text into conservative inventory suggestions. The cleanest design is to feed barcode payloads and recognized text into that existing suggestion path rather than invent a second interpretation engine.
2. **Secure storage already has a concrete precedent.** `BraveSearchCredentialStore` proves the repo is already willing to store small secrets in Keychain with device-only accessibility. Sprint 11 should reuse that posture for vault encryption keys rather than placing secrets in SwiftData, files, or app settings.
3. **Downloaded knowledge should reuse OSA's content-pack and import validation logic.** `SeedContentLoader` and `SeedContentImporter` already verify manifest hashes, record counts, and schema shape for bundled content. Curated knowledge packs should behave like remote seed packs with catalog metadata, integrity validation, local install state, and search-index rebuilds after local commit.
4. **Private binary content needs stronger separation than editorial content.** Inventory photos and vault documents should not be stored as SwiftData blobs. Use SwiftData only for metadata and file references, and keep actual photo or encrypted document bytes in app-owned directories under `Application Support` with explicit file-protection policy.

The smallest coherent Sprint 11 design is therefore:

1. Extend inventory with camera or picker-based capture, barcode or QR decoding, and optional local photo attachments.
2. Use on-device `VisionKit` or `Vision` seams only for barcode detection and bounded text recognition that supports item-name, quantity, unit, and label extraction. Do not attempt broad object recognition or internet product matching.
3. Introduce a dedicated **Document Vault** domain with stronger privacy rules than ordinary inventory media: encrypted file bytes, metadata in SwiftData, unlock gating via `LocalAuthentication`, and a More-list destination rather than a new primary tab.
4. Introduce curated **Knowledge Packs** as approved downloadable pack bundles managed from `Settings`' existing knowledge-discovery area, installed locally only after integrity validation, then surfaced through existing Library, search, and Ask seams.
5. Keep Ask, widgets, Spotlight, and export flows intentionally blind to vault content during this sprint.

**Rationale:** this approach adds real device-capability value while respecting the app's current architecture, minimizes risky cross-cutting changes, and keeps private content separate from editorial and assistant-usable corpora.

&lt;/technical_context&gt;

## Problem-State Table

| Aspect | Current State | Target State |
| --- | --- | --- |
| Inventory capture | Inventory items are entered manually. | Users can scan barcodes or QR codes, capture or import photos, and use on-device recognition to prefill fields conservatively. |
| Inventory media storage | Inventory items have no attachment support. | Inventory items can reference locally stored photos through metadata plus file-backed storage. |
| Image recognition | No on-device image-recognition seam exists for inventory or documents. | Bounded on-device barcode and text recognition exists with deterministic fallback to manual entry. |
| Sensitive document storage | Important documents are only referenced in content and notes. | A dedicated encrypted document vault stores sensitive scans or photos locally with stronger access controls. |
| Knowledge expansion | Discovery imports individual trusted-source articles; bundled downloadable topic packs do not exist. | Curated topic packs can be downloaded from approved endpoints, verified locally, installed into the corpus, and used offline afterward. |
| Security boundary | Keychain is used for the optional Brave API key only. | Keychain-backed vault keys and stronger file-protection rules exist for private document storage without widening data exposure. |
| Navigation and scope | Inventory, Settings, and More surfaces exist; no document-vault or pack-management surface exists. | Inventory gains capture affordances, More gains a bounded vault destination, and Settings gains pack-management controls without adding a new primary tab. |

&lt;preflight_checks&gt;

## Pre-Flight Checks

1. Verify the existing seams that Sprint 11 must extend.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && test -f OSA/Features/Inventory/InventoryItemFormView.swift && test -f OSA/Features/Settings/SettingsScreen.swift && test -f OSA/Networking/Discovery/BraveSearchClient.swift && test -f OSA/Persistence/SeedImport/SeedContentLoader.swift && echo "sprint-11 seams present"
   ```

   *Success: the command prints `sprint-11 seams present`.*

2. Confirm Sprint 11 remains additive by checking that barcode, vault, and knowledge-pack seams are not already implemented.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && rg -n "Barcode|DataScanner|VisionKit|DocumentVault|KnowledgePack|NSCameraUsageDescription" OSA project.yml
   ```

   *Success: matches are limited to references, prompts, or adjacent infrastructure rather than an existing implementation slice.*

3. Verify the current Inventory, keychain, and import seams that the sprint should reuse.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && rg -n "InventoryItemFormView|InventoryRepository|BraveSearchCredentialStore|SeedContentImporter|KnowledgeDiscoveryCoordinator|ImportedKnowledgeImportPipeline" OSA
   ```

   *Success: the command identifies the concrete files and symbols named in this prompt.*

4. Check whether new permissions or resource-path changes will require project regeneration.

   ```bash
   cd /Users/etherealogic-mac-mini/Dev/OSA && rg -n "NSCameraUsageDescription|NSPhotoLibraryUsageDescription|NSPhotoLibraryAddUsageDescription|Resources/Media|Resources/SeedContent" project.yml
   ```

   *Success: you know whether `project.yml` must be updated before implementation begins.*

&lt;/preflight_checks&gt;

## Phased Instructions

### Phase 1: Freeze The Smallest Coherent Sprint 11 Design

1. Keep device capture inside the existing inventory flow.

   Add scan, OCR, and photo-entry affordances to `OSA/Features/Inventory/InventoryItemFormView.swift` and `OSA/Features/Inventory/InventoryItemDetailView.swift` rather than inventing a separate capture feature.

   *Success: the implementation plan routes all inventory capture back into the existing create or edit form.*

2. Keep binary assets file-backed and metadata-backed.

   Store only stable metadata, file identifiers, capture timestamps, and recognition summaries in SwiftData. Keep photo bytes and encrypted document bytes in app-owned directories under `Application Support`.

   *Success: no new SwiftData model stores full-size image or document blobs directly.*

3. Freeze the stronger privacy boundary for vault content before adding UI.

   Document-vault records must remain excluded from Ask retrieval, Spotlight, widgets, exports, and trusted-source import flows for this sprint.

   *Success: the sprint scope names vault content as local-only and non-assistant-usable.*

4. Keep curated knowledge packs separate from arbitrary web imports.

   Restrict downloadable packs to approved OSA-owned or explicitly allowlisted endpoints with catalog metadata, integrity verification, and local install state. Do not accept arbitrary URLs or user-sideloaded archives in Sprint 11.

   *Success: the implementation plan names a bounded catalog-driven pack flow, not a general package manager.*

### Phase 2: Extend Domain Contracts And Local Storage

1. Add bounded inventory-capture value types under `OSA/Domain/Inventory/Models/`.

   Create a focused model file such as `InventoryCaptureModels.swift` with the smallest needed supporting types, for example:

   - `InventoryBarcodeScan`
   - `InventoryPhotoAttachment`
   - `RecognizedInventoryText`

   Extend `OSA/Domain/Inventory/Models/InventoryItem.swift` only with metadata needed to associate photos and a captured barcode with the item.

   *Success: inventory capture data has typed domain models and `InventoryItem` stays small and persistence-agnostic.*

2. Add narrow repository contracts for binary inventory media.

   Add a focused protocol such as `InventoryPhotoStore` under `OSA/Domain/Inventory/Repositories/` and implement it under `OSA/Persistence/` so file-system writes never leak into feature views.

   *Success: feature code requests photo save/load/delete operations through a protocol rather than directly touching `FileManager`.*

3. Add a dedicated document-vault domain slice.

   Add new files such as:

   - `OSA/Domain/Documents/Models/DocumentVaultEntry.swift`
   - `OSA/Domain/Documents/Repositories/DocumentVaultRepository.swift`

   Minimum metadata should include title, category, capture source, created or updated timestamps, encrypted-file identifier, optional OCR summary, and vault-lock state if needed.

   *Success: vault metadata has a first-class domain contract separate from inventory, notes, and imported knowledge.*

4. Implement vault metadata persistence plus encrypted file storage.

   Add a new SwiftData metadata model and repository implementation, plus a file-backed encrypted store using `CryptoKit` for payload encryption and Keychain-backed key storage patterned after `BraveSearchCredentialStore`.

   Recommended files:

   - `OSA/Persistence/SwiftData/Models/PersistedDocumentVaultEntry.swift`
   - `OSA/Persistence/SwiftData/Repositories/SwiftDataDocumentVaultRepository.swift`
   - `OSA/Persistence/FileStorage/EncryptedDocumentVaultStore.swift`
   - `OSA/Persistence/Security/DocumentVaultKeyStore.swift`

   *Success: vault bytes are encrypted before disk write, and the encryption key never lives in SwiftData or `UserDefaults`.*

5. Add knowledge-pack catalog and install-state models.

   Introduce a compact model slice such as:

   - `OSA/Domain/Content/Models/KnowledgePackModels.swift`
   - `OSA/Persistence/SwiftData/Models/PersistedKnowledgePackInstallState.swift`

   Track pack identifier, version, install status, installed-at timestamp, content hash, and last refresh state separately from bundled `PersistedSeedContentState`.

   *Success: remote pack installation state is explicit and does not overload bundled-seed bookkeeping.*

6. Wire new repositories and services through the app bootstrap layer.

    Extend `OSA/App/Bootstrap/AppModelContainer.swift`, `OSA/App/Bootstrap/Dependencies/AppDependencies.swift`, and `OSA/App/Bootstrap/Dependencies/RepositoryEnvironment.swift` with the new inventory-photo, document-vault, and knowledge-pack dependencies.

    *Success: all new services are injected through the existing dependency seams and are preview/test swappable.*

### Phase 3: Add Device-Powered Inventory And Vault UX

1. Add thin scanner and recognition adapters in shared or feature support code.

    Use `DataScannerViewController` or a thin `VisionKit` wrapper when available for live barcode capture, and provide a still-image recognition fallback using `Vision` for unsupported devices or simulators. Keep these adapters narrow and push interpretation logic into testable pure Swift helpers.

    *Success: capture UI is hardware-aware, but recognition interpretation remains unit-testable without a live camera.*

2. Update the inventory form to support scan and photo capture.

    Extend `OSA/Features/Inventory/InventoryItemFormView.swift` with actions such as `Scan Code`, `Capture Photo`, `Import Photo`, and `Recognize Label`. Feed recognized text and barcode payloads into `LocalInventoryCompletionService` or equivalent conservative merge logic so suggested fields never overwrite deliberate user input silently.

    *Success: users can prefill inventory fields from on-device capture while retaining manual control.*

3. Update the inventory detail surface to display local media and scan metadata.

    Extend `OSA/Features/Inventory/InventoryItemDetailView.swift` to show attached photos, barcode text or symbology, and last-recognized metadata. Add delete or replace flows that clean up file-backed attachments safely.

    *Success: item detail presents local photos and scan context without exposing raw file-system paths.*

4. Add a bounded Document Vault surface in the existing More navigation.

    Add a More-list destination and supporting screens such as `DocumentVaultScreen`, `DocumentVaultDetailView`, and `DocumentVaultCaptureView`. Require a local unlock step using `LocalAuthentication` when opening the vault or decrypting a file preview.

    *Success: the vault is reachable without a new primary tab and gated behind an explicit local-auth flow.*

5. Keep vault OCR bounded and privacy-safe.

    If OCR is implemented, use it only for local title suggestions, category hints, and in-vault filtering. Do not index OCR text into global search or Ask during Sprint 11.

    *Success: OCR improves local vault usability without widening assistant or system-surface exposure.*

### Phase 4: Add Curated Knowledge-Pack Download And Install

1. Add a knowledge-pack catalog client and downloader under `OSA/Networking/`.

    Recommended files:

    - `OSA/Networking/Packs/KnowledgePackCatalogClient.swift`
    - `OSA/Networking/Packs/KnowledgePackDownloadCoordinator.swift`

    The catalog should come only from approved hosts, expose pack metadata and hashes, and support manual install or update from `SettingsScreen`'s existing knowledge-discovery area.

    *Success: pack discovery is catalog-driven, allowlisted, and user-initiated.*

2. Reuse the existing content-pack validation and import seams for local commit.

    After download, unpack the pack into a temporary directory, validate manifest hashes and counts through `SeedContentLoader`, import through `SeedContentImporter`, then rebuild or incrementally extend the search index so Library and Ask can see the new local records.

    *Success: newly installed packs become available only after successful local validation and import.*

3. Add connectivity-aware install state and recovery.

    Use `ConnectivityService` and, when useful, `PendingOperation`-style persisted state so interrupted downloads or updates can resume or fail visibly without corrupting existing installed packs.

    *Success: a failed or interrupted pack install leaves the prior local corpus intact and the pending state understandable.*

4. Update `OSA/Features/Settings/SettingsScreen.swift` for pack management.

    Extend the existing knowledge-discovery section with a `Knowledge Packs` subsection showing available packs, installed version status, update actions, and local-only messaging.

    *Success: pack install and update controls live beside other optional online enrichment controls, with explicit offline messaging.*

### Phase 5: Verification, Security, And Regression Coverage

1. Add focused unit and repository tests before relying on device-only checks.

    Minimum expected test coverage:

    - extend `OSATests/InventoryRepositoryTests.swift` for photo and barcode metadata round-trips
    - add `OSATests/InventoryPhotoStoreTests.swift`
    - add `OSATests/DocumentVaultRepositoryTests.swift`
    - add `OSATests/DocumentVaultCryptoServiceTests.swift`
    - add `OSATests/KnowledgePackInstallTests.swift` or equivalent catalog/import tests
    - extend `OSATests/SearchIndexRebuilderTests.swift` if knowledge-pack installation changes searchable corpus composition

    Keep live camera wrappers thin; unit-test the pure interpretation and merge logic rather than the framework UI.

    *Success: the high-risk persistence, crypto, and import paths are covered without depending entirely on live device camera automation.*

2. Add narrow UI coverage where deterministic.

    Extend `OSAUITests/OSAContentAndInputTests.swift` or the nearest existing UI suite for inventory-form affordance visibility, document-vault navigation and lock state, and knowledge-pack settings affordance visibility. Use non-camera fallbacks for automation rather than trying to exercise live camera capture in CI.

    *Success: the new surfaces have smoke coverage even when camera hardware is unavailable in CI.*

3. Regenerate the project if permissions or resource paths changed.

    If `project.yml` changed, run:

    ```bash
    cd /Users/etherealogic-mac-mini/Dev/OSA && xcodegen generate
    ```

    *Success: `OSA.xcodeproj` is regenerated without error and remains in sync with the manifest.*

4. Run the focused build and full test pass.

    ```bash
    cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
    ```

    *Success: the app target builds without errors.*

    ```bash
    cd /Users/etherealogic-mac-mini/Dev/OSA && xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
    ```

    *Success: the full automated suite passes, or exact blockers are reported as `unverified`.*

5. Run the security scan for the new first-party code if tooling is available.

    ```bash
    cd /Users/etherealogic-mac-mini/Dev/OSA && snyk code test --path="$PWD"
    ```

    *Success: the scan completes without new unresolved high-severity findings, or the exact blocker is reported.*

&lt;guardrails&gt;

## Guardrails

- **Forbidden:** Uploading inventory photos, vault documents, OCR text, or scan payloads to third-party services.
- **Forbidden:** Using unknown hosts, arbitrary URLs, or user-supplied package archives for knowledge-pack installation.
- **Forbidden:** Letting Ask, Spotlight, widgets, or exports read vault content in Sprint 11.
- **Forbidden:** Storing raw encryption keys in SwiftData, `UserDefaults`, seed packs, or plaintext files.
- **Forbidden:** Creating a new bottom-tab destination for the vault or pack management.
- **Required:** Use on-device frameworks only for barcode or text recognition; keep manual-entry fallback available.
- **Required:** Keep binary asset bytes out of SwiftData and behind repository or file-store seams.
- **Required:** Use integrity checks before any downloaded knowledge pack becomes part of the local corpus.
- **Required:** Add matching verification for each new persistence, crypto, or import behavior.
- **Budget:** Prefer the smallest coherent implementation that lands camera capture, secure storage, and pack install without turning Sprint 11 into a generic media-management platform.

&lt;/guardrails&gt;

&lt;verification_checklist&gt;

## Verification Checklist

- [ ] Inventory items can be created or edited from manual input without any camera dependency regression.
- [ ] Barcode or QR scanning can prefill inventory fields using on-device capture or still-image fallback.
- [ ] Inventory photos persist locally across relaunch and can be removed cleanly.
- [ ] Document-vault files are encrypted before disk write and require explicit local unlock to view.
- [ ] Vault content remains excluded from Ask, Spotlight, widgets, and generic export flows.
- [ ] Curated knowledge packs install only after allowlist and integrity validation.
- [ ] Installed packs become locally searchable and Ask-usable only after successful local commit.
- [ ] `project.yml` changes, if any, are followed by `xcodegen generate`.
- [ ] Build succeeds.
- [ ] Automated tests pass, or blocked checks are explicitly reported as `unverified`.
- [ ] `snyk code test --path="$PWD"` is run when available, or the blocker is reported explicitly.

&lt;/verification_checklist&gt;

&lt;error_handling&gt;

## Error Handling Table

| Error Condition | Resolution |
| --- | --- |
| Live scanner unavailable on simulator or unsupported hardware | Fall back to still-image import plus `Vision` recognition, and preserve manual entry as a first-class path. |
| Camera permission denied | Keep manual entry and photo-import fallback available; present a clear local-only explanation and Settings deep-link guidance. |
| Keychain write or read fails for vault key storage | Abort vault file creation or decrypt, surface an explicit local error, and avoid writing plaintext fallback files. |
| Local authentication unavailable or fails repeatedly | Keep the vault locked, allow retry, and do not silently downgrade to unprotected document access. |
| Downloaded pack hash or manifest validation fails | Reject the pack, delete temporary files, preserve the current local corpus, and report the failure clearly. |
| Pack download interrupted by connectivity loss | Persist pending state, keep installed content unchanged, and offer retry when connectivity returns. |
| `project.yml` changes but `OSA.xcodeproj` is stale | Run `xcodegen generate` before build or test and report the command result. |
| `xcodebuild` fails because full Xcode is unavailable | Report the exact failure mode and keep build or test claims `unverified`. |
| `snyk` is unavailable | Report the exact command blocker and keep the security verification claim `unverified`. |

&lt;/error_handling&gt;

&lt;out_of_scope&gt;

## Out Of Scope

- Cloud backup, sync, or sharing for inventory media, vault documents, or installed packs.
- Remote OCR, product lookup APIs, or barcode-driven commercial catalog matching.
- General image classification beyond bounded barcode or text-recognition support.
- Adding photo attachments to notes, checklists, widgets, Spotlight, or Siri entities.
- Exposing vault contents to Ask, Library global search, or trusted-source article import.
- Arbitrary package sideloading, third-party pack marketplaces, or user-authored pack creation.
- Background auto-refresh for knowledge packs beyond the smallest explicit update mechanism needed for Sprint 11.

&lt;/out_of_scope&gt;

&lt;alternative_solutions&gt;

## Alternative Solutions

1. **Live scanner first, still-image fallback second**

   - **Primary:** use `DataScannerViewController` where supported and fall back to still-image `Vision` analysis.
   - **Pros:** best on-device UX on modern hardware while keeping simulator and older-device coverage.
   - **Cons:** requires dual-path handling.

2. **NSFileProtection-only vault storage**

   - **Fallback:** rely only on file-protection classes without explicit payload encryption.
   - **Pros:** smaller implementation surface.
   - **Cons:** weaker security posture for the most sensitive user documents and less explicit local-auth control.
   - **Decision:** do not choose this unless CryptoKit- plus-Keychain-based encryption proves technically blocked.

3. **Knowledge packs as imported-knowledge article bundles**

   - **Fallback:** transform packs into imported-knowledge documents instead of remote seed packs.
   - **Pros:** reuses more of the current article import pipeline.
   - **Cons:** poorer fit for structured handbook, quick-card, and field-reference content; weaker editorial-pack semantics.
   - **Decision:** prefer remote seed-pack-style installation unless the content is truly article-only.

&lt;/alternative_solutions&gt;

&lt;report_format&gt;

## Report Format

When the implementation is complete, report using this structure:

1. **Scope completed:** which Sprint 11 slices landed and which were deferred.
2. **Files changed:** grouped by domain, persistence, UI, networking, and tests.
3. **Privacy and security posture:** where keys live, where file bytes live, and what remained excluded from Ask or system surfaces.
4. **Verification evidence:** exact commands run, pass/fail status, and any `unverified` blockers with dates.
5. **Known limitations:** unsupported-device fallbacks, deferred work, or non-blocking follow-ups.

&lt;/report_format&gt;
