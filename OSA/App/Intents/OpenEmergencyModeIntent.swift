import AppIntents

struct OpenEmergencyModeIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Emergency Mode"
    static let description = IntentDescription(
        "Open Lantern directly into Emergency Mode.",
        categoryName: "Navigation"
    )

    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        SharedRuntime.navigationCoordinator.openEmergencyMode()
        return .result(dialog: "Opening Emergency Mode.")
    }
}
