# Lantern

[![Codacy Badge](https://app.codacy.com/project/badge/Grade/789f3082553145829e16ff16dda1f104)](https://app.codacy.com?utm_source=gh&utm_medium=referral&utm_content=&utm_campaign=Badge_grade)
[![codecov](https://codecov.io/gh/Org-EthereaLogic/OSA/branch/main/graph/badge.svg)](https://codecov.io/gh/Org-EthereaLogic/OSA)

Lantern is an offline-first iPhone preparedness app with a grounded local assistant, local-first privacy, and optional trusted-source enrichment that only becomes usable after local persistence and attribution.

The internal repository, Xcode project, target, and scheme still use `OSA` for now. Build and test commands therefore still reference `OSA.xcodeproj` and the `OSA` scheme.

## Source Precedence

Use sources in this order when making product, architecture, or policy claims:

1. `docs/sdlc/*.md` and accepted ADRs under `docs/adr/`
2. Root governance docs: `CONSTITUTION.md`, `DIRECTIVES.md`, `AGENTS.md`, `CLAUDE.md`
3. Current code reality under `OSA/`, `OSATests/`, and `OSAUITests/`
4. Task prompts or issue briefs being executed
5. Reference repositories listed in `AGENTS.md` for style and organization only

## Quickstart

```bash
xcodegen generate
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' build
xcodebuild -project OSA.xcodeproj -scheme OSA -destination 'platform=iOS Simulator,name=iPhone 16' test
```

## Repository Layout

- `OSA/` — app source, organized by app shell, feature surfaces, domain boundaries, persistence, retrieval, assistant, networking, shared UI, and resources
- `OSATests/` — unit-test target scaffold and app-facing smoke tests
- `OSAUITests/` — UI-test target scaffold and launch checks
- `docs/` — canonical SDLC, product, architecture, data, safety, quality, and release docs
- `docs/adr/` — accepted architecture decisions
- `docs/reference/` — non-canonical local reference snapshots and future preserved inputs
- `scripts/` — project-generation, validation, and maintenance helpers
- `assets/` — Lantern brand kit including wordmarks, icons, favicon, typography guide, and color system
- `report/` — append-only human-readable verification and release evidence
- `screenshot/` — image evidence retained alongside dated reports when needed

## Current Phase

Milestone 6 (Apple Intelligence Surface) is complete. The app includes offline-first handbook browsing, grounded local Ask assistant with citations, inventory/checklists/notes organizer, Siri App Intents with AssistantSchema, Spotlight indexing via App Entities, FM-powered inventory completion with heuristic fallback, RSS-based knowledge discovery with optional Brave Search enrichment, and the Lantern brand palette with warm amber/gold themed surfaces. The most recent full `xcodebuild test` run on 2026-03-29 passed 424 XCTest (380 unit + 44 UI) plus 73 Swift Testing cases. See `docs/sdlc/00-doc-suite-index.md` for detailed status.
