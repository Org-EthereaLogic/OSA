import Foundation

struct SeedContentImporter {
    private let loader: SeedContentLoader
    private let repository: any SeedContentRepository
    private let now: () -> Date

    init(
        loader: SeedContentLoader,
        repository: any SeedContentRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.loader = loader
        self.repository = repository
        self.now = now
    }

    @discardableResult
    func importBundledContentIfNeeded() throws -> SeedImportOutcome {
        let bundle = try loader.loadBundle()
        return try repository.upsertSeedContent(bundle, importedAt: now())
    }
}
