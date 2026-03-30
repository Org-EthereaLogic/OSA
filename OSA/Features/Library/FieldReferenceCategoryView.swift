import SwiftUI

struct FieldReferenceCategoryView: View {
    let category: FieldReferenceCategory

    @Environment(\.fieldReferenceRepository) private var repository
    @State private var entries: [FieldReferenceEntry] = []
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Field references could not be loaded.")
                )
            } else if entries.isEmpty {
                ContentUnavailableView(
                    category.displayName,
                    systemImage: category.systemImage,
                    description: Text("No local field references are available in this category yet.")
                )
            } else {
                List {
                    Section {
                        categoryHero
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    Section("\(entries.count) References") {
                        ForEach(entries) { entry in
                            NavigationLink {
                                FieldReferenceDetailView(entry: entry)
                            } label: {
                                FieldReferenceEntryRow(entry: entry)
                            }
                            .listRowBackground(Color.osaSurface)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(.osaBackground)
            }
        }
        .navigationTitle(category.displayName)
        .navigationBarTitleDisplayMode(.large)
        .task { loadEntries() }
    }

    private var categoryHero: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label(category.displayName, systemImage: category.systemImage)
                .font(.sectionHeader)
                .foregroundStyle(.osaPaperGlow)

            Text(category.summary)
                .font(.brandSubheadline)
                .foregroundStyle(Color.white.opacity(0.82))
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.osaCanopy, Color.osaPine, Color.osaNight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: CornerRadius.xl)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaPrimary.opacity(0.24), lineWidth: 1)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.sm)
    }

    private func loadEntries() {
        do {
            entries = try repository?.listEntries(category: category) ?? []
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }
}

private struct FieldReferenceEntryRow: View {
    let entry: FieldReferenceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(entry.title)
                .font(.cardTitle)

            Text(entry.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: Spacing.sm) {
                if entry.safetyLevel == .sensitiveStaticOnly {
                    Label("Sensitive", systemImage: "exclamationmark.shield")
                        .font(.metadataCaption)
                        .foregroundStyle(.osaEmergency)
                }

                if let reviewed = entry.lastReviewedAt {
                    Label(
                        reviewed.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "checkmark.seal.fill"
                    )
                    .font(.metadataCaption)
                    .foregroundStyle(.osaTrust)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        FieldReferenceCategoryView(category: .firstAid)
    }
}
