import SwiftData
import SwiftUI

@main
struct OSAApp: App {
    private let sharedModelContainer: ModelContainer
    private let dependencies: AppDependencies

    init() {
        let container = AppModelContainer.makeShared()
        self.sharedModelContainer = container
        self.dependencies = AppDependencies.live(modelContainer: container)
    }

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .environment(\.handbookRepository, dependencies.handbookRepository)
                .environment(\.quickCardRepository, dependencies.quickCardRepository)
                .environment(\.inventoryRepository, dependencies.inventoryRepository)
                .environment(\.checklistRepository, dependencies.checklistRepository)
                .environment(\.noteRepository, dependencies.noteRepository)
                .environment(\.searchService, dependencies.searchService)
                .environment(\.retrievalService, dependencies.retrievalService)
        }
        .modelContainer(sharedModelContainer)
    }
}
