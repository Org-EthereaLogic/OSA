import SwiftData
import SwiftUI

@main
struct OSAApp: App {
    private let sharedModelContainer: ModelContainer
    private let dependencies: AppDependencies
    @State private var navigationCoordinator = AppNavigationCoordinator()
    @State private var onscreenContentManager = OnscreenContentManager()

    init() {
        let container = AppModelContainer.makeShared()
        self.sharedModelContainer = container
        let deps = AppDependencies.live(modelContainer: container)
        self.dependencies = deps
        SharedRuntime.install(deps)
    }

    var body: some Scene {
        WindowGroup {
            AppTabView(coordinator: navigationCoordinator)
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
                .environment(\.inventoryCompletionService, dependencies.inventoryCompletionService)
                .environment(\.onscreenContentManager, onscreenContentManager)
                .environment(\.rssDiscoveryService, dependencies.rssDiscoveryService)
                .environment(\.discoveryCoordinator, dependencies.discoveryCoordinator)
                .environment(\.weatherForecastRepository, dependencies.weatherForecastRepository)
                .environment(\.weatherForecastService, dependencies.weatherForecastService)
                .environment(\.weatherAlertService, dependencies.weatherAlertService)
                .environment(\.locationService, dependencies.locationService)
                .environment(\.mapAnnotationProvider, dependencies.mapAnnotationProvider)
                .environment(\.tileCacheService, dependencies.tileCacheService)
                .task {
                    SharedRuntime.installNavigationCoordinator(navigationCoordinator)
                    SharedRuntime.installOnscreenContentManager(onscreenContentManager)
                    await dependencies.refreshCoordinator.start()
                    await dependencies.discoveryCoordinator.startIfDue()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
