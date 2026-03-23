import Foundation
import SwiftData

@Model
final class PersistedSeedContentState {
    static let singletonIdentifier = "bundled-editorial-content"

    @Attribute(.unique) var identifier: String
    var schemaVersion: Int
    var contentPackVersion: String
    var appliedAt: Date

    init(
        identifier: String = PersistedSeedContentState.singletonIdentifier,
        schemaVersion: Int,
        contentPackVersion: String,
        appliedAt: Date
    ) {
        self.identifier = identifier
        self.schemaVersion = schemaVersion
        self.contentPackVersion = contentPackVersion
        self.appliedAt = appliedAt
    }
}
