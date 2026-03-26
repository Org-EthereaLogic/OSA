import Foundation

final class LocalRetrievalService: RetrievalService {
    private let searchService: SearchService
    private let sensitivityClassifier: SensitivityClassifier
    private let capabilityDetector: CapabilityDetector
    private let answerGenerator: (any GroundedAnswerGenerator)?

    private let maxEvidenceItems = 8

    init(
        searchService: SearchService,
        sensitivityClassifier: SensitivityClassifier,
        capabilityDetector: CapabilityDetector,
        answerGenerator: (any GroundedAnswerGenerator)? = nil
    ) {
        self.searchService = searchService
        self.sensitivityClassifier = sensitivityClassifier
        self.capabilityDetector = capabilityDetector
        self.answerGenerator = answerGenerator
    }

    func retrieve(query: String, scopes: Set<RetrievalScope>?) async throws -> RetrievalOutcome {
        // 1. Normalize query
        guard let normalized = QueryNormalizer.normalize(query) else {
            return .refused(.emptyQuery)
        }

        // 2. Classify sensitivity
        let sensitivity = sensitivityClassifier.classify(query)
        switch sensitivity {
        case .blocked(let reason):
            return .refused(.blockedSensitiveScope(reason))
        case .sensitiveStaticOnly, .allowed:
            break
        }

        // 3. Map retrieval scopes to search result kinds
        let kindFilter = mapScopesToKinds(scopes, sensitivity: sensitivity)

        // 4. Search local index
        let searchResults = try searchService.search(
            query: normalized,
            scopes: kindFilter,
            limit: maxEvidenceItems * 2 // over-fetch for re-ranking
        )

        // 5. Convert to evidence items
        let evidence = searchResults.map { result in
            EvidenceItem(
                id: result.id,
                kind: result.kind,
                title: result.title,
                snippet: result.snippet,
                score: result.score,
                sourceLabel: sourceLabel(for: result.kind),
                tags: result.tags
            )
        }

        // 6. Re-rank
        let ranked = EvidenceRanker.rank(evidence, query: normalized)
        let topEvidence = Array(ranked.prefix(maxEvidenceItems))

        // 7. Check evidence sufficiency
        guard !topEvidence.isEmpty else {
            return .refused(.insufficientEvidence)
        }

        // 8. Package citations
        let citations = topEvidence.map { item in
            CitationReference(
                id: item.id,
                kind: item.kind,
                title: item.title,
                sourceLabel: item.sourceLabel
            )
        }

        // 9. Determine confidence
        let confidence = determineConfidence(evidence: topEvidence)

        // 10. Detect capability and assemble answer
        let answerMode = capabilityDetector.detectAnswerMode()
        let answerText = await assembleAnswer(
            query: query,
            evidence: topEvidence,
            citations: citations,
            mode: answerMode,
            confidence: confidence
        )

        // 11. Build suggested actions
        let suggestedActions = buildSuggestedActions(evidence: topEvidence)

        return .answered(AnswerResult(
            query: query,
            evidence: topEvidence,
            citations: citations,
            confidence: confidence,
            answerMode: answerMode,
            answerText: answerText,
            suggestedActions: suggestedActions
        ))
    }

    // MARK: - Private Helpers

    private func mapScopesToKinds(
        _ scopes: Set<RetrievalScope>?,
        sensitivity: SensitivityResult
    ) -> Set<SearchResultKind>? {
        // For sensitive-static-only, restrict to handbook and quick cards
        if case .sensitiveStaticOnly = sensitivity {
            return [.handbookSection, .quickCard]
        }

        guard let scopes else { return nil }

        var kinds = Set<SearchResultKind>()
        for scope in scopes {
            switch scope {
            case .handbook: kinds.insert(.handbookSection)
            case .quickCards: kinds.insert(.quickCard)
            case .inventory: kinds.insert(.inventoryItem)
            case .checklists: kinds.insert(.checklistTemplate)
            case .notes: kinds.insert(.noteRecord)
            case .importedKnowledge: kinds.insert(.importedKnowledge)
            }
        }
        return kinds.isEmpty ? nil : kinds
    }

    private func sourceLabel(for kind: SearchResultKind) -> String {
        switch kind {
        case .handbookSection: "Handbook"
        case .quickCard: "Quick Card"
        case .inventoryItem: "Inventory"
        case .checklistTemplate: "Checklist"
        case .noteRecord: "Note"
        case .importedKnowledge: "Imported Source"
        }
    }

    private func determineConfidence(evidence: [EvidenceItem]) -> ConfidenceLevel {
        let approvedSourceCount = evidence.filter {
            $0.kind == .handbookSection || $0.kind == .quickCard || $0.kind == .importedKnowledge
        }.count

        if approvedSourceCount >= 2 {
            return .groundedHigh
        } else if !evidence.isEmpty {
            return .groundedMedium
        } else {
            return .insufficientLocalEvidence
        }
    }

    private func assembleAnswer(
        query: String,
        evidence: [EvidenceItem],
        citations: [CitationReference],
        mode: AnswerMode,
        confidence: ConfidenceLevel
    ) async -> String {
        switch mode {
        case .groundedGeneration:
            if let generator = answerGenerator {
                do {
                    return try await generator.generate(
                        query: query,
                        evidence: evidence,
                        citations: citations,
                        confidence: confidence
                    )
                } catch {
                    // Generation failed — fall back to extractive assembly
                    return assembleExtractiveAnswer(evidence: evidence, confidence: confidence)
                }
            }
            // No generator injected — fall back to extractive
            return assembleExtractiveAnswer(evidence: evidence, confidence: confidence)

        case .extractiveOnly:
            return assembleExtractiveAnswer(evidence: evidence, confidence: confidence)

        case .searchResultsOnly:
            return "Here are the most relevant local sources for your question."
        }
    }

    private func assembleExtractiveAnswer(
        evidence: [EvidenceItem],
        confidence: ConfidenceLevel
    ) -> String {
        guard let top = evidence.first else {
            return "No relevant local content found."
        }

        var parts: [String] = []

        // Lead with the top result
        parts.append(top.snippet)

        // Add supporting evidence if high confidence
        if confidence == .groundedHigh, evidence.count > 1 {
            let supporting = evidence.dropFirst().prefix(2)
            for item in supporting {
                if !item.snippet.isEmpty {
                    parts.append(item.snippet)
                }
            }
        }

        return parts.joined(separator: "\n\n")
    }

    private func buildSuggestedActions(evidence: [EvidenceItem]) -> [SuggestedAction] {
        var actions: [SuggestedAction] = []

        // Suggest opening the top quick card
        if let topCard = evidence.first(where: { $0.kind == .quickCard }) {
            actions.append(.openQuickCard(id: topCard.id, title: topCard.title))
        }

        // Suggest opening the top handbook section
        if let topSection = evidence.first(where: { $0.kind == .handbookSection }) {
            actions.append(.openHandbookSection(id: topSection.id, title: topSection.title))
        }

        return actions
    }
}
