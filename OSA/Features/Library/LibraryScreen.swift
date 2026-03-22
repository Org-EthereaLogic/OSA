import SwiftUI

struct LibraryScreen: View {
    var body: some View {
        List {
            Section {
                Text("Handbook chapters will appear here once seed content is imported.")
                    .foregroundStyle(.secondary)
            } header: {
                Label("Chapters", systemImage: "book.fill")
            }
        }
        .navigationTitle("Library")
    }
}

#Preview {
    NavigationStack {
        LibraryScreen()
    }
}
