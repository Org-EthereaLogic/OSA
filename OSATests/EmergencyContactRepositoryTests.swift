import SwiftData
import XCTest
@testable import OSA

@MainActor
final class EmergencyContactRepositoryTests: XCTestCase {
    func testCreateAndListContacts() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataEmergencyContactRepository(modelContext: container.mainContext)

        let contact = makeContact(name: "Alex Rivera", relationship: "Sibling", phoneNumber: "5551234567")
        try repository.createContact(contact)

        let contacts = try repository.listContacts()
        XCTAssertEqual(contacts.count, 1)
        XCTAssertEqual(contacts.first?.name, "Alex Rivera")
        XCTAssertEqual(contacts.first?.relationship, "Sibling")
    }

    func testContactByID() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataEmergencyContactRepository(modelContext: container.mainContext)

        let contact = makeContact(name: "Morgan Lee", relationship: "Neighbor", phoneNumber: "5555551212")
        try repository.createContact(contact)

        let fetched = try XCTUnwrap(repository.contact(id: contact.id))
        XCTAssertEqual(fetched.phoneNumber, "5555551212")
    }

    func testUpdateContact() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataEmergencyContactRepository(modelContext: container.mainContext)

        var contact = makeContact(name: "Chris Patel", relationship: "Parent", phoneNumber: "5550000000")
        try repository.createContact(contact)

        contact.phoneNumber = "5550001111"
        contact.notes = "Lives two blocks away."
        contact.updatedAt = Date()
        try repository.updateContact(contact)

        let fetched = try XCTUnwrap(repository.contact(id: contact.id))
        XCTAssertEqual(fetched.phoneNumber, "5550001111")
        XCTAssertEqual(fetched.notes, "Lives two blocks away.")
    }

    func testDeleteContact() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataEmergencyContactRepository(modelContext: container.mainContext)

        let contact = makeContact(name: "Jordan Kim", relationship: "Friend", phoneNumber: "5559876543")
        try repository.createContact(contact)
        try repository.deleteContact(id: contact.id)

        XCTAssertNil(try repository.contact(id: contact.id))
        XCTAssertTrue(try repository.listContacts().isEmpty)
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([PersistedEmergencyContact.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeContact(
        name: String,
        relationship: String,
        phoneNumber: String
    ) -> EmergencyContact {
        let now = Date()
        return EmergencyContact(
            id: UUID(),
            name: name,
            relationship: relationship,
            phoneNumber: phoneNumber,
            notes: "",
            createdAt: now,
            updatedAt: now
        )
    }
}
