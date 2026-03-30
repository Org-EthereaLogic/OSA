import Foundation

enum SeedContentPackKind: String, Codable, Equatable, Sendable {
    case handbookChapters = "handbook-chapters"
    case quickCards = "quick-cards"
    case checklistTemplates = "checklist-templates"
    case fieldReferences = "field-references"
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
    let checklistTemplates: [ChecklistTemplate]
    let fieldReferences: [FieldReferenceEntry]

    init(
        manifest: SeedContentManifest,
        chapters: [HandbookChapter],
        quickCards: [QuickCard],
        checklistTemplates: [ChecklistTemplate],
        fieldReferences: [FieldReferenceEntry] = []
    ) {
        self.manifest = manifest
        self.chapters = chapters
        self.quickCards = quickCards
        self.checklistTemplates = checklistTemplates
        self.fieldReferences = fieldReferences
    }
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
    let checklistTemplateCount: Int
    let fieldReferenceCount: Int

    init(
        status: SeedImportStatus,
        versionState: SeedContentVersionState,
        chapterCount: Int,
        sectionCount: Int,
        quickCardCount: Int,
        checklistTemplateCount: Int,
        fieldReferenceCount: Int = 0
    ) {
        self.status = status
        self.versionState = versionState
        self.chapterCount = chapterCount
        self.sectionCount = sectionCount
        self.quickCardCount = quickCardCount
        self.checklistTemplateCount = checklistTemplateCount
        self.fieldReferenceCount = fieldReferenceCount
    }
}
