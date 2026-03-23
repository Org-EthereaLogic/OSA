import Foundation

enum SeedContentPackKind: String, Codable, Equatable, Sendable {
    case handbookChapters = "handbook-chapters"
    case quickCards = "quick-cards"
}

struct SeedContentPackDescriptor: Equatable, Sendable {
    let identifier: String
    let kind: SeedContentPackKind
    let version: String
    let fileName: String
    let recordCount: Int
    let contentHash: String?
}

struct SeedContentManifest: Equatable, Sendable {
    let schemaVersion: Int
    let contentPackVersion: String
    let generatedAt: Date?
    let packs: [SeedContentPackDescriptor]
}

struct SeedContentBundle: Equatable, Sendable {
    let manifest: SeedContentManifest
    let chapters: [HandbookChapter]
    let quickCards: [QuickCard]
}

struct SeedContentVersionState: Equatable, Sendable {
    let schemaVersion: Int
    let contentPackVersion: String
    let appliedAt: Date
}

enum SeedImportStatus: Equatable, Sendable {
    case imported
    case updated
    case skippedAlreadyCurrent
}

struct SeedImportOutcome: Equatable, Sendable {
    let status: SeedImportStatus
    let versionState: SeedContentVersionState
    let chapterCount: Int
    let sectionCount: Int
    let quickCardCount: Int
}
