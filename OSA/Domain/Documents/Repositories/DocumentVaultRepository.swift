import Foundation

protocol DocumentVaultRepository {
    func listEntries() throws -> [DocumentVaultEntry]
    func entry(id: UUID) throws -> DocumentVaultEntry?
    func createEntry(_ entry: DocumentVaultEntry) throws
    func updateEntry(_ entry: DocumentVaultEntry) throws
    func deleteEntry(id: UUID) throws
}
