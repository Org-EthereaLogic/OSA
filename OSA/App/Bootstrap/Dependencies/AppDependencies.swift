import Foundation
import SwiftData

struct AppDependencies {
    let handbookRepository: any HandbookRepository
    let quickCardRepository: any QuickCardRepository
    let seedContentRepository: any SeedContentRepository
    let inventoryRepository: any InventoryRepository
    let checklistRepository: any ChecklistRepository
    let noteRepository: any NoteRepository
    let importedKnowledgeRepository: any ImportedKnowledgeRepository
    let pendingOperationRepository: any PendingOperationRepository
    let capabilityDetector: any CapabilityDetector
    let searchService: (any SearchService)?
    let retrievalService: (any RetrievalService)?
    let connectivityService: any ConnectivityService
    let trustedSourceHTTPClient: any TrustedSourceHTTPClient
    let importPipeline: ImportedKnowledgeImportPipeline
    let refreshCoordinator: ImportedKnowledgeRefreshCoordinator
    let inventoryCompletionService: any InventoryCompletionService
    let discoveryCoordinator: KnowledgeDiscoveryCoordinator

    @MainActor
    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let contentRepository = SwiftDataContentRepository(modelContext: modelContainer.mainContext)
        let inventoryRepository = SwiftDataInventoryRepository(modelContext: modelContainer.mainContext)
        let checklistRepository = SwiftDataChecklistRepository(modelContext: modelContainer.mainContext)
        let noteRepository = SwiftDataNoteRepository(modelContext: modelContainer.mainContext)
        let importedKnowledgeRepository = SwiftDataImportedKnowledgeRepository(modelContext: modelContainer.mainContext)
        let pendingOperationRepository = SwiftDataPendingOperationRepository(modelContext: modelContainer.mainContext)
        let searchService = try? LocalSearchService.makeDefault()

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

        let rssDiscoveryService = LiveRSSDiscoveryService()
        let webSearchClient: (any WebSearchClient)? = {
            let apiKey = UserDefaults.standard.string(
                forKey: DiscoverySettings.braveSearchAPIKeyKey
            )
            guard let key = apiKey, !key.isEmpty else { return nil }
            return BraveSearchClient(apiKey: key)
        }()

        let discoveryCoordinator = KnowledgeDiscoveryCoordinator(
            rssDiscoveryService: rssDiscoveryService,
            webSearchClient: webSearchClient,
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
            checklistRepository: checklistRepository,
            noteRepository: noteRepository,
            importedKnowledgeRepository: importedKnowledgeRepository,
            pendingOperationRepository: pendingOperationRepository,
            capabilityDetector: capabilityDetector,
            searchService: searchService,
            retrievalService: retrievalService,
            connectivityService: connectivityService,
            trustedSourceHTTPClient: trustedSourceHTTPClient,
            importPipeline: importPipeline,
            refreshCoordinator: refreshCoordinator,
            inventoryCompletionService: inventoryCompletionService,
            discoveryCoordinator: discoveryCoordinator
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
