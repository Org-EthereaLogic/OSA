import Foundation

extension PersistedHandbookChapter {
    convenience init(from chapter: HandbookChapter) {
        self.init(
            id: chapter.id,
            slug: chapter.slug,
            title: chapter.title,
            summary: chapter.summary,
            sortOrder: chapter.sortOrder,
            tagsJSON: PersistenceValueCoding.encode(chapter.tags),
            version: chapter.version,
            isSeeded: chapter.isSeeded,
            lastReviewedAt: chapter.lastReviewedAt
        )
    }

    func update(from chapter: HandbookChapter) {
        id = chapter.id
        slug = chapter.slug
        title = chapter.title
        summary = chapter.summary
        sortOrder = chapter.sortOrder
        tagsJSON = PersistenceValueCoding.encode(chapter.tags)
        version = chapter.version
        isSeeded = chapter.isSeeded
        lastReviewedAt = chapter.lastReviewedAt
    }

    func toDomain() -> HandbookChapter {
        HandbookChapter(
            id: id,
            slug: slug,
            title: title,
            summary: summary,
            sortOrder: sortOrder,
            tags: PersistenceValueCoding.decodeStrings(from: tagsJSON),
            version: version,
            isSeeded: isSeeded,
            lastReviewedAt: lastReviewedAt,
            sections: sections
                .sorted {
                    if $0.sortOrder == $1.sortOrder {
                        return $0.heading.localizedCaseInsensitiveCompare($1.heading) == .orderedAscending
                    }

                    return $0.sortOrder < $1.sortOrder
                }
                .map(\.toDomain)
        )
    }
}

extension PersistedHandbookSection {
    convenience init(from section: HandbookSection, chapter: PersistedHandbookChapter) {
        self.init(
            id: section.id,
            chapterID: section.chapterID,
            parentSectionID: section.parentSectionID,
            heading: section.heading,
            bodyMarkdown: section.bodyMarkdown,
            plainText: section.plainText,
            sortOrder: section.sortOrder,
            tagsJSON: PersistenceValueCoding.encode(section.tags),
            safetyLevelRawValue: section.safetyLevel.rawValue,
            chunkGroupID: section.chunkGroupID,
            version: section.version,
            lastReviewedAt: section.lastReviewedAt,
            chapter: chapter
        )
    }

    func update(from section: HandbookSection, chapter: PersistedHandbookChapter) {
        id = section.id
        chapterID = section.chapterID
        parentSectionID = section.parentSectionID
        heading = section.heading
        bodyMarkdown = section.bodyMarkdown
        plainText = section.plainText
        sortOrder = section.sortOrder
        tagsJSON = PersistenceValueCoding.encode(section.tags)
        safetyLevelRawValue = section.safetyLevel.rawValue
        chunkGroupID = section.chunkGroupID
        version = section.version
        lastReviewedAt = section.lastReviewedAt
        self.chapter = chapter
    }

    func toDomain() -> HandbookSection {
        HandbookSection(
            id: id,
            chapterID: chapterID,
            parentSectionID: parentSectionID,
            heading: heading,
            bodyMarkdown: bodyMarkdown,
            plainText: plainText,
            sortOrder: sortOrder,
            tags: PersistenceValueCoding.decodeStrings(from: tagsJSON),
            safetyLevel: HandbookSafetyLevel(rawValue: safetyLevelRawValue) ?? .normal,
            chunkGroupID: chunkGroupID,
            version: version,
            lastReviewedAt: lastReviewedAt
        )
    }
}

extension PersistedQuickCard {
    convenience init(from quickCard: QuickCard) {
        self.init(
            id: quickCard.id,
            slug: quickCard.slug,
            title: quickCard.title,
            category: quickCard.category,
            summary: quickCard.summary,
            bodyMarkdown: quickCard.bodyMarkdown,
            priority: quickCard.priority,
            relatedSectionIDsJSON: PersistenceValueCoding.encode(quickCard.relatedSectionIDs),
            tagsJSON: PersistenceValueCoding.encode(quickCard.tags),
            lastReviewedAt: quickCard.lastReviewedAt,
            largeTypeLayoutVersion: quickCard.largeTypeLayoutVersion
        )
    }

    func update(from quickCard: QuickCard) {
        id = quickCard.id
        slug = quickCard.slug
        title = quickCard.title
        category = quickCard.category
        summary = quickCard.summary
        bodyMarkdown = quickCard.bodyMarkdown
        priority = quickCard.priority
        relatedSectionIDsJSON = PersistenceValueCoding.encode(quickCard.relatedSectionIDs)
        tagsJSON = PersistenceValueCoding.encode(quickCard.tags)
        lastReviewedAt = quickCard.lastReviewedAt
        largeTypeLayoutVersion = quickCard.largeTypeLayoutVersion
    }

    func toDomain() -> QuickCard {
        QuickCard(
            id: id,
            title: title,
            slug: slug,
            category: category,
            summary: summary,
            bodyMarkdown: bodyMarkdown,
            priority: priority,
            relatedSectionIDs: PersistenceValueCoding.decodeUUIDs(from: relatedSectionIDsJSON),
            tags: PersistenceValueCoding.decodeStrings(from: tagsJSON),
            lastReviewedAt: lastReviewedAt,
            largeTypeLayoutVersion: largeTypeLayoutVersion
        )
    }
}

extension PersistedSeedContentState {
    func toDomain() -> SeedContentVersionState {
        SeedContentVersionState(
            schemaVersion: schemaVersion,
            contentPackVersion: contentPackVersion,
            appliedAt: appliedAt
        )
    }
}
