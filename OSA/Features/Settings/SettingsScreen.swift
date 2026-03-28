import SwiftUI

struct SettingsScreen: View {
    @Environment(\.capabilityDetector) private var capabilityDetector
    @Environment(\.discoveryCoordinator) private var discoveryCoordinator
    @Environment(\.connectivityService) private var connectivityService
    @AppStorage(AskScopeSettings.includePersonalNotesKey)
    private var includePersonalNotes = AskScopeSettings.includePersonalNotesDefault
    @AppStorage(DiscoverySettings.isRSSDiscoveryEnabledKey)
    private var isRSSDiscoveryEnabled = DiscoverySettings.isRSSDiscoveryEnabledDefault
    @AppStorage(DiscoverySettings.lastDiscoveryDateKey)
    private var lastDiscoveryTimestamp = 0.0
    @State private var connectivity: ConnectivityState = .offline
    @State private var braveSearchAPIKey: String
    @State private var isDiscovering = false
    @State private var lastDiscoveryMessage: String?
    @State private var credentialErrorMessage: String?
    private let braveSearchCredentialStore: BraveSearchCredentialStore

    init(braveSearchCredentialStore: BraveSearchCredentialStore = BraveSearchCredentialStore()) {
        self.braveSearchCredentialStore = braveSearchCredentialStore
        _braveSearchAPIKey = State(
            initialValue: braveSearchCredentialStore.loadStoredAPIKey() ?? ""
        )
    }

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
                    ConnectivityBadge(state: connectivity)
                }
                LabeledContent("Last Discovery Run") {
                    Text(lastDiscoveryLabel)
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
                .disabled(isDiscovering || discoveryCoordinator == nil || connectivity != .onlineUsable)

                if let lastDiscoveryMessage {
                    Text(lastDiscoveryMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                DisclosureGroup("Brave Search (Optional)") {
                    SecureField("API Key", text: $braveSearchAPIKey)
                        .textContentType(.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .privacySensitive()

                    Text(braveSearchStatusText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if let credentialErrorMessage {
                        Text(credentialErrorMessage)
                            .font(.caption2)
                            .foregroundStyle(.osaCritical)
                    }

                    Text("Free tier: 2,000 queries/month. Stored securely in Keychain and limited to trusted sources.")
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
                        Text("Core data stays on this device. Trusted-source lookups happen only when you choose them.")
                            .font(.metadataCaption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Section("About") {
                HStack(spacing: Spacing.sm) {
                    BrandMarkView(size: 44)
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        BrandWordmarkView(height: 24)
                        Text(AppBrand.subtitle)
                            .font(.metadataCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, Spacing.sm)
                .listRowBackground(Color.osaSecondaryBackground)

                LabeledContent("Version") {
                    Text(appVersionLabel)
                        .font(.metadataCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .tint(.osaPrimary)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
        .navigationTitle("Settings")
        .task { await observeConnectivity() }
        .onChange(of: braveSearchAPIKey) { _, newValue in
            persistBraveSearchAPIKey(newValue)
        }
    }

    private func runManualDiscovery() async {
        guard let coordinator = discoveryCoordinator else { return }
        guard connectivity == .onlineUsable else {
            lastDiscoveryMessage = "Connect to the internet to discover new content."
            return
        }
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

    private func observeConnectivity() async {
        guard let service = connectivityService else { return }
        connectivity = service.currentState
        for await state in service.stateStream() {
            connectivity = state
        }
    }

    private func persistBraveSearchAPIKey(_ apiKey: String) {
        do {
            try braveSearchCredentialStore.saveAPIKey(apiKey)
            credentialErrorMessage = nil
        } catch {
            credentialErrorMessage = error.localizedDescription
        }
    }

    private var answerMode: AnswerMode {
        capabilityDetector?.detectAnswerMode() ?? .searchResultsOnly
    }

    private var lastDiscoveryLabel: String {
        guard lastDiscoveryTimestamp > 0 else { return "Never" }
        return Date(timeIntervalSince1970: lastDiscoveryTimestamp)
            .formatted(date: .abbreviated, time: .shortened)
    }

    private var braveSearchStatusText: String {
        let trimmed = braveSearchAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "No API key stored." : "API key stored securely in Keychain."
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

    private var appVersionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String

        return switch (version, build) {
        case let (version?, build?) where !version.isEmpty && !build.isEmpty:
            "\(version) (\(build))"
        case let (version?, _):
            version
        case let (_, build?):
            build
        default:
            "Unknown"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}
