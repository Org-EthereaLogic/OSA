import SwiftUI

struct ChapterDetailView: View {
    let slug: String

    @Environment(\.handbookRepository) private var repository
    @State private var chapter: HandbookChapter?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This chapter could not be loaded.")
                )
            } else if let chapter {
                List {
                    Section {
                        ChapterHeroCard(chapter: chapter)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }

                    Section {
                        ForEach(chapter.sections.sorted(by: { $0.sortOrder < $1.sortOrder })) { section in
                            NavigationLink {
                                HandbookSectionDetailView(sectionID: section.id)
                            } label: {
                                SectionRow(section: section)
                            }
                            .listRowBackground(Color.osaSurface)
                        }
                    } header: {
                        Text("\(chapter.sections.count) Sections")
                            .font(.categoryLabel)
                            .foregroundStyle(.secondary)
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            } else {
                ProgressView("Loading\u{2026}")
            }
        }
        .navigationTitle(chapter?.title ?? "Chapter")
        .navigationBarTitleDisplayMode(.large)
        .background(.osaBackground)
        .task { loadChapter() }
    }

    private func loadChapter() {
        do {
            chapter = try repository?.chapter(slug: slug)
            if chapter == nil { loadFailed = true }
        } catch {
            loadFailed = true
        }
    }
}

// MARK: - Chapter Hero Card

private struct ChapterHeroCard: View {
    let chapter: HandbookChapter

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(chapter.summary)
                .font(.brandSubheadline)
                .foregroundStyle(Color.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.sm) {
                if chapter.isSeeded {
                    Label("Curated", systemImage: "checkmark.seal.fill")
                        .font(.metadataCaption)
                        .foregroundStyle(.osaPaperGlow)
                }

                if let reviewed = chapter.lastReviewedAt {
                    Label(
                        reviewed.formatted(date: .abbreviated, time: .omitted),
                        systemImage: "clock"
                    )
                    .font(.metadataCaption)
                    .foregroundStyle(.osaPaperGlow.opacity(0.7))
                }

                Label(
                    "\(chapter.sections.count) sections",
                    systemImage: "doc.text"
                )
                .font(.metadataCaption)
                .foregroundStyle(.osaPaperGlow.opacity(0.7))
            }
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
}

// MARK: - Section Row

private struct SectionRow: View {
    let section: HandbookSection

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(section.heading)
                .font(.cardTitle)

            Text(section.plainText.prefix(120) + (section.plainText.count > 120 ? "\u{2026}" : ""))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: Spacing.sm) {
                if section.safetyLevel == .sensitiveStaticOnly {
                    Label("Sensitive", systemImage: "exclamationmark.shield")
                        .font(.metadataCaption)
                        .foregroundStyle(.osaEmergency)
                }

                if let reviewed = section.lastReviewedAt {
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
        ChapterDetailView(slug: "sample-chapter")
    }
}
