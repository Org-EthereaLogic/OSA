import SwiftData
import SwiftUI

@main
struct OSAApp: App {
    private let sharedModelContainer: ModelContainer
    private let dependencies: AppDependencies
    private let isUITesting: Bool
    @State private var navigationCoordinator = AppNavigationCoordinator()
    @State private var onscreenContentManager = OnscreenContentManager()
    @AppStorage(UserProfileSettings.onboardingCompletedKey)
    private var onboardingCompleted = UserProfileSettings.onboardingCompletedDefault

    init() {
        let processInfo = ProcessInfo.processInfo
        let isUITesting = processInfo.arguments.contains("UI-TESTING")
        self.isUITesting = isUITesting

        if isUITesting {
            UserDefaults.standard.set(true, forKey: UserProfileSettings.onboardingCompletedKey)
            UserDefaults.standard.removeObject(forKey: RecentLibraryHistorySettings.recentSectionIDsKey)
        }

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
                .environment(\.supplyTemplateRepository, dependencies.supplyTemplateRepository)
                .environment(\.checklistRepository, dependencies.checklistRepository)
                .environment(\.emergencyContactRepository, dependencies.emergencyContactRepository)
                .environment(\.noteRepository, dependencies.noteRepository)
                .environment(\.importedKnowledgeRepository, dependencies.importedKnowledgeRepository)
                .environment(\.pendingOperationRepository, dependencies.pendingOperationRepository)
                .environment(\.searchService, dependencies.searchService)
                .environment(\.capabilityDetector, dependencies.capabilityDetector)
                .environment(\.retrievalService, dependencies.retrievalService)
                .environment(\.inventoryExpiryNotificationService, dependencies.inventoryExpiryNotificationService)
                .environment(\.connectivityService, dependencies.connectivityService)
                .environment(\.trustedSourceHTTPClient, dependencies.trustedSourceHTTPClient)
                .environment(\.importPipeline, dependencies.importPipeline)
                .environment(\.inventoryCompletionService, dependencies.inventoryCompletionService)
                .environment(\.hapticFeedbackService, dependencies.hapticFeedbackService)
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

                    guard !isUITesting else {
                        return
                    }

                    try? await dependencies.inventoryExpiryNotificationService.rescheduleNotifications()
                    await dependencies.refreshCoordinator.start()
                    await dependencies.discoveryCoordinator.startIfDue()
                }
                .fullScreenCover(isPresented: onboardingBinding) {
                    OnboardingFlowView {
                        onboardingCompleted = true
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private var onboardingBinding: Binding<Bool> {
        if isUITesting {
            return .constant(false)
        }

        return Binding(
            get: { !onboardingCompleted },
            set: { shouldPresent in
                if !shouldPresent {
                    onboardingCompleted = true
                }
            }
        )
    }
}
