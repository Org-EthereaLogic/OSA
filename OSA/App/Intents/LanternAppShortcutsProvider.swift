import AppIntents

/// Registers discoverable App Shortcuts so Siri can invoke Lantern
/// without requiring manual Shortcut creation.
struct LanternAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AskLanternIntent(),
            phrases: [
                "Ask \(.applicationName) a question",
                "Search \(.applicationName)"
            ],
            shortTitle: "Ask Lantern",
            systemImageName: "text.magnifyingglass"
        )

        AppShortcut(
            intent: OpenQuickCardIntent(),
            phrases: [
                "Open quick card in \(.applicationName)",
                "Show quick card in \(.applicationName)"
            ],
            shortTitle: "Open Quick Card",
            systemImageName: "bolt.fill"
        )

        AppShortcut(
            intent: OpenHandbookSectionIntent(),
            phrases: [
                "Open handbook section in \(.applicationName)",
                "Show handbook section in \(.applicationName)"
            ],
            shortTitle: "Open Handbook Section",
            systemImageName: "book.closed.fill"
        )
    }
}
