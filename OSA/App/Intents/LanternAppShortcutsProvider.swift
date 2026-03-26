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
    }
}
