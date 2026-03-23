import SwiftData

struct AppDependencies {
    let handbookRepository: any HandbookRepository
    let quickCardRepository: any QuickCardRepository
    let seedContentRepository: any SeedContentRepository

    static func live(modelContainer: ModelContainer) -> AppDependencies {
        let contentRepository = SwiftDataContentRepository(modelContext: modelContainer.mainContext)

        return AppDependencies(
            handbookRepository: contentRepository,
            quickCardRepository: contentRepository,
            seedContentRepository: contentRepository
        )
    }
}
