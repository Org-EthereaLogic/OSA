import Foundation

protocol HandbookRepository {
    func listChapters() throws -> [HandbookChapterSummary]
    func chapter(slug: String) throws -> HandbookChapter?
    func chapter(id: UUID) throws -> HandbookChapter?
    func section(id: UUID) throws -> HandbookSection?
}

protocol QuickCardRepository {
    func listQuickCards() throws -> [QuickCard]
    func quickCard(slug: String) throws -> QuickCard?
    func quickCard(id: UUID) throws -> QuickCard?
}

protocol SeedContentRepository {
    func currentSeedVersionState() throws -> SeedContentVersionState?

    @discardableResult
    func upsertSeedContent(_ bundle: SeedContentBundle, importedAt: Date) throws -> SeedImportOutcome
}
