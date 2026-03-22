# ADR-0002: Grounded Assistant Only

Status: Accepted  
Date: 2026-03-21  
Related docs: [PRD](../02-prd.md), [Technical Architecture](../05-technical-architecture.md), [AI Assistant](../08-ai-assistant-retrieval-and-guardrails.md), [Security And Privacy](../10-security-privacy-and-safety.md)

## Confirmed Facts

- The product includes an Ask feature, but product context and safety boundaries make unrestricted chat unacceptable.
- The app has a finite local corpus and several sensitive content domains.

## Assumptions

- Retrieval quality can be made strong enough that a grounded assistant remains useful without open-ended model behavior.
- Users can accept explicit refusals and "not found locally" responses if they are clear and well-cited.

## Recommendations

- Keep retrieval, citation, and refusal behavior testable and deterministic.
- Teach the bounded scope in UI copy so users do not mistake Ask for a general chatbot.

## Open Questions

- Whether notes are included in Ask scope by default still needs product confirmation.
- The exact UX on devices without supported generation capability remains a release decision.

## Context

OSA includes an "Ask" feature, but the product intent is a bounded preparedness handbook assistant, not a general conversational chatbot. The app also has safety-sensitive domains where incorrect improvisation would create risk.

## Decision

The assistant is not a general chatbot and may answer only from approved local sources and app data.

Approved local sources include:

- bundled handbook chapters and sections
- quick cards
- approved imported knowledge already normalized and stored locally
- inventory, checklists, and notes when they are within configured scope

## Rationale

- Grounding reduces hallucination risk.
- Citation-backed answers are easier to trust and easier to test.
- A bounded assistant fits the product better than an open-ended chat surface.
- This decision aligns with the safety boundaries around medical, weapon, foraging, and dangerous improvisation topics.

## Tradeoffs

- The assistant will sometimes refuse or fail to answer questions users expect a generic chatbot to handle.
- Response fluency may be reduced on unsupported devices when extractive fallback is used.
- More effort is required in retrieval quality, taxonomy, and editorial content structure.

## Consequences

- Ask must always run retrieval before answering.
- Uncited answers are product defects.
- Out-of-scope requests require explicit refusal behavior.
- UI copy must teach users that Ask is a bounded reference assistant.

## Done Means

- The assistant cannot answer unsupported questions from model priors alone.
- Every answer path is grounded in local evidence or explicitly says the information is not available locally.
- Regression tests cover refusal and citation behavior for sensitive prompts.
