import Foundation
import SwiftData

@Model
final class PersistedKnowledgePackInstallState {
    @Attribute(.unique) var packIdentifier: String
    var title: String
    var version: String
    var statusRawValue: String
    var installedAt: Date?
    var contentHash: String
    var lastError: String?
    var recordSetJSON: String
    var lastRefreshedAt: Date?

    init(
        packIdentifier: String,
        title: String,
        version: String,
        statusRawValue: String,
        installedAt: Date?,
        contentHash: String,
        lastError: String?,
        recordSetJSON: String,
        lastRefreshedAt: Date?
    ) {
        self.packIdentifier = packIdentifier
        self.title = title
        self.version = version
        self.statusRawValue = statusRawValue
        self.installedAt = installedAt
        self.contentHash = contentHash
        self.lastError = lastError
        self.recordSetJSON = recordSetJSON
        self.lastRefreshedAt = lastRefreshedAt
    }
}
