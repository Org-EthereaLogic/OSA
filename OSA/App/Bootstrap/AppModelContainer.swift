import Foundation
import SwiftData

enum AppModelContainer {
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
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )

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
