# ADR-0004: iOS 18 Minimum Target With Foundation Models And Extractive Fallback

Status: Accepted
Date: 2026-03-21
Related docs: [Technical Architecture](../sdlc/05-technical-architecture.md), [AI Assistant](../sdlc/08-ai-assistant-retrieval-and-guardrails.md), [ADR-0002](./ADR-0002-grounded-assistant-only.md)

## Confirmed Facts

- The product includes a grounded Ask assistant that benefits from on-device generation.
- Apple Foundation Models are available on iOS 18+ devices with supported hardware.
- The repository is pre-implementation, making this the right time to lock the target.

## Context

Multiple documents identified the minimum iOS version as a blocking decision before project scaffolding. The technical architecture recommends iOS 18 if it materially simplifies Foundation Models integration, and the AI assistant spec defines a three-tier capability model (foundationGeneration, extractiveOnly, unavailable). Targeting iOS 18+ unifies the persistence, UI, and AI layers around modern Apple frameworks.

## Decision

The minimum deployment target for OSA v1 is iOS 18.

The app will use Apple Foundation Models for grounded answer generation on supported devices and fall back to extractive answer assembly on iOS 18 devices where Foundation Models are unavailable or resource-constrained.

## Rationale

- iOS 18 provides SwiftData maturity, modern SwiftUI navigation, and Foundation Models access on a single deployment target.
- Extractive fallback ensures the app remains useful on all iOS 18 hardware, including devices without model support.
- A single-version target reduces testing matrix complexity for a solo developer.
- Bundling a third-party local model is explicitly deferred to avoid app size, battery, and safety evaluation overhead.

## Tradeoffs

- Users on iOS 17 and earlier cannot use the app.
- Answer quality will vary by device: newer hardware gets fluent generated summaries, older iOS 18 hardware gets cited snippet assembly.
- If Apple restricts or changes Foundation Models APIs, the app must adapt within the iOS 18+ surface.

## Consequences

- The Xcode project will set a deployment target of iOS 18.0.
- SwiftData, modern SwiftUI, and Foundation Models APIs can be used without availability checks.
- The model adapter layer must detect capability at runtime and route to generation or extractive paths.
- QA must cover both Foundation Models-capable and extractive-only device profiles.
- No bundled third-party LLM in v1.

## Done Means

- The Xcode project targets iOS 18.0.
- The assistant layer has both generation and extractive code paths.
- Test plans include at least one device or simulator path for each capability tier.
