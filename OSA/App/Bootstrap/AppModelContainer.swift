import Foundation
import SwiftData

private extension ProcessInfo {
    /// Returns `true` when the process is hosted by XCTest or a UI-test runner.
    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestSessionIdentifier"] != nil
    }

    var isRunningUITests: Bool {
        arguments.contains("UI-TESTING")
    }

    var isRunningUnitTests: Bool {
        isRunningTests && !isRunningUITests
    }
}

/// Shared runtime for App Intents and other non-SwiftUI entry points.
///
/// Lazily creates the same `AppDependencies` graph used by the main app.
/// Thread-safe through `@MainActor` isolation.
enum SharedRuntime {
    @MainActor
    private static var _dependencies: AppDependencies?

    @MainActor
    private static var _navigationCoordinator: AppNavigationCoordinator?

    @MainActor
    private static var _onscreenContentManager: OnscreenContentManager?

    @MainActor
    static var dependencies: AppDependencies {
        if let existing = _dependencies { return existing }
        let container = AppModelContainer.makeShared()
        let deps = AppDependencies.live(modelContainer: container)
        _dependencies = deps
        return deps
    }

    @MainActor
    static var navigationCoordinator: AppNavigationCoordinator {
        if let existing = _navigationCoordinator { return existing }
        let coordinator = AppNavigationCoordinator()
        _navigationCoordinator = coordinator
        return coordinator
    }

    /// Called by `OSAApp.init()` to share the already-created dependencies.
    @MainActor
    static func install(_ deps: AppDependencies) {
        _dependencies = deps
    }

    /// Called by `OSAApp` to share the navigation coordinator with App Intents.
    @MainActor
    static func installNavigationCoordinator(_ coordinator: AppNavigationCoordinator) {
        _navigationCoordinator = coordinator
    }

    @MainActor
    static var onscreenContentManager: OnscreenContentManager {
        if let existing = _onscreenContentManager { return existing }
        let manager = OnscreenContentManager()
        _onscreenContentManager = manager
        return manager
    }

    @MainActor
    static func installOnscreenContentManager(_ manager: OnscreenContentManager) {
        _onscreenContentManager = manager
    }
}

enum AppModelContainer {
    @MainActor
    static func makeShared(bundle: Bundle = .main) -> ModelContainer {
        let schema = Schema([
            PersistedHandbookChapter.self,
            PersistedHandbookSection.self,
            PersistedQuickCard.self,
            PersistedSeedContentState.self,
            PersistedInventoryItem.self,
            PersistedChecklistTemplate.self,
            PersistedChecklistTemplateItem.self,
            PersistedChecklistRun.self,
            PersistedChecklistRunItem.self,
            PersistedEmergencyContact.self,
            PersistedNoteRecord.self,
            PersistedSourceRecord.self,
            PersistedImportedKnowledgeDocument.self,
            PersistedKnowledgeChunk.self,
            PersistedPendingOperation.self,
            PersistedDailyForecast.self,
            PersistedWeatherAlert.self
        ])
        let processInfo = ProcessInfo.processInfo
        let isTestHost = processInfo.isRunningTests
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isTestHost
        )

        do {
            let modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Skip seed import for unit-test hosts, but allow UI tests to
            // import bundled content into an in-memory store for navigation.
            guard !processInfo.isRunningUnitTests else {
                return modelContainer
            }

            let dependencies = AppDependencies.live(modelContainer: modelContainer)
            let loader = try SeedContentLoader.bundled(in: bundle)
            let importer = SeedContentImporter(
                loader: loader,
                repository: dependencies.seedContentRepository
            )

            _ = try importer.importBundledContentIfNeeded()

            return modelContainer
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
