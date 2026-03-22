import SwiftUI

struct ChecklistsView: View {
    var body: some View {
        List {
            Section {
                Text("Checklist templates will appear here once seed content is imported.")
                    .foregroundStyle(.secondary)
            } header: {
                Label("Templates", systemImage: "checklist")
            }
        }
        .navigationTitle("Checklists")
    }
}

#Preview {
    NavigationStack {
        ChecklistsView()
    }
}
