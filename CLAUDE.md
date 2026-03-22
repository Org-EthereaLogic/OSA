# CLAUDE.md — OSA Quick Reference

OSA is an offline-first iPhone preparedness app with a grounded local assistant, local-first data storage, and optional trusted-source import that only becomes usable after local persistence and attribution.

## Command Shortlist

| Command | Use |
| --- | --- |
| `xcodegen generate` | Regenerate `OSA.xcodeproj` from `project.yml` after project-structure changes |
| `xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build` | Build the app when full Xcode is installed |
| `xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test` | Run tests when a test target exists and full Xcode is installed |
| `snyk code test --path="$PWD"` | Run Snyk Code against the repository when first-party code or security-sensitive config changes |
| `git status --short` | Inspect local workspace changes before and after edits |

## Product Contract

- The app is iPhone-first, offline-first, and local-first.
- Core top-level surfaces are `Home`, `Library`, `Ask`, `Inventory`, `Checklists`, `Quick Cards`, `Notes`, and `Settings`.
- The assistant is not a general chatbot and may answer only from approved local sources and allowed app data.
- Imported web knowledge is usable only after it is persisted locally with provenance and appropriate review state.
- When generative capability is unavailable, the app must degrade to extractive or search-first behavior instead of inventing answers.

## Current Platform Baseline

- App target: `OSA`
- Deployment target: iOS 18.0
- Swift version: 6.0
- Persistence recommendation: SwiftData in `OSA/Persistence` behind repository protocols in `OSA/Domain`
- Architecture shape: single Xcode app target with disciplined folder boundaries

## Verification Notes

- `xcodebuild` requires full Xcode, not only Command Line Tools.
- If `xcodebuild` fails because the active developer directory points at `/Library/Developer/CommandLineTools`, report the blocker and keep build or test claims unverified.
- Run `xcodegen generate` whenever target structure changes so `project.yml` and `OSA.xcodeproj` do not drift.

## File Map

| Path | Purpose |
| --- | --- |
| `project.yml` | Canonical XcodeGen manifest for the project |
| `OSA.xcodeproj` | Generated Xcode project |
| `OSA/App/` | App lifecycle, composition root, and navigation shell |
| `OSA/Features/` | SwiftUI feature surfaces |
| `OSA/Domain/` | Domain models, repository protocols, and use-case boundaries |
| `OSA/Persistence/` | SwiftData models, mappings, migrations, and repository implementations |
| `OSA/Assistant/` | Assistant policy, prompt shaping, and model adapters |
| `OSA/Retrieval/` | Local search, chunking, ranking, and citation packaging |
| `OSA/Networking/` | Trusted-source search, download, normalization, and refresh logic |
| `OSA/Shared/` | Reusable UI and cross-cutting helpers |
| `docs/` | Canonical SDLC, product, architecture, quality, safety, and release docs |
| `docs/adr/` | Accepted architecture decisions |

## Reading Order

Start here before making architectural or policy claims:

1. `CONSTITUTION.md`
2. `DIRECTIVES.md`
3. `AGENTS.md`
4. `docs/00-doc-suite-index.md`
5. `docs/05-technical-architecture.md`
6. `docs/06-data-model-local-storage.md`
7. `docs/08-ai-assistant-retrieval-and-guardrails.md`
8. `docs/10-security-privacy-and-safety.md`
9. `docs/11-quality-strategy-test-plan-and-acceptance.md`

## Notes

- Prefer folder and protocol boundaries over early package splitting.
- Keep SwiftData details out of feature code.
- Trust current code over stale prose, but update stale prose quickly when code becomes the new source of truth.
- Reference repos used for governance style only: `/Volumes/etherealogic-2/Dev/FailLens_Core/` and `/Volumes/etherealogic-2/Dev/ADWS_PRO/`.
