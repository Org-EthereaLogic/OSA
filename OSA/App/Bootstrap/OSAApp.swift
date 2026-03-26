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
                .environment(\.importedKnowledgeRepository, dependencies.importedKnowledgeRepository)
                .environment(\.pendingOperationRepository, dependencies.pendingOperationRepository)
                .environment(\.searchService, dependencies.searchService)
                .environment(\.capabilityDetector, dependencies.capabilityDetector)
                .environment(\.retrievalService, dependencies.retrievalService)
                .environment(\.connectivityService, dependencies.connectivityService)
                .environment(\.trustedSourceHTTPClient, dependencies.trustedSourceHTTPClient)
                .environment(\.importPipeline, dependencies.importPipeline)
                .task {
                    await dependencies.refreshCoordinator.start()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
