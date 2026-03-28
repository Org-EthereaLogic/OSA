import Foundation

protocol EmergencyContactRepository {
    func listContacts() throws -> [EmergencyContact]
    func contact(id: UUID) throws -> EmergencyContact?
    func createContact(_ contact: EmergencyContact) throws
    func updateContact(_ contact: EmergencyContact) throws
    func deleteContact(id: UUID) throws
}
