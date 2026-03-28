import SwiftUI

struct HandbookSectionDetailView: View {
    let sectionID: UUID

    @Environment(\.handbookRepository) private var repository
    @Environment(\.quickCardRepository) private var quickCardRepository
    @Environment(\.onscreenContentManager) private var onscreenContentManager
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @AppStorage(PinnedContentSettings.pinnedSectionIDsKey)
    private var pinnedSectionIDsRawValue = PinnedContentSettings.encode(ids: [])
    @AppStorage(AccessibilitySettings.largePrintReadingModeKey)
    private var largePrintReadingMode = AccessibilitySettings.largePrintReadingModeDefault
    @State private var section: HandbookSection?
    @State private var chapter: HandbookChapter?
    @State private var relatedCards: [QuickCard] = []
    @State private var relatedSections: [HandbookSection] = []
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This section could not be loaded.")
                )
            } else if let section {
                content(section)
            } else {
                ProgressView("Loading...")
            }
        }
        .navigationTitle(section?.heading ?? "Section")
        .navigationBarTitleDisplayMode(.inline)
        .background(.osaBackground)
        .task { loadSection() }
        .onDisappear { onscreenContentManager?.clear() }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    pinnedSectionIDsRawValue = PinnedContentSettings.toggled(sectionID, rawValue: pinnedSectionIDsRawValue)
                    hapticFeedbackService?.play(.pinToggle)
                } label: {
                    Image(systemName: isPinned ? "pin.fill" : "pin")
                }
                .accessibilityLabel(isPinned ? "Unpin handbook section" : "Pin handbook section")
            }
        }
    }

    @ViewBuilder
    private func content(_ section: HandbookSection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                // Hero header card
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    if let chapter {
                        Label(chapter.title, systemImage: "book.closed.fill")
                            .font(.metadataCaption)
                            .foregroundStyle(.osaPaperGlow.opacity(0.7))
                    }

                    Text(section.heading)
                        .font(.stressTitle)
                        .foregroundStyle(.white)

                    HStack(spacing: Spacing.sm) {
                        if section.safetyLevel == .sensitiveStaticOnly {
                            Label("Sensitive", systemImage: "exclamationmark.shield")
                                .font(.metadataCaption)
                                .foregroundStyle(.osaEmber)
                        }

                        Label("Stored locally", systemImage: "internaldrive.fill")
                            .font(.metadataCaption)
                            .foregroundStyle(.osaPaperGlow)

                        if let reviewed = section.lastReviewedAt {
                            Label(
                                reviewed.formatted(date: .abbreviated, time: .omitted),
                                systemImage: "checkmark.seal.fill"
                            )
                            .font(.metadataCaption)
                            .foregroundStyle(.osaPaperGlow)
                        }
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

                // Body content card
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if let attributed = try? AttributedString(markdown: MarkdownPreprocessor.prepare(section.bodyMarkdown)) {
                        Text(attributed)
                            .font(largePrintReadingMode ? .system(size: 24, weight: .medium, design: .rounded) : .body)
                    } else {
                        Text(section.plainText)
                            .font(largePrintReadingMode ? .system(size: 24, weight: .medium, design: .rounded) : .body)
                    }

                    if section.lastReviewedAt != nil || !section.tags.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            if let reviewed = section.lastReviewedAt {
                                Label(
                                    "Reviewed \(reviewed.formatted(date: .abbreviated, time: .omitted))",
                                    systemImage: "checkmark.seal.fill"
                                )
                                .font(.metadataCaption)
                                .foregroundStyle(.osaTrust)
                            }

                            Label("Stored locally on this device", systemImage: "internaldrive.fill")
                                .font(.metadataCaption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if !relatedCards.isEmpty || !relatedSections.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Related Content")
                                .font(.sectionHeader)

                            ForEach(relatedCards) { card in
                                NavigationLink {
                                    QuickCardDetailView(card: card)
                                } label: {
                                    Label(card.title, systemImage: "bolt.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                                }
                                .buttonStyle(.plain)
                            }

                            ForEach(relatedSections) { related in
                                NavigationLink {
                                    HandbookSectionDetailView(sectionID: related.id)
                                } label: {
                                    Label(related.heading, systemImage: "book.closed.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
                .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.osaHairline, lineWidth: 1)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .padding(.bottom, Spacing.xxxl)
        }
    }

    private func loadSection() {
        do {
            guard let loadedSection = try repository?.section(id: sectionID) else {
                loadFailed = true
                return
            }

            section = loadedSection
            chapter = try repository?.chapter(id: loadedSection.chapterID)
            loadRelatedContent(for: loadedSection)
            onscreenContentManager?.publishHandbookSection(
                id: loadedSection.id,
                heading: loadedSection.heading,
                chapterTitle: chapter?.title ?? ""
            )
        } catch {
            loadFailed = true
            onscreenContentManager?.clear()
        }
    }

    private var isPinned: Bool {
        PinnedContentSettings.isPinned(sectionID, rawValue: pinnedSectionIDsRawValue)
    }

    private func loadRelatedContent(for loadedSection: HandbookSection) {
        let scenarioTags = Set(loadedSection.tags.filter { $0.hasPrefix("scenario:") })

        if let quickCardRepository {
            let cards = (try? quickCardRepository.listQuickCards()) ?? []
            relatedCards = cards.filter { card in
                card.relatedSectionIDs.contains(loadedSection.id)
                    || !scenarioTags.isDisjoint(with: Set(card.tags))
            }
            .prefix(3)
            .map { $0 }
        } else {
            relatedCards = []
        }

        if let chapter {
            relatedSections = chapter.sections.filter { candidate in
                candidate.id != loadedSection.id
                    && (!scenarioTags.isDisjoint(with: Set(candidate.tags))
                        || candidate.parentSectionID == loadedSection.parentSectionID)
            }
            .prefix(3)
            .map { $0 }
        } else {
            relatedSections = []
        }
    }
}

#Preview {
    NavigationStack {
        HandbookSectionDetailView(sectionID: UUID())
    }
}
