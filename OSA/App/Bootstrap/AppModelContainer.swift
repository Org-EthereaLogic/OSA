import Foundation
import SwiftData

private extension ProcessInfo {
    /// Returns `true` when the process is hosted by XCTest or a UI-test runner.
    var isRunningTests: Bool {
        environment["XCTestConfigurationFilePath"] != nil
            || environment["XCTestSessionIdentifier"] != nil
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
            PersistedNoteRecord.self
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
