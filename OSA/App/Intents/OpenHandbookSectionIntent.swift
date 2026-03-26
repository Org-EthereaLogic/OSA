import AppIntents

/// App Intent that opens a specific handbook section by entity identity.
///
/// Siri and Shortcuts use this to deep-link into the app after
/// resolving a handbook section through `HandbookSectionEntity`.
struct OpenHandbookSectionIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Handbook Section"
    static let description = IntentDescription(
        "Open a specific handbook section in Lantern.",
        categoryName: "Navigation"
    )

    @Parameter(title: "Handbook Section")
    var target: HandbookSectionEntity

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let coordinator = SharedRuntime.navigationCoordinator
        coordinator.openHandbookSection(id: target.id)

        return .result(dialog: "Opening \(target.heading).")
    }
}
