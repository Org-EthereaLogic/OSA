import SwiftUI

struct SettingsScreen: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.capabilityDetector) private var capabilityDetector
    @Environment(\.discoveryCoordinator) private var discoveryCoordinator
    @Environment(\.connectivityService) private var connectivityService
    @Environment(\.emergencyContactRepository) private var emergencyContactRepository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @AppStorage(AskScopeSettings.includePersonalNotesKey)
    private var includePersonalNotes = AskScopeSettings.includePersonalNotesDefault
    @AppStorage(UserProfileSettings.regionKey)
    private var regionRawValue = UserProfileSettings.regionDefault.rawValue
    @AppStorage(UserProfileSettings.householdSizeKey)
    private var householdSize = UserProfileSettings.householdSizeDefault
    @AppStorage(UserProfileSettings.hazardsKey)
    private var hazardsRawValue = UserProfileSettings.encode(hazards: [])
    @AppStorage(AccessibilitySettings.largePrintReadingModeKey)
    private var largePrintReadingMode = AccessibilitySettings.largePrintReadingModeDefault
    @AppStorage(AccessibilitySettings.criticalHapticsKey)
    private var criticalHaptics = AccessibilitySettings.criticalHapticsDefault
    @AppStorage(DiscoverySettings.isRSSDiscoveryEnabledKey)
    private var isRSSDiscoveryEnabled = DiscoverySettings.isRSSDiscoveryEnabledDefault
    @AppStorage(DiscoverySettings.lastDiscoveryDateKey)
    private var lastDiscoveryTimestamp = 0.0
    @State private var connectivity: ConnectivityState = .offline
    @State private var braveSearchAPIKey: String
    @State private var isDiscovering = false
    @State private var lastDiscoveryMessage: String?
    @State private var lastDiscoveryMessageColor: Color = .secondary
    @State private var credentialErrorMessage: String?
    @State private var contacts: [EmergencyContact] = []
    @State private var contactEditor: EmergencyContactEditorState?
    @State private var connectivityNotice: ConnectivityStatusNotice?
    @State private var connectivityNoticeDismissTask: Task<Void, Never>?
    private let braveSearchCredentialStore: BraveSearchCredentialStore

    init(braveSearchCredentialStore: BraveSearchCredentialStore = BraveSearchCredentialStore()) {
        self.braveSearchCredentialStore = braveSearchCredentialStore
        _braveSearchAPIKey = State(
            initialValue: braveSearchCredentialStore.loadStoredAPIKey() ?? ""
        )
    }

    var body: some View {
        List {
            preparednessProfileSection
            emergencyContactsSection
            accessibilityFeedbackSection
            assistantSection
            connectivitySection
            knowledgeDiscoverySection
            privacySection
            aboutSection
        }
        .tint(.osaPrimary)
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
        .navigationTitle("Settings")
        .task {
            loadContacts()
            await observeConnectivity()
        }
        .onChange(of: braveSearchAPIKey) { _, newValue in
            persistBraveSearchAPIKey(newValue)
        }
        .sheet(item: $contactEditor, onDismiss: loadContacts) { editor in
            NavigationStack {
                EmergencyContactFormView(mode: editor.mode) { contact in
                    switch editor {
                    case .create:
                        try emergencyContactRepository?.createContact(contact)
                    case .edit:
                        try emergencyContactRepository?.updateContact(contact)
                    }
                    loadContacts()
                }
            }
        }
        .onDisappear {
            connectivityNoticeDismissTask?.cancel()
        }
    }

    @ViewBuilder
    private var preparednessProfileSection: some View {
        Section("Preparedness Profile") {
            Picker("Region", selection: $regionRawValue) {
                ForEach(PreparednessRegion.allCases) { region in
                    Text(region.displayName).tag(region.rawValue)
                }
            }
            .accessibilityHint("Updates region-based suggestions and preparedness defaults.")

            Stepper(value: $householdSize, in: 1...12) {
                Text("Household Size: \(householdSize)")
            }
            .accessibilityHint("Adjusts household-based preparedness calculations.")

            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text("Primary Hazards")
                    .font(.subheadline)
                ForEach(HazardScenario.allCases) { hazard in
                    Toggle(
                        hazard.displayName,
                        isOn: Binding(
                            get: { selectedHazards.contains(hazard) },
                            set: { isOn in updateHazard(hazard, isSelected: isOn) }
                        )
                    )
                    .accessibilityHint("Includes \(hazard.displayName.lowercased()) in your preparedness profile.")
                }
            }
        }
    }

    @ViewBuilder
    private var emergencyContactsSection: some View {
        Section("Emergency Contacts") {
            SettingsSummaryCard(
                systemImage: contacts.isEmpty ? "person.crop.circle.badge.plus" : "checkmark.shield.fill",
                title: contacts.isEmpty ? "Set up the I'm Safe shortcut" : "I'm Safe shortcut ready",
                message: contacts.isEmpty
                    ? "Add one or more local contacts so Emergency Mode can prepare a ready-to-send check-in message."
                    : "\(contacts.count) \(contacts.count == 1 ? "local contact is" : "local contacts are") available for quick check-ins from Emergency Mode.",
                tint: contacts.isEmpty ? .osaPrimary : .osaLocal
            )

            if !contacts.isEmpty {
                ForEach(contacts) { contact in
                    Button {
                        contactEditor = .edit(contact)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xxs) {
                                Text(contact.name)
                                    .foregroundStyle(.primary)
                                Text(contact.relationship.isEmpty ? contact.phoneNumber : "\(contact.relationship) · \(contact.phoneNumber)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Edits this emergency contact.")
                }
                .onDelete(perform: deleteContacts)
            }

            Button {
                contactEditor = .create
            } label: {
                Label("Add Emergency Contact", systemImage: "plus")
            }
            .accessibilityHint("Creates a new emergency contact stored on this device.")
        }
    }

    @ViewBuilder
    private var accessibilityFeedbackSection: some View {
        Section("Accessibility & Feedback") {
            SettingsSummaryCard(
                systemImage: "figure.wave.circle",
                title: "Large type and critical feedback",
                message: "These settings affect emergency reading screens, checklist completion cues, and other high-priority interactions.",
                tint: .osaCalm
            )

            Toggle("Large print reading mode", isOn: $largePrintReadingMode)
                .accessibilityHint("Uses larger text on reading-heavy emergency content.")
            Toggle("Critical haptics", isOn: $criticalHaptics)
                .accessibilityHint("Enables stronger haptic feedback for important actions.")
        }
    }

    @ViewBuilder
    private var assistantSection: some View {
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
                .accessibilityHint("Allows Ask to search personal notes stored on this device.")
        }
    }

    @ViewBuilder
    private var connectivitySection: some View {
        Section("Connectivity") {
            if let connectivityNotice {
                ConnectivityStatusCallout(notice: connectivityNotice)
            }

            LabeledContent("Status") {
                ConnectivityBadge(state: connectivity)
            }

            LabeledContent("Last Discovery Run") {
                Text(lastDiscoveryLabel)
                    .foregroundStyle(.secondary)
            }

            Text(connectivitySupportText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var knowledgeDiscoverySection: some View {
        Section("Knowledge Discovery") {
            Label(discoveryAvailabilityText, systemImage: discoveryAvailabilityIcon)
                .font(.caption)
                .foregroundStyle(discoveryAvailabilityTint)

            Toggle("Auto-discover from RSS feeds", isOn: $isRSSDiscoveryEnabled)
                .accessibilityHint("Automatically checks approved RSS feeds when discovery is due.")

            Button {
                Task { await runManualDiscovery() }
            } label: {
                HStack {
                    Label(
                        isDiscovering ? "Discovering Approved Sources" : "Discover New Content",
                        systemImage: isDiscovering ? "arrow.triangle.2.circlepath" : "antenna.radiowaves.left.and.right"
                    )
                    if isDiscovering {
                        Spacer()
                        ProgressView()
                    }
                }
            }
            .disabled(discoveryActionDisabled)
            .accessibilityHint(discoveryAccessibilityHint)

            if let lastDiscoveryMessage {
                Text(lastDiscoveryMessage)
                    .font(.caption)
                    .foregroundStyle(lastDiscoveryMessageColor)
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
    }

    @ViewBuilder
    private var privacySection: some View {
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
    }

    @ViewBuilder
    private var aboutSection: some View {
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

    private func runManualDiscovery() async {
        guard let coordinator = discoveryCoordinator else {
            lastDiscoveryMessage = "Knowledge discovery is unavailable in this build."
            lastDiscoveryMessageColor = .osaCritical
            return
        }
        guard connectivity == .onlineUsable else {
            lastDiscoveryMessage = "Connect to the internet to discover new content."
            lastDiscoveryMessageColor = .secondary
            hapticFeedbackService?.play(.warning)
            return
        }

        isDiscovering = true
        lastDiscoveryMessage = nil
        lastDiscoveryMessageColor = .secondary

        defer {
            isDiscovering = false
        }

        let result = await coordinator.discoverAndImport()

        if result.articlesImported > 0 {
            if result.errors.isEmpty {
                lastDiscoveryMessage = "Imported \(result.articlesImported) new \(result.articlesImported == 1 ? "item" : "items") from approved sources."
                lastDiscoveryMessageColor = .osaLocal
            } else {
                lastDiscoveryMessage = "Imported \(result.articlesImported) new \(result.articlesImported == 1 ? "item" : "items"), but some approved sources could not be refreshed."
                lastDiscoveryMessageColor = .secondary
            }
            hapticFeedbackService?.play(.success)
        } else if !result.errors.isEmpty {
            lastDiscoveryMessage = "Discovery finished with connectivity or source errors before importing new content."
            lastDiscoveryMessageColor = .osaCritical
            hapticFeedbackService?.play(.warning)
        } else if result.articlesDiscovered == 0 {
            lastDiscoveryMessage = "No new approved content found."
            lastDiscoveryMessageColor = .secondary
            hapticFeedbackService?.play(.warning)
        } else {
            lastDiscoveryMessage = "No new imports were needed. \(result.articlesSkippedDuplicate) \(result.articlesSkippedDuplicate == 1 ? "article was" : "articles were") already stored locally."
            lastDiscoveryMessageColor = .secondary
            hapticFeedbackService?.play(.warning)
        }
    }

    private func observeConnectivity() async {
        guard let service = connectivityService else { return }
        var previousState: ConnectivityState?
        for await state in service.stateStream() {
            handleConnectivityChange(from: previousState, to: state)
            previousState = state
        }
    }

    private func handleConnectivityChange(from previousState: ConnectivityState?, to newState: ConnectivityState) {
        guard previousState != newState else { return }
        withAnimation(connectivityAnimation) {
            connectivity = newState
        }
        presentConnectivityNotice(settingsConnectivityNotice(for: newState, previousState: previousState))
    }

    private func presentConnectivityNotice(_ notice: ConnectivityStatusNotice?) {
        connectivityNoticeDismissTask?.cancel()

        withAnimation(connectivityAnimation) {
            connectivityNotice = notice
        }

        guard let notice, notice.autoDismisses else { return }

        connectivityNoticeDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled, connectivityNotice == notice else { return }
            withAnimation(connectivityAnimation) {
                connectivityNotice = nil
            }
        }
    }

    private func settingsConnectivityNotice(
        for state: ConnectivityState,
        previousState: ConnectivityState?
    ) -> ConnectivityStatusNotice? {
        switch state {
        case .offline:
            return ConnectivityStatusNotice(
                state: state,
                title: "Discovery paused",
                message: "Local content stays available. Discovery and trusted-source refresh resume when you're back online.",
                autoDismisses: false
            )
        case .onlineConstrained:
            return ConnectivityStatusNotice(
                state: state,
                title: "Connection limited",
                message: "Discovery remains visible, but approved-source checks wait for a stronger connection.",
                autoDismisses: false
            )
        case .onlineUsable:
            guard let previousState, previousState != .onlineUsable else { return nil }
            return ConnectivityStatusNotice(
                state: state,
                title: previousState == .syncInProgress ? "Refresh complete" : "Online enrichment available",
                message: previousState == .syncInProgress
                    ? "Approved-source refresh finished. Manual discovery is available again."
                    : "You can discover or import approved sources now. Local content remains available either way.",
                autoDismisses: true
            )
        case .syncInProgress:
            return ConnectivityStatusNotice(
                state: state,
                title: "Refresh in progress",
                message: "Approved-source updates are running. Existing local content remains usable.",
                autoDismisses: false
            )
        }
    }

    private func loadContacts() {
        do {
            contacts = try emergencyContactRepository?.listContacts() ?? []
        } catch {
            contacts = []
        }
    }

    private func deleteContacts(at offsets: IndexSet) {
        for index in offsets {
            let contact = contacts[index]
            try? emergencyContactRepository?.deleteContact(id: contact.id)
        }
        if !offsets.isEmpty {
            hapticFeedbackService?.play(.warning)
        }
        loadContacts()
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

    private var connectivitySupportText: String {
        switch connectivity {
        case .offline:
            "OSA remains fully usable offline. Connectivity only affects optional discovery and refresh."
        case .onlineConstrained:
            "Local content is ready now. Optional discovery may stay paused until the connection improves."
        case .onlineUsable:
            "Online enrichment is available, but handbook, quick cards, notes, and checklists stay local-first."
        case .syncInProgress:
            "Approved-source refresh is active in the foreground without blocking core local features."
        }
    }

    private var discoveryAvailabilityText: String {
        switch connectivity {
        case .offline:
            "Discovery is unavailable offline. Your local handbook, quick cards, and notes still work."
        case .onlineConstrained:
            "Wait for a stronger connection before discovering or refreshing approved sources."
        case .onlineUsable:
            "Discovery checks approved sources and stores imported content locally for later offline use."
        case .syncInProgress:
            "Approved-source refresh is already running. New discovery can start when it finishes."
        }
    }

    private var discoveryAvailabilityIcon: String {
        switch connectivity {
        case .offline:
            "wifi.slash"
        case .onlineConstrained:
            "wifi.exclamationmark"
        case .onlineUsable:
            "tray.and.arrow.down.fill"
        case .syncInProgress:
            "arrow.triangle.2.circlepath"
        }
    }

    private var discoveryAvailabilityTint: Color {
        switch connectivity {
        case .offline:
            .osaBoundary
        case .onlineConstrained:
            .osaWarning
        case .onlineUsable:
            .osaTrust
        case .syncInProgress:
            .osaPrimary
        }
    }

    private var discoveryActionDisabled: Bool {
        isDiscovering || discoveryCoordinator == nil || connectivity != .onlineUsable
    }

    private var discoveryAccessibilityHint: String {
        switch connectivity {
        case .offline:
            "Unavailable offline. Reconnect to check approved sources for new content."
        case .onlineConstrained:
            "Wait for a stronger connection before checking approved sources."
        case .onlineUsable:
            "Checks approved sources for newly importable content."
        case .syncInProgress:
            "Disabled while an approved-source refresh is already in progress."
        }
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

    private var connectivityAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.2)
    }

    private var selectedHazards: Set<HazardScenario> {
        Set(UserProfileSettings.hazards(from: hazardsRawValue))
    }

    private func updateHazard(_ hazard: HazardScenario, isSelected: Bool) {
        var hazards = selectedHazards
        if isSelected {
            hazards.insert(hazard)
        } else {
            hazards.remove(hazard)
        }
        hazardsRawValue = UserProfileSettings.encode(hazards: Array(hazards).sorted { $0.rawValue < $1.rawValue })
    }
}

#Preview {
    NavigationStack {
        SettingsScreen()
    }
}

private struct SettingsSummaryCard: View {
    let systemImage: String
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, Spacing.xxs)
        .accessibilityElement(children: .combine)
    }
}

private enum EmergencyContactEditorState: Identifiable {
    case create
    case edit(EmergencyContact)

    var id: String {
        switch self {
        case .create:
            "create"
        case .edit(let contact):
            "edit-\(contact.id.uuidString)"
        }
    }

    var mode: EmergencyContactFormView.Mode {
        switch self {
        case .create:
            .create
        case .edit(let contact):
            .edit(contact)
        }
    }
}
