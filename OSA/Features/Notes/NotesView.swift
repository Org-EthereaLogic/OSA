import SwiftUI

struct NotesView: View {
    var body: some View {
        List {
            Section {
                Text("Create your first note to get started.")
                    .foregroundStyle(.secondary)
            } header: {
                Label("Personal Notes", systemImage: "note.text")
            }

            Section {
                Label("Emergency Contacts", systemImage: "person.crop.circle")
                Label("Meeting Points", systemImage: "mappin.and.ellipse")
                Label("Local References", systemImage: "map.fill")
            } header: {
                Text("Suggested First Notes")
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Add note placeholder
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        NotesView()
    }
}
