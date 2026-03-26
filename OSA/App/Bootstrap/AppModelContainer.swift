import Foundation
import SwiftData

private extension ProcessInfo {
    /// Returns `true` when the process is hosted by XCTest or a UI-test runner.
    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestSessionIdentifier"] != nil
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
    static var dependencies: AppDependencies {
        if let existing = _dependencies { return existing }
        let container = AppModelContainer.makeShared()
        let deps = AppDependencies.live(modelContainer: container)
        _dependencies = deps
        return deps
    }

    /// Called by `OSAApp.init()` to share the already-created dependencies.
    @MainActor
    static func install(_ deps: AppDependencies) {
        _dependencies = deps
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
            PersistedNoteRecord.self,
            PersistedSourceRecord.self,
            PersistedImportedKnowledgeDocument.self,
            PersistedKnowledgeChunk.self,
            PersistedPendingOperation.self
        ])
        let isTestHost = ProcessInfo.processInfo.isRunningTests
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isTestHost
        )

        do {
            let modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

            // Skip seed import when running inside a unit-test host process.
            // The test host may not bundle seed content resources.
            guard !ProcessInfo.processInfo.isRunningTests else {
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
