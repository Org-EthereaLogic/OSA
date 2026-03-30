import Foundation

extension PersistedKnowledgePackInstallState {
    convenience init(from state: KnowledgePackInstallState) {
        self.init(
            packIdentifier: state.packIdentifier,
            title: state.title,
            version: state.version,
            statusRawValue: state.status.rawValue,
            installedAt: state.installedAt,
            contentHash: state.contentHash,
            lastError: state.lastError,
            recordSetJSON: PersistenceValueCoding.encodeCodable(state.recordSet),
            lastRefreshedAt: state.lastRefreshedAt
        )
    }

    func update(from state: KnowledgePackInstallState) {
        title = state.title
        version = state.version
        statusRawValue = state.status.rawValue
        installedAt = state.installedAt
        contentHash = state.contentHash
        lastError = state.lastError
        recordSetJSON = PersistenceValueCoding.encodeCodable(state.recordSet)
        lastRefreshedAt = state.lastRefreshedAt
    }

    func toDomain() -> KnowledgePackInstallState {
        KnowledgePackInstallState(
            packIdentifier: packIdentifier,
            title: title,
            version: version,
            status: KnowledgePackInstallStatus(rawValue: statusRawValue) ?? .notInstalled,
            installedAt: installedAt,
            contentHash: contentHash,
            lastError: lastError,
            recordSet: PersistenceValueCoding.decodeCodable(KnowledgePackRecordSet.self, from: recordSetJSON) ?? .empty,
            lastRefreshedAt: lastRefreshedAt
        )
    }
}
