import SwiftUI

struct EmergencyContactFormView: View {
    enum Mode {
        case create
        case edit(EmergencyContact)
    }

    let mode: Mode
    let onSave: (EmergencyContact) throws -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var name = ""
    @State private var relationship = ""
    @State private var phoneNumber = ""
    @State private var notes = ""
    @State private var showSaveError = false

    private var existingContact: EmergencyContact? {
        if case .edit(let contact) = mode {
            return contact
        }
        return nil
    }

    var body: some View {
        Form {
            Section("Contact") {
                TextField("Name", text: $name)
                TextField("Relationship", text: $relationship)
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)
            }

            Section("Notes") {
                TextField("Optional notes", text: $notes, axis: .vertical)
                    .lineLimit(2...4)
                    .accessibilityLabel("Contact notes")
            }
        }
        .navigationTitle(existingContact == nil ? "New Contact" : "Edit Contact")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
                    .accessibilityHint("Discards changes and closes the emergency contact form.")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveContact() }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityHint("Saves this emergency contact on the device.")
            }
        }
        .alert("Unable to Save Contact", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Please try again.")
        }
        .onAppear(perform: populateFromExisting)
    }

    private func populateFromExisting() {
        guard let existingContact else { return }
        name = existingContact.name
        relationship = existingContact.relationship
        phoneNumber = existingContact.phoneNumber
        notes = existingContact.notes
    }

    private func saveContact() {
        let now = Date()
        let contact = EmergencyContact(
            id: existingContact?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            relationship: relationship.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: existingContact?.createdAt ?? now,
            updatedAt: now
        )

        do {
            try onSave(contact)
            hapticFeedbackService?.play(.success)
            dismiss()
        } catch {
            hapticFeedbackService?.play(.error)
            showSaveError = true
        }
    }
}
