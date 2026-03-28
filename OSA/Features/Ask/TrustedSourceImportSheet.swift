import SwiftUI

/// A sheet presented from Ask that lets the user browse approved publishers,
/// enter a trusted HTTPS page URL, preview fetched content, and import it
/// into the local knowledge base.
struct TrustedSourceImportSheet: View {
    @Bindable var viewModel: TrustedSourceImportViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.importState {
                case .browsing:
                    browseView
                case .fetching:
                    statusView(
                        icon: "arrow.down.circle",
                        label: "Fetching page...",
                        showProgress: true
                    )
                case .previewing:
                    previewView
                case .importing:
                    statusView(
                        icon: "square.and.arrow.down",
                        label: "Saving locally and indexing...",
                        showProgress: true
                    )
                case .succeeded:
                    successView
                case .failed:
                    failedView
                }
            }
            .navigationTitle("Import Trusted Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.importState != .succeeded {
                        Button("Cancel") { dismiss() }
                    }
                }
            }
        }
    }

    // MARK: - Browse

    private var browseView: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Enter a page URL from an approved publisher to import it for offline use.")
                        .font(.metadataCaption)
                        .foregroundStyle(.secondary)

                    TextField("https://www.ready.gov/...", text: $viewModel.urlText)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)

                    if case .invalid(let reason) = viewModel.urlValidation {
                        Text(reason)
                            .font(.caption)
                            .foregroundStyle(.osaCritical)
                    }

                    Button {
                        Task { await viewModel.fetchPreview() }
                    } label: {
                        Label("Preview Page", systemImage: "eye")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.urlValidation.isValid)
                }
            } header: {
                Text("Page URL")
            }

            Section {
                if viewModel.approvedSources.isEmpty {
                    Text("No matching publishers.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.approvedSources, id: \.canonicalHost) { source in
                        Button {
                            viewModel.prefillHost(source.canonicalHost)
                        } label: {
                            publisherRow(source)
                        }
                        .buttonStyle(.plain)
                    }
                }
            } header: {
                Text("Approved Publishers")
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Filter publishers")
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
    }

    private func publisherRow(_ source: TrustedSourceDefinition) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(spacing: Spacing.xs) {
                Text(source.publisherName)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                Text(trustLabel(source.trustLevel))
                    .font(.caption2)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, 2)
                    .background(.osaSurface, in: Capsule())
                    .foregroundStyle(.secondary)
            }

            Text(source.canonicalHost)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let notes = source.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, Spacing.xxs)
    }

    private func trustLabel(_ level: TrustLevel) -> String {
        switch level {
        case .curated: "Curated"
        case .community: "Community"
        case .unverified: "Unverified"
        }
    }

    // MARK: - Status

    private func statusView(icon: String, label: String, showProgress: Bool) -> some View {
        VStack(spacing: Spacing.lg) {
            Spacer()
            if showProgress {
                ProgressView()
                    .scaleEffect(1.5)
            } else {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
            Text(label)
                .font(.headline)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
    }

    // MARK: - Preview

    private var previewView: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        if let title = viewModel.previewTitle {
                            Text(title)
                                .font(.headline)
                        }

                        if let domain = viewModel.previewDomain {
                            Label(domain, systemImage: "globe")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Source")
                }

                if let excerpt = viewModel.previewExcerpt {
                    Section {
                        Text(excerpt)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(8)
                    } header: {
                        Text("Content Preview")
                    }
                }

                Section {
                    Text("Importing saves this page locally for offline access. It will be indexed and available in Ask and Library search.")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .scrollContentBackground(.hidden)
            .background(.osaBackground)

            VStack(spacing: Spacing.sm) {
                Button {
                    Task { await viewModel.confirmImport() }
                } label: {
                    Label("Import for Offline Use", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("Back to Search") {
                    viewModel.resetToSearch()
                }
                .font(.subheadline)
            }
            .padding()
            .background(.osaSurface)
        }
    }

    // MARK: - Success

    private var successView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.osaLocal)

            Text("Imported Successfully")
                .font(.headline)

            if let title = viewModel.previewTitle {
                Text("\"\(title)\" is now available offline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("Your original question will be re-run against updated local sources.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Return to Ask")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
    }

    // MARK: - Failed

    private var failedView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.osaEmergency)

            Text("Import Failed")
                .font(.headline)

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button {
                    viewModel.resetToSearch()
                } label: {
                    Text("Try Another Source")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button("Cancel") {
                    dismiss()
                }
                .font(.subheadline)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}
