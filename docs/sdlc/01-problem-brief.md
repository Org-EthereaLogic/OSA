# Problem Brief

Status: Initial draft complete.  
Related docs: [PRD](./02-prd.md), [MVP Scope Roadmap](./03-mvp-scope-roadmap.md), [Technical Architecture](./05-technical-architecture.md), [Risk Register](./risk-register.md)

## Confirmed Facts

- OSA is intended to be an offline-first iPhone preparedness handbook app with optional online capabilities.
- Core product elements include curated handbook content, quick cards, checklists, inventory, personal notes, and a local Ask assistant.
- The assistant is bounded: it must answer only from approved local content and app data.
- The repo contains complete Milestone 1 (Foundation), Milestone 2 (Core Organizer), and Milestone 3 (Grounded Ask) implementations including a polish sprint. All core product surfaces — handbook browsing, quick cards, inventory, checklists, notes, local search, and bounded Ask with citations — are implemented, wired to live repositories, and tested. Home shows live data, Settings reflects real capability detection, and Ask routes to content via navigation destinations. This brief sets the product baseline for remaining implementation work.

## Assumptions

- The first release is a personal product that may begin as a small-scale private or TestFlight app before broader distribution.
- The initial user is likely a preparedness-minded household planner, with additional value for family members who need quick access under stress.
- The anniversary-gift or personal-product origin is context, not a requirement that changes the product quality bar.

## Recommendations

- Build the app first as a reliable reference and organization tool, not as an AI showcase.
- Make speed, clarity, and trust more important than breadth.
- Keep the first release narrow enough that content quality and offline reliability can both be strong.

## Open Questions

- Is the intended launch audience only the original household, or a wider public audience?
- How much of the initial content will be authored from scratch versus imported and reviewed from external sources?
- Does "local notes/maps/forest reference" require actual offline map rendering in v1?

## Problem Statement

Preparedness information is often fragmented across websites, notes apps, paper lists, and memory. In the moments when people need that information most, connectivity may be poor, stress is high, and generic chat systems are not reliable enough to act as a trusted handbook. People need a single, local, calm, citeable source of preparedness information and household context that remains useful offline.

## Target Users

### Primary User

- A household preparedness planner who wants a curated handbook plus practical tools for inventory, checklists, and notes.

### Secondary User

- A family member or partner who needs fast access to quick cards, contacts, or simple guidance during an outage or disruption.

### Tertiary User

- A careful hobbyist who wants lawful, safety-oriented reference material and structured logs for specific domains such as archery maintenance and practice.

## Why This Product Exists

- To consolidate important preparedness knowledge into a trusted offline-first app.
- To reduce the cognitive overhead of searching across scattered sources during stressful conditions.
- To pair handbook knowledge with household-specific data such as inventory, notes, and checklists.
- To provide bounded AI assistance without sacrificing provenance or safety.

## Personal Background Context

The anniversary-gift and personal-product context is useful only as background: it explains why the product can prioritize practicality, privacy, and polish over broad-market feature sprawl. It should not justify cutting engineering rigor or content review quality.

## Product Vision

OSA should feel like a calm, dependable preparedness handbook that lives on the phone, works offline, and knows the user's local context without exposing that data to remote services. The app should help the user find relevant information fast, maintain household readiness, and ask bounded questions against a trusted local corpus with citations.

## Constraints

- Offline-first behavior is mandatory for core flows.
- Safety-sensitive topics require tighter guardrails than ordinary lifestyle content.
- The app should remain practical for a solo developer or very small team.
- User privacy defaults to on-device only.
- v1 should avoid architectures that require a backend just to function.

## Non-Goals

- A general-purpose chatbot.
- Tactical weapon guidance, hunting coaching, or combat advice.
- High-risk medical diagnosis or personalized treatment advice.
- Edible-plant identification.
- A large-scale social, marketplace, or community platform.
- Mandatory account creation or cloud dependency in v1.

## Success Criteria

- A user can cold-start the app fully offline and access core handbook, quick cards, search, notes, inventory, checklists, and Ask over local content.
- The app clearly distinguishes what is available locally versus what requires connectivity.
- Ask provides cited, bounded answers and refuses unsupported requests.
- Online knowledge import produces durable local content that remains available offline afterward.
- The information architecture remains simple enough to operate under stress.

## Major Risks

- Weak or inconsistent content quality undermines the retrieval and Ask experience.
- Device or OS limitations reduce AI capability on part of the target hardware set.
- Scope creep turns a disciplined handbook app into an under-specified survival super-app.
- Safety boundaries drift if content and assistant policies are not actively maintained.
- Migration and storage complexity increase quickly once imported knowledge grows.

## Done Means

- This brief gives a stable product framing for the PRD and roadmap.
- Non-goals are explicit enough to cut scope during implementation.
- Risks and constraints align with the ADRs and architecture recommendations.

## Next-Step Recommendations

1. Confirm whether the first release targets only a private audience or public App Store distribution.
2. ~~Resolve the minimum supported iPhone and iOS baseline before feature scaffolding.~~ **Resolved:** iOS 18.0 minimum. See [ADR-0004](../adr/ADR-0004-ios18-minimum-target-with-foundation-models.md).
3. Start seed-content planning immediately; this product will only be as strong as its local corpus.
