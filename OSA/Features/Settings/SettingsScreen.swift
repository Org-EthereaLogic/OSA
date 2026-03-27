import SwiftUI

struct SettingsScreen: View {
    @Environment(\.capabilityDetector) private var capabilityDetector
    @Environment(\.discoveryCoordinator) private var discoveryCoordinator
    @AppStorage(AskScopeSettings.includePersonalNotesKey)
    private var includePersonalNotes = AskScopeSettings.includePersonalNotesDefault
    @AppStorage(DiscoverySettings.isRSSDiscoveryEnabledKey)
    private var isRSSDiscoveryEnabled = DiscoverySettings.isRSSDiscoveryEnabledDefault
    @AppStorage(DiscoverySettings.braveSearchAPIKeyKey)
    private var braveSearchAPIKey = ""
    @State private var isDiscovering = false
    @State private var lastDiscoveryMessage: String?

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

            Section("Knowledge Discovery") {
                Toggle("Auto-discover from RSS feeds", isOn: $isRSSDiscoveryEnabled)

                Button {
                    Task { await runManualDiscovery() }
                } label: {
                    HStack {
                        Label("Discover New Content", systemImage: "antenna.radiowaves.left.and.right")
                        if isDiscovering {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isDiscovering || discoveryCoordinator == nil)

                if let lastDiscoveryMessage {
                    Text(lastDiscoveryMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                DisclosureGroup("Brave Search (Optional)") {
                    TextField("API Key", text: $braveSearchAPIKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                    Text("Free tier: 2,000 queries/month. Searches only trusted sources.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
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
                .padding(.vertical, Spacing.sm)
                .listRowBackground(Color.osaSecondaryBackground)

                LabeledContent("Version") {
                    Text("0.1.0")
                        .font(.metadataCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.osaPrimary)
        .navigationTitle("Settings")
    }

    private func runManualDiscovery() async {
        guard let coordinator = discoveryCoordinator else { return }
        isDiscovering = true
        lastDiscoveryMessage = nil

        let result = await coordinator.discoverAndImport()

        if result.articlesDiscovered == 0 {
            lastDiscoveryMessage = "No new content found."
        } else {
            lastDiscoveryMessage = "Found \(result.articlesDiscovered), imported \(result.articlesImported), skipped \(result.articlesSkippedDuplicate) duplicates."
        }
        isDiscovering = false
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
