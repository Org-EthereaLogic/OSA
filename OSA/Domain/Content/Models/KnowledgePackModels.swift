import Foundation

enum KnowledgePackInstallStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case notInstalled = "not-installed"
    case installing
    case installed
    case failed
}

struct KnowledgePackRecordSet: Codable, Equatable, Sendable {
    var chapterIDs: [UUID]
    var quickCardIDs: [UUID]
    var checklistTemplateIDs: [UUID]
    var fieldReferenceIDs: [UUID]

    static let empty = KnowledgePackRecordSet(
        chapterIDs: [],
        quickCardIDs: [],
        checklistTemplateIDs: [],
        fieldReferenceIDs: []
    )
}

struct KnowledgePackCatalogEntry: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let summary: String
    let version: String
    let manifestURL: URL
    let contentHash: String

    var isBundled: Bool {
        manifestURL.isFileURL
    }

    var requiresConnectivity: Bool {
        !isBundled
    }
}

struct KnowledgePackCatalog: Equatable, Sendable {
    let generatedAt: Date?
    let packs: [KnowledgePackCatalogEntry]
}

struct KnowledgePackInstallState: Identifiable, Equatable, Sendable {
    var id: String { packIdentifier }

    let packIdentifier: String
    var title: String
    var version: String
    var status: KnowledgePackInstallStatus
    var installedAt: Date?
    var contentHash: String
    var lastError: String?
    var recordSet: KnowledgePackRecordSet
    var lastRefreshedAt: Date?
}

struct KnowledgePackInstallResult: Equatable, Sendable {
    let recordSet: KnowledgePackRecordSet
    let chapterCount: Int
    let quickCardCount: Int
    let checklistTemplateCount: Int
    let fieldReferenceCount: Int
}
