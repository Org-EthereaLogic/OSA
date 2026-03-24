import SwiftData

struct AppDependencies {
    let handbookRepository: any HandbookRepository
    let quickCardRepository: any QuickCardRepository
    let seedContentRepository: any SeedContentRepository
    let inventoryRepository: any InventoryRepository
    let checklistRepository: any ChecklistRepository
    let noteRepository: any NoteRepository
    let searchService: (any SearchService)?
    let retrievalService: (any RetrievalService)?

    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let contentRepository = SwiftDataContentRepository(modelContext: modelContainer.mainContext)
        let inventoryRepository = SwiftDataInventoryRepository(modelContext: modelContainer.mainContext)
        let checklistRepository = SwiftDataChecklistRepository(modelContext: modelContainer.mainContext)
        let noteRepository = SwiftDataNoteRepository(modelContext: modelContainer.mainContext)
        let searchService = try? LocalSearchService.makeDefault()

        let retrievalService: (any RetrievalService)? = searchService.map { search in
            LocalRetrievalService(
                searchService: search,
                sensitivityClassifier: SensitivityPolicy(),
                capabilityDetector: DeviceCapabilityDetector()
            )
        }

        return AppDependencies(
            handbookRepository: contentRepository,
            quickCardRepository: contentRepository,
            seedContentRepository: contentRepository,
            inventoryRepository: inventoryRepository,
            checklistRepository: checklistRepository,
            noteRepository: noteRepository,
            searchService: searchService,
            retrievalService: retrievalService
        )
    }
}
