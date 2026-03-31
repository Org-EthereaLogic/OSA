import SwiftUI

struct OSARootView: View {
    private let dependencies: AppDependencies
    private let isUITesting: Bool
    private let userDefaults: UserDefaults

    @State private var navigationCoordinator = AppNavigationCoordinator()
    @State private var onscreenContentManager = OnscreenContentManager()
    @AppStorage(UserProfileSettings.onboardingCompletedKey)
    private var onboardingCompleted = UserProfileSettings.onboardingCompletedDefault
    @AppStorage(AccessibilitySettings.appLanguageKey)
    private var appLanguageRawValue = AccessibilitySettings.appLanguageDefault.rawValue

    init(
        dependencies: AppDependencies,
        isUITesting: Bool,
        userDefaults: UserDefaults
    ) {
        self.dependencies = dependencies
        self.isUITesting = isUITesting
        self.userDefaults = userDefaults
        _onboardingCompleted = AppStorage(
            wrappedValue: UserProfileSettings.onboardingCompletedDefault,
            UserProfileSettings.onboardingCompletedKey,
            store: userDefaults
        )
        _appLanguageRawValue = AppStorage(
            wrappedValue: AccessibilitySettings.appLanguageDefault.rawValue,
            AccessibilitySettings.appLanguageKey,
            store: userDefaults
        )
    }

    var body: some View {
        AppTabView(coordinator: navigationCoordinator)
            .defaultAppStorage(userDefaults)
            .environment(
                \.locale,
                AccessibilitySettings.appLanguage(from: appLanguageRawValue).locale
            )
            .environment(\.handbookRepository, dependencies.handbookRepository)
            .environment(\.quickCardRepository, dependencies.quickCardRepository)
            .environment(\.fieldReferenceRepository, dependencies.fieldReferenceRepository)
            .environment(\.practiceProgressRepository, dependencies.practiceProgressRepository)
            .environment(\.inventoryRepository, dependencies.inventoryRepository)
            .environment(\.inventoryPhotoStore, dependencies.inventoryPhotoStore)
            .environment(\.documentVaultRepository, dependencies.documentVaultRepository)
            .environment(\.documentVaultFileStore, dependencies.documentVaultFileStore)
            .environment(\.knowledgePackInstallStateRepository, dependencies.knowledgePackInstallStateRepository)
            .environment(\.knowledgePackCatalogClient, dependencies.knowledgePackCatalogClient)
            .environment(\.knowledgePackDownloadCoordinator, dependencies.knowledgePackDownloadCoordinator)
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
            .environment(\.widgetSnapshotCoordinator, dependencies.widgetSnapshotCoordinator)
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
            .environment(\.waypointRepository, dependencies.waypointRepository)
            .environment(\.recordedTrackRepository, dependencies.recordedTrackRepository)
            .environment(\.tileCacheService, dependencies.tileCacheService)
            .task {
                SharedRuntime.installNavigationCoordinator(navigationCoordinator)
                SharedRuntime.installOnscreenContentManager(onscreenContentManager)

                guard !isUITesting else {
                    return
                }

                await dependencies.widgetSnapshotCoordinator.refreshSnapshot()
                await dependencies.protocolLiveActivityCoordinator.syncActiveProtocol()
                try? await dependencies.inventoryExpiryNotificationService.rescheduleNotifications()
                await dependencies.refreshCoordinator.start()
                await dependencies.discoveryCoordinator.startIfDue()
            }
            .onOpenURL { url in
                guard let deepLink = SystemSurfaceDeepLink(url: url) else { return }
                navigationCoordinator.handle(deepLink)
            }
            .fullScreenCover(isPresented: onboardingBinding) {
                OnboardingFlowView {
                    onboardingCompleted = true
                }
            }
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
