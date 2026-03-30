import SwiftUI

struct FieldReferenceRouteView: View {
    let entryID: UUID

    @Environment(\.fieldReferenceRepository) private var repository
    @State private var entry: FieldReferenceEntry?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This field reference could not be loaded.")
                )
            } else if let entry {
                FieldReferenceDetailView(entry: entry)
            } else {
                ProgressView("Loading...")
            }
        }
        .task { loadEntry() }
    }

    private func loadEntry() {
        do {
            entry = try repository?.entry(id: entryID)
            loadFailed = entry == nil
        } catch {
            loadFailed = true
        }
    }
}

#Preview {
    NavigationStack {
        FieldReferenceRouteView(entryID: UUID())
    }
}
