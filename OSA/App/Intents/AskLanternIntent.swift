import AppIntents

/// A natural-language App Intent that lets Siri ask Lantern
/// a preparedness question using the existing grounded retrieval pipeline.
///
/// All queries flow through `LocalRetrievalService` -> `SensitivityPolicy`
/// -> `GroundedPromptBuilder` -> `FoundationModelAdapter` (when available).
/// The assistant contract, citation requirements, and safety guardrails
/// remain enforced regardless of entry point.
struct AskLanternIntent: AppIntent {
    static let title: LocalizedStringResource = "Ask Lantern"
    static let description = IntentDescription(
        "Ask a preparedness question. Lantern answers only from approved local content with citations.",
        categoryName: "Search"
    )

    @Parameter(title: "Question", description: "A natural-language preparedness question")
    var question: String

    static let openAppWhenRun: Bool = false

    @MainActor
    func perform() async throws -> some ReturnsValue<String> & ProvidesDialog {
        let deps = SharedRuntime.dependencies

        guard let retrievalService = deps.retrievalService else {
            return .result(
                value: "Lantern's local knowledge base is not available.",
                dialog: "Lantern's local knowledge base is not available. Try opening the app."
            )
        }

        let executor = AskLanternIntentExecutor(retrievalService: retrievalService)
        let answer = await executor.execute(question: question)

        return .result(
            value: answer.text,
            dialog: IntentDialog(stringLiteral: answer.text)
        )
    }
}
