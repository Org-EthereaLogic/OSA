import SwiftUI

struct DocumentVaultScreen: View {
    @Environment(\.documentVaultRepository) private var repository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var entries: [DocumentVaultEntry] = []
    @State private var searchText = ""
    @State private var isUnlocked = false
    @State private var isUnlocking = false
    @State private var showingAddDocument = false
    @State private var loadFailed = false
    @State private var unlockErrorMessage: String?

    var body: some View {
        Group {
            if !isUnlocked {
                lockedState
            } else if loadFailed {
                ContentUnavailableView(
                    "Unable to Load Vault",
                    systemImage: "lock.trianglebadge.exclamationmark",
                    description: Text("The encrypted document vault could not be loaded.")
                )
            } else if filteredEntries.isEmpty {
                ContentUnavailableView(
                    entries.isEmpty ? "No Vault Documents Yet" : "No Matching Documents",
                    systemImage: entries.isEmpty ? "lock.doc" : "magnifyingglass",
                    description: Text(
                        entries.isEmpty
                            ? "Capture or import local copies of important documents. Vault files stay encrypted on this iPhone."
                            : "Try a different title or category filter."
                    )
                )
            } else {
                listContent
            }
        }
        .navigationTitle("Document Vault")
        .toolbar {
            if isUnlocked {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddDocument = true
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Add vault document")
                    .accessibilityHint("Captures or imports a document into the encrypted local vault.")
                }
            }
        }
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .sheet(isPresented: $showingAddDocument) {
            NavigationStack {
                DocumentVaultCaptureView {
                    loadEntries()
                }
            }
        }
        .alert("Vault Access", isPresented: unlockAlertBinding) {
            Button("OK", role: .cancel) {
                unlockErrorMessage = nil
            }
        } message: {
            Text(unlockErrorMessage ?? "Vault access failed.")
        }
    }

    private var lockedState: some View {
        ContentUnavailableView(
            "Vault Locked",
            systemImage: "lock.shield",
            description: Text("Documents stay encrypted on device and are excluded from Ask, widgets, Spotlight, and export flows.")
        )
        .overlay(alignment: .bottom) {
            VStack(spacing: Spacing.sm) {
                Button {
                    Task { await unlockVault() }
                } label: {
                    HStack {
                        Label("Unlock Vault", systemImage: "faceid")
                        if isUnlocking {
                            ProgressView()
                                .padding(.leading, Spacing.xs)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("document-vault-unlock")
                .buttonStyle(.borderedProminent)
                .disabled(isUnlocking)

                Text("Unlock uses local device authentication only.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    private var listContent: some View {
        List {
            Section("Encrypted Local Documents") {
                ForEach(filteredEntries) { entry in
                    NavigationLink {
                        DocumentVaultDetailView(entryID: entry.id)
                    } label: {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            HStack {
                                Label(entry.title, systemImage: entry.category.systemImage)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: Int64(entry.byteCount), countStyle: .file))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Text(entry.category.displayName)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if let ocrSummary = entry.ocrSummary, !ocrSummary.isEmpty {
                                Text(ocrSummary)
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
    }

    private var filteredEntries: [DocumentVaultEntry] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return entries }

        return entries.filter { entry in
            entry.title.localizedCaseInsensitiveContains(trimmedQuery)
                || entry.category.displayName.localizedCaseInsensitiveContains(trimmedQuery)
                || (entry.ocrSummary?.localizedCaseInsensitiveContains(trimmedQuery) ?? false)
        }
    }

    private var unlockAlertBinding: Binding<Bool> {
        Binding(
            get: { unlockErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    unlockErrorMessage = nil
                }
            }
        )
    }

    private func unlockVault() async {
        isUnlocking = true
        defer { isUnlocking = false }

        do {
            try await DocumentVaultAuthenticator.unlock(reason: "Unlock your encrypted document vault.")
            isUnlocked = true
            hapticFeedbackService?.play(.success)
            loadEntries()
        } catch {
            unlockErrorMessage = error.localizedDescription
            hapticFeedbackService?.play(.error)
        }
    }

    private func loadEntries() {
        do {
            entries = try repository?.listEntries() ?? []
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }
}

#Preview {
    NavigationStack {
        DocumentVaultScreen()
    }
}
