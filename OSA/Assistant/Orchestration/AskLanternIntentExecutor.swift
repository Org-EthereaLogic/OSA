import Foundation

/// Executes a natural-language question through the existing grounded
/// retrieval pipeline and formats the result for Siri and Shortcuts.
///
/// This executor reuses `RetrievalService` and does not bypass
/// sensitivity policy, capability detection, or citation packaging.
@MainActor
struct AskLanternIntentExecutor {

    private let retrievalService: any RetrievalService
    private let includePersonalNotes: () -> Bool
    private let preferredTagsProvider: () -> Set<String>

    init(
        retrievalService: any RetrievalService,
        includePersonalNotes: @escaping () -> Bool = {
            UserDefaults.standard.bool(forKey: AskScopeSettings.includePersonalNotesKey)
        },
        preferredTagsProvider: @escaping () -> Set<String> = {
            let storedRegion = UserDefaults.standard.string(forKey: UserProfileSettings.regionKey)
                ?? UserProfileSettings.regionDefault.rawValue
            return [UserProfileSettings.region(from: storedRegion).tag]
        }
    ) {
        self.retrievalService = retrievalService
        self.includePersonalNotes = includePersonalNotes
        self.preferredTagsProvider = preferredTagsProvider
    }

    /// Execute a question and return Siri-formatted result text.
    func execute(question: String) async -> LanternAnswerResult {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return LanternAnswerResult(
                text: "Please ask a specific question about preparedness.",
                isRefusal: true
            )
        }

        let scopes = AskScopeSettings.retrievalScopes(
            includePersonalNotes: includePersonalNotes()
        )

        do {
            nonisolated(unsafe) let service = retrievalService
            let context = RetrievalContext(preferredTags: preferredTagsProvider())
            let outcome = try await service.retrieve(
                query: trimmed,
                scopes: scopes,
                context: context.isEmpty ? nil : context
            )
            return format(outcome)
        } catch {
            return LanternAnswerResult(
                text: "Lantern's local knowledge base is temporarily unavailable. Try opening the app directly.",
                isRefusal: true
            )
        }
    }

    // MARK: - Formatting

    private func format(_ outcome: RetrievalOutcome) -> LanternAnswerResult {
        switch outcome {
        case .answered(let result):
            return formatAnswer(result)
        case .refused(let reason):
            return formatRefusal(reason)
        }
    }

    private func formatAnswer(_ result: AnswerResult) -> LanternAnswerResult {
        var text = result.answerText

        if !result.citations.isEmpty {
            let sourceLabels = result.citations
                .map(\.displayLabel)
                .prefix(3)
            text += "\n\nSources: " + sourceLabels.joined(separator: "; ")
        }

        return LanternAnswerResult(text: text, isRefusal: false)
    }

    private func formatRefusal(_ reason: RefusalReason) -> LanternAnswerResult {
        let text: String
        switch reason {
        case .emptyQuery:
            text = "Please ask a specific question about preparedness."
        case .blockedSensitiveScope(let detail):
            text = "This question is outside Lantern's scope. \(detail)"
        case .insufficientEvidence:
            text = "No relevant content was found in your local knowledge base. Try rephrasing your question or importing a trusted source in the app."
        case .outsideProductScope:
            text = "This question is outside the scope of your preparedness handbook."
        }
        return LanternAnswerResult(text: text, isRefusal: true)
    }
}

/// The formatted result of an intent execution.
struct LanternAnswerResult: Equatable, Sendable {
    let text: String
    let isRefusal: Bool
}
