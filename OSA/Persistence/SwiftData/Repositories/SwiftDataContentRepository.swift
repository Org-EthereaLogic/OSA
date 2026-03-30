import Foundation
import SwiftData

final class SwiftDataContentRepository: HandbookRepository, QuickCardRepository, FieldReferenceRepository, SeedContentRepository, KnowledgePackContentRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func listChapters() throws -> [HandbookChapterSummary] {
        var descriptor = FetchDescriptor<PersistedHandbookChapter>(
            sortBy: [
                SortDescriptor(\.sortOrder),
                SortDescriptor(\.title)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor)
            .map { $0.toDomain().summaryValue }
    }

    func chapter(slug: String) throws -> HandbookChapter? {
        let targetSlug = slug
        let descriptor = FetchDescriptor<PersistedHandbookChapter>(
            predicate: #Predicate { $0.slug == targetSlug }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func chapter(id: UUID) throws -> HandbookChapter? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedHandbookChapter>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func section(id: UUID) throws -> HandbookSection? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedHandbookSection>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func listQuickCards() throws -> [QuickCard] {
        var descriptor = FetchDescriptor<PersistedQuickCard>(
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.title)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func quickCard(slug: String) throws -> QuickCard? {
        let targetSlug = slug
        let descriptor = FetchDescriptor<PersistedQuickCard>(
            predicate: #Predicate { $0.slug == targetSlug }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func quickCard(id: UUID) throws -> QuickCard? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedQuickCard>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func listEntries() throws -> [FieldReferenceEntry] {
        var descriptor = FetchDescriptor<PersistedFieldReferenceEntry>(
            sortBy: [
                SortDescriptor(\.categoryRawValue),
                SortDescriptor(\.sortOrder),
                SortDescriptor(\.title)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func listEntries(category: FieldReferenceCategory) throws -> [FieldReferenceEntry] {
        let targetCategory = category.rawValue
        var descriptor = FetchDescriptor<PersistedFieldReferenceEntry>(
            predicate: #Predicate { $0.categoryRawValue == targetCategory },
            sortBy: [
                SortDescriptor(\.sortOrder),
                SortDescriptor(\.title)
            ]
        )
        descriptor.includePendingChanges = true

        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func entry(slug: String) throws -> FieldReferenceEntry? {
        let targetSlug = slug
        let descriptor = FetchDescriptor<PersistedFieldReferenceEntry>(
            predicate: #Predicate { $0.slug == targetSlug }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func entry(id: UUID) throws -> FieldReferenceEntry? {
        let targetID = id
        let descriptor = FetchDescriptor<PersistedFieldReferenceEntry>(
            predicate: #Predicate { $0.id == targetID }
        )

        return try modelContext.fetch(descriptor).first?.toDomain()
    }

    func currentSeedVersionState() throws -> SeedContentVersionState? {
        let states = try modelContext.fetch(FetchDescriptor<PersistedSeedContentState>())
        return states.first(where: { $0.identifier == PersistedSeedContentState.singletonIdentifier })?.toDomain()
    }

    @discardableResult
    func upsertSeedContent(_ bundle: SeedContentBundle, importedAt: Date) throws -> SeedImportOutcome {
        if let currentState = try currentSeedVersionState(),
           currentState.schemaVersion == bundle.manifest.schemaVersion,
           currentState.contentPackVersion == bundle.manifest.contentPackVersion {
            return SeedImportOutcome(
                status: .skippedAlreadyCurrent,
                versionState: currentState,
                chapterCount: bundle.chapters.count,
                sectionCount: bundle.chapters.reduce(into: 0) { $0 += $1.sections.count },
                quickCardCount: bundle.quickCards.count,
                checklistTemplateCount: bundle.checklistTemplates.count,
                fieldReferenceCount: bundle.fieldReferences.count
            )
        }

        let existingChapters = try modelContext.fetch(FetchDescriptor<PersistedHandbookChapter>())
        let existingQuickCards = try modelContext.fetch(FetchDescriptor<PersistedQuickCard>())
        let existingFieldReferences = try modelContext.fetch(FetchDescriptor<PersistedFieldReferenceEntry>())
        let existingState = try modelContext.fetch(FetchDescriptor<PersistedSeedContentState>()).first

        let existingChaptersByID = Dictionary(uniqueKeysWithValues: existingChapters.map { ($0.id, $0) })
        let existingQuickCardsByID = Dictionary(uniqueKeysWithValues: existingQuickCards.map { ($0.id, $0) })
        let existingFieldReferencesByID = Dictionary(uniqueKeysWithValues: existingFieldReferences.map { ($0.id, $0) })

        var incomingChapterIDs = Set<UUID>()
        var incomingQuickCardIDs = Set<UUID>()
        var incomingFieldReferenceIDs = Set<UUID>()

        for chapter in bundle.chapters.sorted(by: chapterSort) {
            incomingChapterIDs.insert(chapter.id)

            let chapterRecord = existingChaptersByID[chapter.id] ?? {
                let newRecord = PersistedHandbookChapter(from: chapter)
                modelContext.insert(newRecord)
                return newRecord
            }()

            chapterRecord.update(from: chapter)

            let existingSectionsByID = Dictionary(uniqueKeysWithValues: chapterRecord.sections.map { ($0.id, $0) })
            var incomingSectionIDs = Set<UUID>()

            for section in chapter.sections.sorted(by: sectionSort) {
                incomingSectionIDs.insert(section.id)

                if let existingSection = existingSectionsByID[section.id] {
                    existingSection.update(from: section, chapter: chapterRecord)
                } else {
                    let newSection = PersistedHandbookSection(from: section, chapter: chapterRecord)
                    modelContext.insert(newSection)
                }
            }

            for existingSection in Array(chapterRecord.sections) where !incomingSectionIDs.contains(existingSection.id) {
                modelContext.delete(existingSection)
            }
        }

        for chapterRecord in existingChapters where !incomingChapterIDs.contains(chapterRecord.id) {
            modelContext.delete(chapterRecord)
        }

        for quickCard in bundle.quickCards.sorted(by: quickCardSort) {
            incomingQuickCardIDs.insert(quickCard.id)

            if let existingQuickCard = existingQuickCardsByID[quickCard.id] {
                existingQuickCard.update(from: quickCard)
            } else {
                modelContext.insert(PersistedQuickCard(from: quickCard))
            }
        }

        for quickCardRecord in existingQuickCards where !incomingQuickCardIDs.contains(quickCardRecord.id) {
            modelContext.delete(quickCardRecord)
        }

        for fieldReference in bundle.fieldReferences.sorted(by: fieldReferenceSort) {
            incomingFieldReferenceIDs.insert(fieldReference.id)

            if let existingFieldReference = existingFieldReferencesByID[fieldReference.id] {
                existingFieldReference.update(from: fieldReference)
            } else {
                modelContext.insert(PersistedFieldReferenceEntry(from: fieldReference))
            }
        }

        for fieldReferenceRecord in existingFieldReferences where !incomingFieldReferenceIDs.contains(fieldReferenceRecord.id) {
            modelContext.delete(fieldReferenceRecord)
        }

        // Upsert checklist templates
        let existingTemplates = try modelContext.fetch(FetchDescriptor<PersistedChecklistTemplate>())
        let existingTemplatesByID = Dictionary(uniqueKeysWithValues: existingTemplates.map { ($0.id, $0) })
        var incomingTemplateIDs = Set<UUID>()

        for template in bundle.checklistTemplates {
            incomingTemplateIDs.insert(template.id)

            let templateRecord = existingTemplatesByID[template.id] ?? {
                let newRecord = PersistedChecklistTemplate(from: template)
                modelContext.insert(newRecord)
                return newRecord
            }()

            templateRecord.update(from: template)

            let existingItemsByID = Dictionary(uniqueKeysWithValues: templateRecord.items.map { ($0.id, $0) })
            var incomingItemIDs = Set<UUID>()

            for item in template.items {
                incomingItemIDs.insert(item.id)

                if let existingItem = existingItemsByID[item.id] {
                    existingItem.update(from: item)
                } else {
                    let newItem = PersistedChecklistTemplateItem(from: item, template: templateRecord)
                    modelContext.insert(newItem)
                }
            }

            for existingItem in Array(templateRecord.items) where !incomingItemIDs.contains(existingItem.id) {
                modelContext.delete(existingItem)
            }
        }

        for templateRecord in existingTemplates where !incomingTemplateIDs.contains(templateRecord.id) {
            modelContext.delete(templateRecord)
        }

        let updatedState = SeedContentVersionState(
            schemaVersion: bundle.manifest.schemaVersion,
            contentPackVersion: bundle.manifest.contentPackVersion,
            appliedAt: importedAt
        )

        if let existingState {
            existingState.schemaVersion = updatedState.schemaVersion
            existingState.contentPackVersion = updatedState.contentPackVersion
            existingState.appliedAt = updatedState.appliedAt
        } else {
            modelContext.insert(
                PersistedSeedContentState(
                    schemaVersion: updatedState.schemaVersion,
                    contentPackVersion: updatedState.contentPackVersion,
                    appliedAt: updatedState.appliedAt
                )
            )
        }

        try modelContext.save()

        return SeedImportOutcome(
            status: existingState == nil ? .imported : .updated,
            versionState: updatedState,
            chapterCount: bundle.chapters.count,
            sectionCount: bundle.chapters.reduce(into: 0) { $0 += $1.sections.count },
            quickCardCount: bundle.quickCards.count,
            checklistTemplateCount: bundle.checklistTemplates.count,
            fieldReferenceCount: bundle.fieldReferences.count
        )
    }

    @discardableResult
    func installKnowledgePack(
        _ bundle: SeedContentBundle,
        previousRecordSet: KnowledgePackRecordSet?,
        importedAt: Date
    ) throws -> KnowledgePackInstallResult {
        let existingChapters = try modelContext.fetch(FetchDescriptor<PersistedHandbookChapter>())
        let existingQuickCards = try modelContext.fetch(FetchDescriptor<PersistedQuickCard>())
        let existingFieldReferences = try modelContext.fetch(FetchDescriptor<PersistedFieldReferenceEntry>())
        let existingTemplates = try modelContext.fetch(FetchDescriptor<PersistedChecklistTemplate>())

        let existingChaptersByID = Dictionary(uniqueKeysWithValues: existingChapters.map { ($0.id, $0) })
        let existingQuickCardsByID = Dictionary(uniqueKeysWithValues: existingQuickCards.map { ($0.id, $0) })
        let existingFieldReferencesByID = Dictionary(uniqueKeysWithValues: existingFieldReferences.map { ($0.id, $0) })
        let existingTemplatesByID = Dictionary(uniqueKeysWithValues: existingTemplates.map { ($0.id, $0) })

        let incomingChapterIDs = Set(bundle.chapters.map(\.id))
        let incomingQuickCardIDs = Set(bundle.quickCards.map(\.id))
        let incomingFieldReferenceIDs = Set(bundle.fieldReferences.map(\.id))
        let incomingTemplateIDs = Set(bundle.checklistTemplates.map(\.id))

        for chapter in bundle.chapters.sorted(by: chapterSort) {
            let chapterRecord = existingChaptersByID[chapter.id] ?? {
                let newRecord = PersistedHandbookChapter(from: chapter)
                modelContext.insert(newRecord)
                return newRecord
            }()

            chapterRecord.update(from: chapter)

            let existingSectionsByID = Dictionary(uniqueKeysWithValues: chapterRecord.sections.map { ($0.id, $0) })
            let incomingSectionIDs = Set(chapter.sections.map(\.id))

            for section in chapter.sections.sorted(by: sectionSort) {
                if let existingSection = existingSectionsByID[section.id] {
                    existingSection.update(from: section, chapter: chapterRecord)
                } else {
                    modelContext.insert(PersistedHandbookSection(from: section, chapter: chapterRecord))
                }
            }

            for existingSection in Array(chapterRecord.sections) where !incomingSectionIDs.contains(existingSection.id) {
                modelContext.delete(existingSection)
            }
        }

        if let previousChapterIDs = previousRecordSet?.chapterIDs {
            for chapterID in previousChapterIDs where !incomingChapterIDs.contains(chapterID) {
                if let chapterRecord = existingChaptersByID[chapterID] {
                    modelContext.delete(chapterRecord)
                }
            }
        }

        for quickCard in bundle.quickCards.sorted(by: quickCardSort) {
            if let existingQuickCard = existingQuickCardsByID[quickCard.id] {
                existingQuickCard.update(from: quickCard)
            } else {
                modelContext.insert(PersistedQuickCard(from: quickCard))
            }
        }

        if let previousQuickCardIDs = previousRecordSet?.quickCardIDs {
            for quickCardID in previousQuickCardIDs where !incomingQuickCardIDs.contains(quickCardID) {
                if let quickCardRecord = existingQuickCardsByID[quickCardID] {
                    modelContext.delete(quickCardRecord)
                }
            }
        }

        for fieldReference in bundle.fieldReferences.sorted(by: fieldReferenceSort) {
            if let existingFieldReference = existingFieldReferencesByID[fieldReference.id] {
                existingFieldReference.update(from: fieldReference)
            } else {
                modelContext.insert(PersistedFieldReferenceEntry(from: fieldReference))
            }
        }

        if let previousFieldReferenceIDs = previousRecordSet?.fieldReferenceIDs {
            for fieldReferenceID in previousFieldReferenceIDs where !incomingFieldReferenceIDs.contains(fieldReferenceID) {
                if let fieldReferenceRecord = existingFieldReferencesByID[fieldReferenceID] {
                    modelContext.delete(fieldReferenceRecord)
                }
            }
        }

        for template in bundle.checklistTemplates {
            let templateRecord = existingTemplatesByID[template.id] ?? {
                let newRecord = PersistedChecklistTemplate(from: template)
                modelContext.insert(newRecord)
                return newRecord
            }()

            templateRecord.update(from: template)

            let existingItemsByID = Dictionary(uniqueKeysWithValues: templateRecord.items.map { ($0.id, $0) })
            let incomingItemIDs = Set(template.items.map(\.id))

            for item in template.items {
                if let existingItem = existingItemsByID[item.id] {
                    existingItem.update(from: item)
                } else {
                    modelContext.insert(PersistedChecklistTemplateItem(from: item, template: templateRecord))
                }
            }

            for existingItem in Array(templateRecord.items) where !incomingItemIDs.contains(existingItem.id) {
                modelContext.delete(existingItem)
            }
        }

        if let previousTemplateIDs = previousRecordSet?.checklistTemplateIDs {
            for templateID in previousTemplateIDs where !incomingTemplateIDs.contains(templateID) {
                if let templateRecord = existingTemplatesByID[templateID] {
                    modelContext.delete(templateRecord)
                }
            }
        }

        _ = importedAt
        try modelContext.save()

        return KnowledgePackInstallResult(
            recordSet: KnowledgePackRecordSet(
                chapterIDs: bundle.chapters.map(\.id),
                quickCardIDs: bundle.quickCards.map(\.id),
                checklistTemplateIDs: bundle.checklistTemplates.map(\.id),
                fieldReferenceIDs: bundle.fieldReferences.map(\.id)
            ),
            chapterCount: bundle.chapters.count,
            quickCardCount: bundle.quickCards.count,
            checklistTemplateCount: bundle.checklistTemplates.count,
            fieldReferenceCount: bundle.fieldReferences.count
        )
    }

    private func chapterSort(lhs: HandbookChapter, rhs: HandbookChapter) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        return lhs.sortOrder < rhs.sortOrder
    }

    private func sectionSort(lhs: HandbookSection, rhs: HandbookSection) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.heading.localizedCaseInsensitiveCompare(rhs.heading) == .orderedAscending
        }

        return lhs.sortOrder < rhs.sortOrder
    }

    private func quickCardSort(lhs: QuickCard, rhs: QuickCard) -> Bool {
        if lhs.priority == rhs.priority {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }

        return lhs.priority > rhs.priority
    }

    private func fieldReferenceSort(lhs: FieldReferenceEntry, rhs: FieldReferenceEntry) -> Bool {
        if lhs.category == rhs.category {
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }

            return lhs.sortOrder < rhs.sortOrder
        }

        return lhs.category.rawValue.localizedCaseInsensitiveCompare(rhs.category.rawValue) == .orderedAscending
    }
}
