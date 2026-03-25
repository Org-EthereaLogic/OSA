import SwiftData

struct AppDependencies {
    let handbookRepository: any HandbookRepository
    let quickCardRepository: any QuickCardRepository
    let seedContentRepository: any SeedContentRepository
    let inventoryRepository: any InventoryRepository
    let checklistRepository: any ChecklistRepository
    let noteRepository: any NoteRepository
    let capabilityDetector: any CapabilityDetector
    let searchService: (any SearchService)?
    let retrievalService: (any RetrievalService)?

    @MainActor
    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let contentRepository = SwiftDataContentRepository(modelContext: modelContainer.mainContext)
        let inventoryRepository = SwiftDataInventoryRepository(modelContext: modelContainer.mainContext)
        let checklistRepository = SwiftDataChecklistRepository(modelContext: modelContainer.mainContext)
        let noteRepository = SwiftDataNoteRepository(modelContext: modelContainer.mainContext)
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

        return AppDependencies(
            handbookRepository: contentRepository,
            quickCardRepository: contentRepository,
            seedContentRepository: contentRepository,
            inventoryRepository: inventoryRepository,
            checklistRepository: checklistRepository,
            noteRepository: noteRepository,
            capabilityDetector: capabilityDetector,
            searchService: searchService,
            retrievalService: retrievalService
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
