import SwiftUI

struct KnowledgePackManagementScreen: View {
    @Environment(\.knowledgePackCatalogClient) private var catalogClient
    @Environment(\.knowledgePackDownloadCoordinator) private var downloadCoordinator
    @Environment(\.knowledgePackInstallStateRepository) private var installStateRepository
    @Environment(\.connectivityService) private var connectivityService
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var catalogEntries: [KnowledgePackCatalogEntry] = []
    @State private var installStatesByID: [String: KnowledgePackInstallState] = [:]
    @State private var isRefreshing = false
    @State private var activePackID: String?
    @State private var statusMessage: String?
    @State private var statusColor: Color = .secondary

    var body: some View {
        List {
            Section("Catalog Status") {
                Label(catalogSummaryText, systemImage: catalogSummaryIcon)
                    .font(.caption)
                    .foregroundStyle(catalogSummaryColor)

                if let statusMessage {
                    Text(statusMessage)
                        .font(.caption)
                        .foregroundStyle(statusColor)
                }

                Text("Curated packs ship with the app, validate locally with the seed-pack loader, auto-install on launch, and remain searchable offline.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Available Packs") {
                if catalogEntries.isEmpty {
                    Text("No catalog entries are available yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(catalogEntries) { entry in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            HStack(alignment: .top, spacing: Spacing.sm) {
                                VStack(alignment: .leading, spacing: Spacing.xxs) {
                                    Text(entry.title)
                                        .font(.headline)
                                    Text(entry.summary)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: Spacing.xxs) {
                                    Text("v\(entry.version)")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(.secondary)
                                    Text(statusLabel(for: entry))
                                        .font(.caption2)
                                        .foregroundStyle(statusTint(for: entry))
                                        .accessibilityIdentifier("knowledge-pack-status-\(entry.id)")
                                }
                            }

                            Text(entry.isBundled ? "Included with this app" : "Requires connectivity")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)

                            Button {
                                Task { await install(entry) }
                            } label: {
                                HStack {
                                    Label(actionLabel(for: entry), systemImage: actionSystemImage(for: entry))
                                    if activePackID == entry.id {
                                        Spacer()
                                        ProgressView()
                                    }
                                }
                            }
                            .accessibilityIdentifier("knowledge-pack-action-\(entry.id)")
                            .disabled(actionDisabled(for: entry))

                            if let installedState = installStatesByID[entry.id],
                               let installedAt = installedState.installedAt {
                                Text("Installed locally \(installedAt.formatted(date: .abbreviated, time: .shortened)).")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            }

                            if let installedState = installStatesByID[entry.id],
                               installedState.status == .failed,
                               let lastError = installedState.lastError {
                                Text(lastError)
                                    .font(.caption2)
                                    .foregroundStyle(.osaCritical)
                            }
                        }
                        .padding(.vertical, Spacing.xxs)
                    }
                }
            }
        }
        .navigationTitle("Knowledge Packs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await refreshCatalog() }
                } label: {
                    if isRefreshing {
                        ProgressView()
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                .accessibilityIdentifier("knowledge-pack-refresh")
                .disabled(isRefreshing)
                .accessibilityLabel("Reload knowledge pack catalog")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
        .task {
            loadInstallStates()
            await refreshCatalog()
        }
    }

    private func refreshCatalog() async {
        guard let catalogClient else {
            statusMessage = "Knowledge-pack discovery is unavailable in this build."
            statusColor = .osaCritical
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            let catalog = try await catalogClient.fetchCatalog()
            catalogEntries = catalog.packs.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            let bundledCount = catalogEntries.filter { $0.isBundled }.count
            if bundledCount > 0 {
                statusMessage = "Loaded \(bundledCount) bundled pack\(bundledCount == 1 ? "" : "s")."
            } else {
                statusMessage = "Catalog refreshed."
            }
            statusColor = .secondary
            loadInstallStates()
        } catch {
            statusMessage = error.localizedDescription
            statusColor = .osaCritical
        }
    }

    private func install(_ entry: KnowledgePackCatalogEntry) async {
        guard let downloadCoordinator else {
            statusMessage = "Knowledge-pack installation is unavailable in this build."
            statusColor = .osaCritical
            return
        }

        activePackID = entry.id
        defer { activePackID = nil }

        do {
            _ = try await downloadCoordinator.install(entry)
            loadInstallStates()
            statusMessage = "\(entry.title) is installed locally."
            statusColor = .osaLocal
            hapticFeedbackService?.play(.success)
        } catch {
            loadInstallStates()
            statusMessage = error.localizedDescription
            statusColor = .osaCritical
            hapticFeedbackService?.play(.error)
        }
    }

    private func loadInstallStates() {
        do {
            let states = try installStateRepository?.listStates() ?? []
            installStatesByID = Dictionary(uniqueKeysWithValues: states.map { ($0.packIdentifier, $0) })
        } catch {
            installStatesByID = [:]
        }
    }

    private func statusLabel(for entry: KnowledgePackCatalogEntry) -> String {
        guard let state = installStatesByID[entry.id] else {
            return "Not installed"
        }

        switch state.status {
        case .notInstalled:
            return "Not installed"
        case .installing:
            return "Installing"
        case .installed:
            return state.version == entry.version && state.contentHash == entry.contentHash
                ? "Installed"
                : "Update available"
        case .failed:
            return "Install failed"
        }
    }

    private func statusTint(for entry: KnowledgePackCatalogEntry) -> Color {
        switch statusLabel(for: entry) {
        case "Installed":
            .osaLocal
        case "Update available":
            .osaWarning
        case "Installing":
            .osaPrimary
        case "Install failed":
            .osaCritical
        default:
            .secondary
        }
    }

    private func actionLabel(for entry: KnowledgePackCatalogEntry) -> String {
        guard let state = installStatesByID[entry.id] else {
            return "Install"
        }

        switch state.status {
        case .installed:
            return state.version == entry.version && state.contentHash == entry.contentHash
                ? "Installed"
                : "Update"
        case .installing:
            return "Installing"
        case .failed:
            return "Retry Install"
        case .notInstalled:
            return "Install"
        }
    }

    private func actionSystemImage(for entry: KnowledgePackCatalogEntry) -> String {
        switch actionLabel(for: entry) {
        case "Installed":
            "checkmark.circle.fill"
        case "Update":
            "arrow.triangle.2.circlepath"
        case "Installing":
            "hourglass"
        case "Retry Install":
            "exclamationmark.arrow.trianglehead.clockwise"
        default:
            "tray.and.arrow.down"
        }
    }

    private func actionDisabled(for entry: KnowledgePackCatalogEntry) -> Bool {
        activePackID != nil
            || (entry.requiresConnectivity && connectivityService?.currentState != .onlineUsable)
            || actionLabel(for: entry) == "Installed"
    }

    private var catalogSummaryText: String {
        if catalogEntries.contains(where: \.isBundled) {
            return bundledEntries.allSatisfy { isCurrentInstall($0) }
                ? "Bundled packs are installed and ready offline."
                : "Bundled packs ship with the app and install locally on launch."
        }

        switch connectivityService?.currentState ?? .offline {
        case .offline:
            return "Reconnect to fetch or update curated knowledge packs."
        case .onlineConstrained:
            return "Wait for a stronger connection before refreshing or installing packs."
        case .onlineUsable:
            return "Curated pack installs are available."
        case .syncInProgress:
            return "Knowledge import or refresh is already running. Local content remains usable."
        }
    }

    private var catalogSummaryIcon: String {
        if catalogEntries.contains(where: \.isBundled) {
            return bundledEntries.allSatisfy { isCurrentInstall($0) }
                ? "checkmark.circle.fill"
                : "shippingbox.fill"
        }

        switch connectivityService?.currentState ?? .offline {
        case .offline:
            return "wifi.slash"
        case .onlineConstrained:
            return "wifi.exclamationmark"
        case .onlineUsable:
            return "tray.and.arrow.down.fill"
        case .syncInProgress:
            return "arrow.triangle.2.circlepath"
        }
    }

    private var catalogSummaryColor: Color {
        if catalogEntries.contains(where: \.isBundled) {
            return .osaLocal
        }

        switch connectivityService?.currentState ?? .offline {
        case .offline:
            return .osaBoundary
        case .onlineConstrained:
            return .osaWarning
        case .onlineUsable:
            return .osaTrust
        case .syncInProgress:
            return .osaPrimary
        }
    }

    private var bundledEntries: [KnowledgePackCatalogEntry] {
        catalogEntries.filter(\.isBundled)
    }

    private func isCurrentInstall(_ entry: KnowledgePackCatalogEntry) -> Bool {
        guard let state = installStatesByID[entry.id] else {
            return false
        }

        return state.status == .installed
            && state.version == entry.version
            && state.contentHash == entry.contentHash
    }
}

#Preview {
    NavigationStack {
        KnowledgePackManagementScreen()
    }
}
