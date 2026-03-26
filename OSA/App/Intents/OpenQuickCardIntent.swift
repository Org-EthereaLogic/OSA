import AppIntents

/// App Intent that opens a specific quick card by entity identity.
///
/// Siri and Shortcuts use this to deep-link into the app after
/// resolving a quick card through `QuickCardEntity`.
struct OpenQuickCardIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Quick Card"
    static let description = IntentDescription(
        "Open a specific quick card in Lantern.",
        categoryName: "Navigation"
    )

    @Parameter(title: "Quick Card")
    var target: QuickCardEntity

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let coordinator = SharedRuntime.navigationCoordinator
        coordinator.openQuickCard(id: target.id)

        return .result(dialog: "Opening \(target.title).")
    }
}
