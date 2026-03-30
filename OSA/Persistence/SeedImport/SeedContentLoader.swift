import CryptoKit
import Foundation

enum SeedContentLoaderError: Error, Equatable {
    case missingSeedContentDirectory
    case missingManifest
    case missingPackFile(String)
    case missingContentHash(fileName: String)
    case contentHashMismatch(expected: String, actual: String, fileName: String)
    case recordCountMismatch(expected: Int, actual: Int, fileName: String)
    case missingReferencedSection(quickCardID: UUID, sectionID: UUID)
    case missingReferencedSectionForFieldReference(fieldReferenceID: UUID, sectionID: UUID)
    case missingMediaAsset(contentID: UUID, path: String)
    case invalidMediaReference(contentID: UUID, path: String)
    case invalidQuizDefinition(contentID: UUID, message: String)
}

struct SeedContentLoader {
    private static let seedSubdirectory = "SeedContent"

    let directoryURL: URL

    static func bundled(in bundle: Bundle = .main) throws -> SeedContentLoader {
        guard let resourceURL = bundle.resourceURL else {
            throw SeedContentLoaderError.missingSeedContentDirectory
        }

        let directoryURL = resourceURL.appendingPathComponent(seedSubdirectory, isDirectory: true)

        guard FileManager.default.fileExists(atPath: directoryURL.path) else {
            throw SeedContentLoaderError.missingSeedContentDirectory
        }

        return SeedContentLoader(directoryURL: directoryURL)
    }

    func loadBundle() throws -> SeedContentBundle {
        let manifest = try loadManifest()
        var chapters: [HandbookChapter] = []
        var quickCards: [QuickCard] = []
        var checklistTemplates: [ChecklistTemplate] = []
        var fieldReferences: [FieldReferenceEntry] = []

        for pack in manifest.packs {
            let packData = try loadPackData(named: pack.fileName)
            try validateContentHash(
                expected: pack.contentHash,
                data: packData,
                fileName: pack.fileName
            )

            switch pack.kind {
            case .handbookChapters:
                let packChapters = try decodeHandbookPack(from: packData)
                try validateRecordCount(
                    expected: pack.recordCount,
                    actual: packChapters.count,
                    fileName: pack.fileName
                )
                chapters.append(contentsOf: packChapters)
            case .quickCards:
                let packQuickCards = try decodeQuickCardPack(from: packData)
                try validateRecordCount(
                    expected: pack.recordCount,
                    actual: packQuickCards.count,
                    fileName: pack.fileName
                )
                quickCards.append(contentsOf: packQuickCards)
            case .checklistTemplates:
                let packTemplates = try decodeChecklistTemplatePack(from: packData)
                try validateRecordCount(
                    expected: pack.recordCount,
                    actual: packTemplates.count,
                    fileName: pack.fileName
                )
                checklistTemplates.append(contentsOf: packTemplates)
            case .fieldReferences:
                let packFieldReferences = try decodeFieldReferencePack(from: packData)
                try validateRecordCount(
                    expected: pack.recordCount,
                    actual: packFieldReferences.count,
                    fileName: pack.fileName
                )
                fieldReferences.append(contentsOf: packFieldReferences)
            }
        }

        let sectionIDs = Set(chapters.flatMap(\.sections).map(\.id))
        for quickCard in quickCards {
            for sectionID in quickCard.relatedSectionIDs where !sectionIDs.contains(sectionID) {
                throw SeedContentLoaderError.missingReferencedSection(
                    quickCardID: quickCard.id,
                    sectionID: sectionID
                )
            }
        }

        for fieldReference in fieldReferences {
            for sectionID in fieldReference.relatedSectionIDs where !sectionIDs.contains(sectionID) {
                throw SeedContentLoaderError.missingReferencedSectionForFieldReference(
                    fieldReferenceID: fieldReference.id,
                    sectionID: sectionID
                )
            }
        }

        let resourceRootURL = directoryURL.deletingLastPathComponent()
        try validateEnhancements(for: quickCards, resourceRootURL: resourceRootURL)
        try validateEnhancements(for: fieldReferences, resourceRootURL: resourceRootURL)

        return SeedContentBundle(
            manifest: manifest,
            chapters: chapters.sorted(by: chapterSort),
            quickCards: quickCards.sorted(by: quickCardSort),
            checklistTemplates: checklistTemplates.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending },
            fieldReferences: fieldReferences.sorted(by: fieldReferenceSort)
        )
    }

    private func loadManifest() throws -> SeedContentManifest {
        let fileURL = directoryURL.appendingPathComponent("SeedManifest.json")

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SeedContentLoaderError.missingManifest
        }

        let manifestFile = try decoder.decode(SeedManifestFile.self, from: Data(contentsOf: fileURL))
        return manifestFile.toDomain()
    }

    private func loadPackData(named fileName: String) throws -> Data {
        let fileURL = directoryURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SeedContentLoaderError.missingPackFile(fileName)
        }

        return try Data(contentsOf: fileURL)
    }

    private func decodeHandbookPack(from data: Data) throws -> [HandbookChapter] {
        let pack = try decoder.decode(HandbookSeedPackFile.self, from: data)
        return pack.chapters.map(\.toDomain)
    }

    private func decodeQuickCardPack(from data: Data) throws -> [QuickCard] {
        let pack = try decoder.decode(QuickCardSeedPackFile.self, from: data)
        return pack.quickCards.map(\.toDomain)
    }

    private func decodeChecklistTemplatePack(from data: Data) throws -> [ChecklistTemplate] {
        let pack = try decoder.decode(ChecklistTemplateSeedPackFile.self, from: data)
        return pack.templates.map(\.toDomain)
    }

    private func decodeFieldReferencePack(from data: Data) throws -> [FieldReferenceEntry] {
        let pack = try decoder.decode(FieldReferenceSeedPackFile.self, from: data)
        return pack.entries.map(\.toDomain)
    }

    private func validateContentHash(expected: String?, data: Data, fileName: String) throws {
        guard let expected, !expected.isEmpty else {
            throw SeedContentLoaderError.missingContentHash(fileName: fileName)
        }

        let actual = sha256Hex(for: data)
        guard actual.caseInsensitiveCompare(expected) == .orderedSame else {
            throw SeedContentLoaderError.contentHashMismatch(
                expected: expected,
                actual: actual,
                fileName: fileName
            )
        }
    }

    private func validateRecordCount(expected: Int, actual: Int, fileName: String) throws {
        guard expected == actual else {
            throw SeedContentLoaderError.recordCountMismatch(
                expected: expected,
                actual: actual,
                fileName: fileName
            )
        }
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    private func sha256Hex(for data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func chapterSort(lhs: HandbookChapter, rhs: HandbookChapter) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
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

    private func validateEnhancements(for quickCards: [QuickCard], resourceRootURL: URL) throws {
        for quickCard in quickCards {
            try validateMediaAttachments(
                quickCard.mediaAttachments,
                contentID: quickCard.id,
                resourceRootURL: resourceRootURL
            )
            try validateQuizDefinition(quickCard.quizDefinition, contentID: quickCard.id)
        }
    }

    private func validateEnhancements(for fieldReferences: [FieldReferenceEntry], resourceRootURL: URL) throws {
        for fieldReference in fieldReferences {
            try validateMediaAttachments(
                fieldReference.mediaAttachments,
                contentID: fieldReference.id,
                resourceRootURL: resourceRootURL
            )
            try validateQuizDefinition(fieldReference.quizDefinition, contentID: fieldReference.id)
        }
    }

    private func validateMediaAttachments(
        _ attachments: [LocalMediaAttachment],
        contentID: UUID,
        resourceRootURL: URL
    ) throws {
        for attachment in attachments {
            let bundlePath = attachment.bundlePath.trimmingCharacters(in: .whitespacesAndNewlines)

            guard !bundlePath.isEmpty,
                  !bundlePath.contains("://"),
                  !bundlePath.hasPrefix("/") else {
                throw SeedContentLoaderError.invalidMediaReference(
                    contentID: contentID,
                    path: attachment.bundlePath
                )
            }

            switch attachment.kind {
            case .inlineSVG:
                guard bundlePath.lowercased().hasSuffix(".svg") else {
                    throw SeedContentLoaderError.invalidMediaReference(contentID: contentID, path: attachment.bundlePath)
                }
            case .shortVideo:
                guard bundlePath.lowercased().hasSuffix(".mp4") else {
                    throw SeedContentLoaderError.invalidMediaReference(contentID: contentID, path: attachment.bundlePath)
                }
            }

            let assetURL = resourceRootURL.appendingPathComponent(bundlePath)
            guard FileManager.default.fileExists(atPath: assetURL.path) else {
                throw SeedContentLoaderError.missingMediaAsset(
                    contentID: contentID,
                    path: attachment.bundlePath
                )
            }
        }
    }

    private func validateQuizDefinition(_ quizDefinition: QuizDefinition?, contentID: UUID) throws {
        guard let quizDefinition else { return }

        guard !quizDefinition.questions.isEmpty else {
            throw SeedContentLoaderError.invalidQuizDefinition(
                contentID: contentID,
                message: "Quiz definitions must contain at least one question."
            )
        }

        guard (0...100).contains(quizDefinition.masteryScorePercent) else {
            throw SeedContentLoaderError.invalidQuizDefinition(
                contentID: contentID,
                message: "Mastery score percent must be between 0 and 100."
            )
        }

        for question in quizDefinition.questions {
            guard !question.options.isEmpty else {
                throw SeedContentLoaderError.invalidQuizDefinition(
                    contentID: contentID,
                    message: "Question \(question.id) must contain answer options."
                )
            }

            guard question.correctOption != nil else {
                throw SeedContentLoaderError.invalidQuizDefinition(
                    contentID: contentID,
                    message: "Question \(question.id) has an invalid correct option."
                )
            }
        }
    }
}

private struct SeedManifestFile: Decodable {
    let schemaVersion: Int
    let contentPackVersion: String
    let generatedAt: Date?
    let packs: [SeedContentPackDescriptorFile]

    func toDomain() -> SeedContentManifest {
        SeedContentManifest(
            schemaVersion: schemaVersion,
            contentPackVersion: contentPackVersion,
            generatedAt: generatedAt,
            packs: packs.map { $0.toDomain() }
        )
    }
}

private struct SeedContentPackDescriptorFile: Decodable {
    let identifier: String
    let kind: SeedContentPackKind
    let version: String
    let fileName: String
    let recordCount: Int
    let contentHash: String?

    func toDomain() -> SeedContentPackDescriptor {
        SeedContentPackDescriptor(
            identifier: identifier,
            kind: kind,
            version: version,
            fileName: fileName,
            recordCount: recordCount,
            contentHash: contentHash
        )
    }
}

private struct HandbookSeedPackFile: Decodable {
    let chapters: [HandbookChapterFile]
}

private struct HandbookChapterFile: Decodable {
    let id: UUID
    let slug: String
    let title: String
    let summary: String
    let sortOrder: Int
    let tags: [String]
    let version: Int
    let isSeeded: Bool
    let lastReviewedAt: Date?
    let sections: [HandbookSectionFile]

    var toDomain: HandbookChapter {
        HandbookChapter(
            id: id,
            slug: slug,
            title: title,
            summary: summary,
            sortOrder: sortOrder,
            tags: tags,
            version: version,
            isSeeded: isSeeded,
            lastReviewedAt: lastReviewedAt,
            sections: sections.map(\.toDomain).sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.heading.localizedCaseInsensitiveCompare($1.heading) == .orderedAscending
                }

                return $0.sortOrder < $1.sortOrder
            }
        )
    }
}

private struct HandbookSectionFile: Decodable {
    let id: UUID
    let chapterID: UUID
    let parentSectionID: UUID?
    let heading: String
    let bodyMarkdown: String
    let plainText: String
    let sortOrder: Int
    let tags: [String]
    let safetyLevel: HandbookSafetyLevel
    let chunkGroupID: String
    let version: Int
    let lastReviewedAt: Date?

    var toDomain: HandbookSection {
        HandbookSection(
            id: id,
            chapterID: chapterID,
            parentSectionID: parentSectionID,
            heading: heading,
            bodyMarkdown: bodyMarkdown,
            plainText: plainText,
            sortOrder: sortOrder,
            tags: tags,
            safetyLevel: safetyLevel,
            chunkGroupID: chunkGroupID,
            version: version,
            lastReviewedAt: lastReviewedAt
        )
    }
}

private struct ChecklistTemplateSeedPackFile: Decodable {
    let templates: [ChecklistTemplateFile]
}

private struct ChecklistTemplateFile: Decodable {
    let id: UUID
    let title: String
    let slug: String
    let category: String
    let description: String
    let estimatedMinutes: Int
    let tags: [String]
    let sourceType: ChecklistSourceType
    let presentationStyle: ChecklistPresentationStyle?
    let timerProfile: ChecklistTimerProfile?
    let lastReviewedAt: Date?
    let items: [ChecklistTemplateItemFile]

    var toDomain: ChecklistTemplate {
        ChecklistTemplate(
            id: id,
            title: title,
            slug: slug,
            category: category,
            description: description,
            estimatedMinutes: estimatedMinutes,
            tags: tags,
            sourceType: sourceType,
            presentationStyle: presentationStyle ?? .standard,
            timerProfile: timerProfile,
            lastReviewedAt: lastReviewedAt,
            items: items.enumerated().map { index, item in
                item.toDomain(templateID: id, defaultSortOrder: (index + 1) * 100)
            }
        )
    }
}

private struct ChecklistTemplateItemFile: Decodable {
    let id: UUID
    let text: String
    let detail: String?
    let sortOrder: Int?
    let isOptional: Bool
    let riskLevel: String?

    func toDomain(templateID: UUID, defaultSortOrder: Int) -> ChecklistTemplateItem {
        ChecklistTemplateItem(
            id: id,
            templateID: templateID,
            text: text,
            detail: detail,
            sortOrder: sortOrder ?? defaultSortOrder,
            isOptional: isOptional,
            riskLevel: riskLevel
        )
    }
}

private struct QuickCardSeedPackFile: Decodable {
    let quickCards: [QuickCardFile]
}

private struct QuickCardFile: Decodable {
    let id: UUID
    let title: String
    let slug: String
    let category: String
    let summary: String
    let bodyMarkdown: String
    let priority: Int
    let relatedSectionIDs: [UUID]
    let tags: [String]
    let lastReviewedAt: Date?
    let largeTypeLayoutVersion: Int
    let mediaAttachments: [LocalMediaAttachment]?
    let quizDefinition: QuizDefinition?
    let weeklyDrillMetadata: WeeklyDrillMetadata?

    var toDomain: QuickCard {
        QuickCard(
            id: id,
            title: title,
            slug: slug,
            category: category,
            summary: summary,
            bodyMarkdown: bodyMarkdown,
            priority: priority,
            relatedSectionIDs: relatedSectionIDs,
            tags: tags,
            lastReviewedAt: lastReviewedAt,
            largeTypeLayoutVersion: largeTypeLayoutVersion,
            mediaAttachments: mediaAttachments ?? [],
            quizDefinition: quizDefinition,
            weeklyDrillMetadata: weeklyDrillMetadata
        )
    }
}

private struct FieldReferenceSeedPackFile: Decodable {
    let entries: [FieldReferenceEntryFile]
}

private struct FieldReferenceEntryFile: Decodable {
    let id: UUID
    let slug: String
    let title: String
    let category: FieldReferenceCategory
    let summary: String
    let sortOrder: Int
    let sections: [FieldReferenceSectionFile]
    let relatedSectionIDs: [UUID]
    let tags: [String]
    let safetyLevel: HandbookSafetyLevel
    let lastReviewedAt: Date?
    let mediaAttachments: [LocalMediaAttachment]?
    let quizDefinition: QuizDefinition?

    var toDomain: FieldReferenceEntry {
        FieldReferenceEntry(
            id: id,
            slug: slug,
            title: title,
            category: category,
            summary: summary,
            sortOrder: sortOrder,
            sections: sections.map(\.toDomain),
            relatedSectionIDs: relatedSectionIDs,
            tags: tags,
            safetyLevel: safetyLevel,
            lastReviewedAt: lastReviewedAt,
            mediaAttachments: mediaAttachments ?? [],
            quizDefinition: quizDefinition
        )
    }
}

private struct FieldReferenceSectionFile: Decodable {
    let title: String
    let bodyMarkdown: String
    let plainText: String
    let sortOrder: Int

    var toDomain: FieldReferenceSection {
        FieldReferenceSection(
            title: title,
            bodyMarkdown: bodyMarkdown,
            plainText: plainText,
            sortOrder: sortOrder
        )
    }
}
