import SwiftUI

struct SettingsScreen: View {
    @Environment(\.capabilityDetector) private var capabilityDetector
    @AppStorage(AskScopeSettings.includePersonalNotesKey)
    private var includePersonalNotes = AskScopeSettings.includePersonalNotesDefault

    var body: some View {
        List {
            Section("Assistant") {
                LabeledContent("Model Capability") {
                    VStack(alignment: .trailing, spacing: Spacing.xxs) {
                        Text(capabilityTitle)
                            .foregroundStyle(.secondary)
                        Text(capabilityDetail)
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                Toggle("Include personal notes in Ask", isOn: $includePersonalNotes)
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
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(.osaLocal)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("On-device only")
                        Text("All data stays on this device. Nothing is transmitted.")
                            .font(.metadataCaption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Section("About") {
                HStack(spacing: Spacing.sm) {
                    BrandMarkView(size: 44)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text(AppBrand.displayName)
                            .font(.cardTitle)
                        Text(AppBrand.subtitle)
                            .font(.metadataCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, Spacing.xxs)

                LabeledContent("Version") {
                    Text("0.1.0")
                        .font(.metadataCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
    }

    private var answerMode: AnswerMode {
        capabilityDetector?.detectAnswerMode() ?? .searchResultsOnly
    }

    private var capabilityTitle: String {
        switch answerMode {
        case .groundedGeneration:
            "On-device grounded summaries"
        case .extractiveOnly:
            "Cited local answers"
        case .searchResultsOnly:
            "Source browsing only"
        }
    }

    private var capabilityDetail: String {
        switch answerMode {
        case .groundedGeneration:
            "Uses local retrieval with supported on-device generation."
        case .extractiveOnly:
            "Uses local retrieval and extractive answer assembly."
        case .searchResultsOnly:
            "Shows local sources without generated answer text."
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}
