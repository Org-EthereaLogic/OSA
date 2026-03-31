import Foundation

enum UITestFixtureMode: String, Sendable {
    case weekSimulation = "week-sim"
}

enum UITestConnectivityOverride: String, Sendable {
    case offline
    case onlineConstrained
    case onlineUsable
    case syncInProgress

    var state: ConnectivityState {
        switch self {
        case .offline:
            .offline
        case .onlineConstrained:
            .onlineConstrained
        case .onlineUsable:
            .onlineUsable
        case .syncInProgress:
            .syncInProgress
        }
    }
}

struct UITestScenarioConfiguration: Sendable {
    static let scenarioIDArgument = "UI-TEST-SCENARIO-ID"
    static let resetStateArgument = "UI-TEST-RESET-STATE"
    static let nowArgument = "UI-TEST-NOW"
    static let connectivityArgument = "UI-TEST-CONNECTIVITY"
    static let fixtureModeArgument = "UI-TEST-FIXTURE-MODE"

    let scenarioID: String
    let shouldResetState: Bool
    let nowOverride: Date?
    let connectivityOverride: UITestConnectivityOverride?
    let fixtureMode: UITestFixtureMode?

    init?(
        processInfo: ProcessInfo = .processInfo,
        fileManager: FileManager = .default
    ) {
        guard processInfo.arguments.contains("UI-TESTING"),
              let scenarioID = processInfo.launchArgumentValue(named: Self.scenarioIDArgument),
              !scenarioID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return nil
        }

        self.scenarioID = scenarioID
        self.shouldResetState = processInfo.launchArgumentValue(named: Self.resetStateArgument) == "1"

        if let nowValue = processInfo.launchArgumentValue(named: Self.nowArgument) {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            nowOverride = formatter.date(from: nowValue)
        } else {
            nowOverride = nil
        }

        if let connectivityValue = processInfo.launchArgumentValue(named: Self.connectivityArgument) {
            connectivityOverride = UITestConnectivityOverride(rawValue: connectivityValue)
        } else {
            connectivityOverride = nil
        }

        if let fixtureValue = processInfo.launchArgumentValue(named: Self.fixtureModeArgument) {
            fixtureMode = UITestFixtureMode(rawValue: fixtureValue)
        } else {
            fixtureMode = nil
        }

        let root = fileManager.temporaryDirectory
            .appendingPathComponent("OSA-UITest-Scenarios", isDirectory: true)
            .appendingPathComponent(Self.sanitizedID(from: scenarioID), isDirectory: true)

        baseDirectoryURL = root
        stateDirectoryURL = root.appendingPathComponent("State", isDirectory: true)
        supportDirectoryURL = root.appendingPathComponent("AppSupport", isDirectory: true)
        modelStoreURL = stateDirectoryURL.appendingPathComponent("Model.sqlite", isDirectory: false)
        searchIndexDirectoryURL = supportDirectoryURL.appendingPathComponent("SearchIndex", isDirectory: true)
        fileStorageBaseDirectoryURL = supportDirectoryURL.appendingPathComponent("FileStorage", isDirectory: true)
        userDefaultsSuiteName = "com.etherealogic.OSA.ui-test.\(Self.sanitizedID(from: scenarioID))"
    }

    let baseDirectoryURL: URL
    let stateDirectoryURL: URL
    let supportDirectoryURL: URL
    let modelStoreURL: URL
    let searchIndexDirectoryURL: URL
    let fileStorageBaseDirectoryURL: URL
    let userDefaultsSuiteName: String

    var userDefaults: UserDefaults {
        UserDefaults(suiteName: userDefaultsSuiteName) ?? .standard
    }

    func prepareForLaunch(fileManager: FileManager = .default) {
        if shouldResetState {
            if fileManager.fileExists(atPath: baseDirectoryURL.path) {
                try? fileManager.removeItem(at: baseDirectoryURL)
            }
            userDefaults.removePersistentDomain(forName: userDefaultsSuiteName)
        }

        try? fileManager.createDirectory(at: stateDirectoryURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: searchIndexDirectoryURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: fileStorageBaseDirectoryURL, withIntermediateDirectories: true)
    }

    private static func sanitizedID(from rawValue: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let scalars = rawValue.unicodeScalars.map { scalar in
            allowed.contains(scalar) ? Character(scalar) : "-"
        }
        let sanitized = String(scalars)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-_"))
        return sanitized.isEmpty ? "default" : sanitized
    }
}

struct AppRuntimeConfiguration {
    let isUITesting: Bool
    let scenario: UITestScenarioConfiguration?

    static func current(processInfo: ProcessInfo = .processInfo) -> AppRuntimeConfiguration {
        AppRuntimeConfiguration(
            isUITesting: processInfo.arguments.contains("UI-TESTING"),
            scenario: UITestScenarioConfiguration(processInfo: processInfo)
        )
    }

    var userDefaults: UserDefaults {
        scenario?.userDefaults ?? .standard
    }

    var nowProvider: @Sendable () -> Date {
        if let override = scenario?.nowOverride {
            return { override }
        }
        return Date.init
    }

    var connectivityOverride: ConnectivityState? {
        scenario?.connectivityOverride?.state
    }

    var modelStoreURL: URL? {
        scenario?.modelStoreURL
    }

    var searchIndexDirectoryURL: URL? {
        scenario?.searchIndexDirectoryURL
    }

    var fileStorageBaseDirectoryURL: URL? {
        scenario?.fileStorageBaseDirectoryURL
    }

    var shouldUseWeekSimulationFixtures: Bool {
        #if targetEnvironment(simulator)
        scenario?.fixtureMode == .weekSimulation
        #else
        false
        #endif
    }

    func prepareForLaunch() {
        scenario?.prepareForLaunch()

        guard isUITesting else { return }

        let defaults = userDefaults
        defaults.set(true, forKey: UserProfileSettings.onboardingCompletedKey)

        if scenario == nil {
            defaults.removeObject(forKey: RecentLibraryHistorySettings.recentSectionIDsKey)
            defaults.removeObject(forKey: RecentAskHistorySettings.recentQuestionsKey)
            defaults.set(
                AccessibilitySettings.appLanguageDefault.rawValue,
                forKey: AccessibilitySettings.appLanguageKey
            )
            defaults.set(
                AccessibilitySettings.highContrastModeDefault,
                forKey: AccessibilitySettings.highContrastModeKey
            )
            defaults.set(
                AccessibilitySettings.largePrintReadingModeDefault,
                forKey: AccessibilitySettings.largePrintReadingModeKey
            )
            return
        }

        if defaults.object(forKey: AccessibilitySettings.appLanguageKey) == nil {
            defaults.set(
                AccessibilitySettings.appLanguageDefault.rawValue,
                forKey: AccessibilitySettings.appLanguageKey
            )
        }
        if defaults.object(forKey: AccessibilitySettings.highContrastModeKey) == nil {
            defaults.set(
                AccessibilitySettings.highContrastModeDefault,
                forKey: AccessibilitySettings.highContrastModeKey
            )
        }
        if defaults.object(forKey: AccessibilitySettings.largePrintReadingModeKey) == nil {
            defaults.set(
                AccessibilitySettings.largePrintReadingModeDefault,
                forKey: AccessibilitySettings.largePrintReadingModeKey
            )
        }
    }
}

private extension ProcessInfo {
    func launchArgumentValue(named key: String) -> String? {
        arguments.first(where: { $0.hasPrefix("\(key)=") })?
            .split(separator: "=", maxSplits: 1)
            .last
            .map(String.init)
    }
}
