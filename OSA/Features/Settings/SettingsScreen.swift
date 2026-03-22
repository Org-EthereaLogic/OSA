import SwiftUI

struct SettingsScreen: View {
    var body: some View {
        List {
            Section("Assistant") {
                LabeledContent("Model Capability") {
                    Text("Checking...")
                        .foregroundStyle(.secondary)
                }
                Toggle("Include personal notes in Ask", isOn: .constant(false))
            }

            Section("Connectivity") {
                LabeledContent("Status") {
                    ConnectivityBadge(state: .offline)
                }
                LabeledContent("Last Refresh") {
                    Text("Never")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Privacy") {
                LabeledContent("Data Storage") {
                    Text("On device only")
                        .foregroundStyle(.secondary)
                }
            }

            Section("About") {
                LabeledContent("Version") {
                    Text("0.1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}
