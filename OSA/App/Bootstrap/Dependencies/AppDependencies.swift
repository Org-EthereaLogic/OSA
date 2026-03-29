import Foundation
import SwiftData

struct AppDependencies {
    let handbookRepository: any HandbookRepository
    let quickCardRepository: any QuickCardRepository
    let seedContentRepository: any SeedContentRepository
    let inventoryRepository: any InventoryRepository
    let supplyTemplateRepository: any SupplyTemplateRepository
    let checklistRepository: any ChecklistRepository
    let emergencyContactRepository: any EmergencyContactRepository
    let noteRepository: any NoteRepository
    let importedKnowledgeRepository: any ImportedKnowledgeRepository
    let pendingOperationRepository: any PendingOperationRepository
    let capabilityDetector: any CapabilityDetector
    let searchService: (any SearchService)?
    let retrievalService: (any RetrievalService)?
    let inventoryExpiryNotificationService: any InventoryExpiryNotificationServicing
    let connectivityService: any ConnectivityService
    let trustedSourceHTTPClient: any TrustedSourceHTTPClient
    let importPipeline: ImportedKnowledgeImportPipeline
    let refreshCoordinator: ImportedKnowledgeRefreshCoordinator
    let inventoryCompletionService: any InventoryCompletionService
    let hapticFeedbackService: any HapticFeedbackService
    let rssDiscoveryService: any RSSDiscoveryService
    let discoveryCoordinator: KnowledgeDiscoveryCoordinator
    let weatherForecastRepository: any WeatherForecastRepository
    let weatherForecastService: any WeatherForecastService
    let weatherAlertService: any WeatherAlertService
    let locationService: any LocationService
    let mapAnnotationProvider: any MapAnnotationProvider
    let tileCacheService: any TileCacheService

    @MainActor
    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let contentRepository = SwiftDataContentRepository(modelContext: modelContainer.mainContext)
        let baseInventoryRepository = SwiftDataInventoryRepository(modelContext: modelContainer.mainContext)
        let supplyTemplateRepository = BundledSupplyTemplateRepository()
        let checklistRepository = SwiftDataChecklistRepository(modelContext: modelContainer.mainContext)
        let emergencyContactRepository = SwiftDataEmergencyContactRepository(modelContext: modelContainer.mainContext)
        let baseNoteRepository = SwiftDataNoteRepository(modelContext: modelContainer.mainContext)
        let importedKnowledgeRepository = SwiftDataImportedKnowledgeRepository(modelContext: modelContainer.mainContext)
        let pendingOperationRepository = SwiftDataPendingOperationRepository(modelContext: modelContainer.mainContext)
        let searchService = try? LocalSearchService.makeDefault()
        let inventoryRepository: any InventoryRepository
        let noteRepository: any NoteRepository

        if let searchService {
            inventoryRepository = SearchIndexedInventoryRepository(
                base: baseInventoryRepository,
                searchService: searchService
            )
            noteRepository = SearchIndexedNoteRepository(
                base: baseNoteRepository,
                searchService: searchService
            )

            try? SearchIndexRebuilder(
                searchService: searchService,
                handbookRepository: contentRepository,
                quickCardRepository: contentRepository,
                inventoryRepository: inventoryRepository,
                checklistRepository: checklistRepository,
                noteRepository: noteRepository,
                importedKnowledgeRepository: importedKnowledgeRepository
            )
            .rebuild()
        } else {
            inventoryRepository = baseInventoryRepository
            noteRepository = baseNoteRepository
        }

        let capabilityDetector = DeviceCapabilityDetector()
        let answerGenerator = Self.makeAnswerGenerator(
            for: capabilityDetector.detectAnswerMode()
        )

        let retrievalService: (any RetrievalService)? = searchService.map { search in
            LocalRetrievalService(
                searchService: search,
                sensitivityClassifier: SensitivityPolicy(),
                capabilityDetector: capabilityDetector,
                answerGenerator: answerGenerator
            )
        }

        let inventoryExpiryNotificationService = InventoryExpiryNotificationService(
            inventoryRepository: inventoryRepository
        )

        let connectivityService = NWPathMonitorConnectivityService()
        connectivityService.start()

        let trustedSourceHTTPClient = URLSessionTrustedSourceHTTPClient(
            connectivityService: connectivityService
        )

        let importPipeline = ImportedKnowledgeImportPipeline(
            repository: importedKnowledgeRepository,
            searchService: searchService
        )

        let refreshCoordinator = ImportedKnowledgeRefreshCoordinator(
            importedKnowledgeRepository: importedKnowledgeRepository,
            pendingOperationRepository: pendingOperationRepository,
            connectivityService: connectivityService,
            httpClient: trustedSourceHTTPClient,
            importPipeline: importPipeline
        )

        let inventoryCompletionService = LocalInventoryCompletionService(
            capabilityDetector: capabilityDetector
        )
        let hapticFeedbackService = LiveHapticFeedbackService()

        let weatherForecastRepository = SwiftDataWeatherForecastRepository(
            modelContext: modelContainer.mainContext
        )
        let weatherForecastService = LiveWeatherKitForecastService()
        let weatherAlertService = LiveWeatherAlertService()
        let locationService = CLLocationManagerService()
        let mapAnnotationProvider = BundledMapAnnotationProvider()
        let tileCacheService = OSMTileCacheService()

        let rssDiscoveryService = LiveRSSDiscoveryService()
        let braveSearchCredentialStore = BraveSearchCredentialStore()

        let discoveryCoordinator = KnowledgeDiscoveryCoordinator(
            rssDiscoveryService: rssDiscoveryService,
            webSearchClientProvider: {
                guard let key = braveSearchCredentialStore.loadStoredAPIKey(),
                      !key.isEmpty else { return nil }
                return BraveSearchClient(apiKey: key)
            },
            httpClient: trustedSourceHTTPClient,
            importPipeline: importPipeline,
            importedKnowledgeRepository: importedKnowledgeRepository,
            connectivityService: connectivityService
        )

        return AppDependencies(
            handbookRepository: contentRepository,
            quickCardRepository: contentRepository,
            seedContentRepository: contentRepository,
            inventoryRepository: inventoryRepository,
            supplyTemplateRepository: supplyTemplateRepository,
            checklistRepository: checklistRepository,
            emergencyContactRepository: emergencyContactRepository,
            noteRepository: noteRepository,
            importedKnowledgeRepository: importedKnowledgeRepository,
            pendingOperationRepository: pendingOperationRepository,
            capabilityDetector: capabilityDetector,
            searchService: searchService,
            retrievalService: retrievalService,
            inventoryExpiryNotificationService: inventoryExpiryNotificationService,
            connectivityService: connectivityService,
            trustedSourceHTTPClient: trustedSourceHTTPClient,
            importPipeline: importPipeline,
            refreshCoordinator: refreshCoordinator,
            inventoryCompletionService: inventoryCompletionService,
            hapticFeedbackService: hapticFeedbackService,
            rssDiscoveryService: rssDiscoveryService,
            discoveryCoordinator: discoveryCoordinator,
            weatherForecastRepository: weatherForecastRepository,
            weatherForecastService: weatherForecastService,
            weatherAlertService: weatherAlertService,
            locationService: locationService,
            mapAnnotationProvider: mapAnnotationProvider,
            tileCacheService: tileCacheService
        )
    }

    private static func makeAnswerGenerator(
        for mode: AnswerMode
    ) -> (any GroundedAnswerGenerator)? {
        guard mode == .groundedGeneration else { return nil }

        #if canImport(FoundationModels)
        if #available(iOS 26, *) {
            return FoundationModelAdapter()
        }
        #endif

        return nil
    }
}
