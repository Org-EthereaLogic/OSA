import SwiftUI

struct InventoryScreen: View {
    var body: some View {
        List {
            Section {
                Text("Add your first supply item to get started.")
                    .foregroundStyle(.secondary)
            } header: {
                Label("Supplies", systemImage: "archivebox.fill")
            }

            Section {
                Label("Water", systemImage: "drop.fill")
                Label("Food", systemImage: "fork.knife")
                Label("Power", systemImage: "bolt.fill")
                Label("First Aid", systemImage: "cross.case.fill")
            } header: {
                Text("Suggested Categories")
            }
        }
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    // Add item placeholder
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        InventoryScreen()
    }
}
