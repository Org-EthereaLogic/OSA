import Foundation

enum SeedContentLoaderError: Error, Equatable {
    case missingSeedContentDirectory
    case missingManifest
    case missingPackFile(String)
    case recordCountMismatch(expected: Int, actual: Int, fileName: String)
    case missingReferencedSection(quickCardID: UUID, sectionID: UUID)
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

        for pack in manifest.packs {
            switch pack.kind {
            case .handbookChapters:
                let packChapters = try loadHandbookPack(named: pack.fileName)
                try validateRecordCount(
                    expected: pack.recordCount,
                    actual: packChapters.count,
                    fileName: pack.fileName
                )
                chapters.append(contentsOf: packChapters)
            case .quickCards:
                let packQuickCards = try loadQuickCardPack(named: pack.fileName)
                try validateRecordCount(
                    expected: pack.recordCount,
                    actual: packQuickCards.count,
                    fileName: pack.fileName
                )
                quickCards.append(contentsOf: packQuickCards)
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

        return SeedContentBundle(
            manifest: manifest,
            chapters: chapters.sorted(by: chapterSort),
            quickCards: quickCards.sorted(by: quickCardSort)
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

    private func loadHandbookPack(named fileName: String) throws -> [HandbookChapter] {
        let fileURL = directoryURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SeedContentLoaderError.missingPackFile(fileName)
        }

        let pack = try decoder.decode(HandbookSeedPackFile.self, from: Data(contentsOf: fileURL))
        return pack.chapters.map(\.toDomain)
    }

    private func loadQuickCardPack(named fileName: String) throws -> [QuickCard] {
        let fileURL = directoryURL.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            throw SeedContentLoaderError.missingPackFile(fileName)
        }

        let pack = try decoder.decode(QuickCardSeedPackFile.self, from: Data(contentsOf: fileURL))
        return pack.quickCards.map(\.toDomain)
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
            packs: packs.map(\.toDomain)
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
            largeTypeLayoutVersion: largeTypeLayoutVersion
        )
    }
}
