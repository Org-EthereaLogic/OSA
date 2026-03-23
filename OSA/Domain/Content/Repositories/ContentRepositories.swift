import Foundation

protocol HandbookRepository {
    func listChapters() throws -> [HandbookChapterSummary]
    func chapter(slug: String) throws -> HandbookChapter?
}

protocol QuickCardRepository {
    func listQuickCards() throws -> [QuickCard]
    func quickCard(slug: String) throws -> QuickCard?
}

protocol SeedContentRepository {
    func currentSeedVersionState() throws -> SeedContentVersionState?

    @discardableResult
    func upsertSeedContent(_ bundle: SeedContentBundle, importedAt: Date) throws -> SeedImportOutcome
}
