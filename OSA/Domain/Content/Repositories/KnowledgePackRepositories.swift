import Foundation

protocol KnowledgePackInstallStateRepository {
    func listStates() throws -> [KnowledgePackInstallState]
    func state(packIdentifier: String) throws -> KnowledgePackInstallState?
    func saveState(_ state: KnowledgePackInstallState) throws
}

protocol KnowledgePackContentRepository {
    @discardableResult
    func installKnowledgePack(
        _ bundle: SeedContentBundle,
        previousRecordSet: KnowledgePackRecordSet?,
        importedAt: Date
    ) throws -> KnowledgePackInstallResult
}
