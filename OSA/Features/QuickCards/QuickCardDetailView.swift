import SwiftUI

struct QuickCardDetailView: View {
    let card: QuickCard

    @Environment(\.handbookRepository) private var handbookRepository
    @Environment(\.quickCardRepository) private var quickCardRepository
    @Environment(\.practiceProgressRepository) private var practiceProgressRepository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(PinnedContentSettings.pinnedQuickCardIDsKey)
    private var pinnedQuickCardIDsRawValue = PinnedContentSettings.encode(ids: [])
    @AppStorage(AccessibilitySettings.largePrintReadingModeKey)
    private var largePrintReadingMode = AccessibilitySettings.largePrintReadingModeDefault
    @AppStorage(AccessibilitySettings.appLanguageKey)
    private var appLanguageRawValue = AccessibilitySettings.appLanguageDefault.rawValue
    @AppStorage(AccessibilitySettings.highContrastModeKey)
    private var highContrastMode = AccessibilitySettings.highContrastModeDefault
    @State private var relatedSections: [HandbookSection] = []
    @State private var sharePayload: ActivitySharePayload?
    @State private var quizProgress: QuizProgress?
    @State private var weeklyDrillCompletion: WeeklyDrillCompletion?
    @State private var showingQuiz = false
    @State private var isCurrentWeeklyDrillCard = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label {
                        Text(card.category)
                            .font(.categoryLabel)
                            .textCase(.uppercase)
                    } icon: {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                    }
                    .foregroundStyle(.osaEmber)

                    Text(card.localizedTitle(for: appLanguage))
                        .font(.stressTitle)
                        .foregroundStyle(Color.osaHeroPrimaryText(highContrast: highContrastMode))
                        .fixedSize(horizontal: false, vertical: true)

                    Text(card.localizedSummary(for: appLanguage))
                        .font(.brandSubheadline)
                        .foregroundStyle(Color.osaHeroSecondaryText(highContrast: highContrastMode))
                        .fixedSize(horizontal: false, vertical: true)

                    let metadataLayout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
                        : AnyLayout(HStackLayout(spacing: Spacing.sm))

                    metadataLayout {
                        Label("Stored locally", systemImage: "internaldrive.fill")
                            .font(.metadataCaption)
                            .foregroundStyle(Color.osaHeroMetadataText(highContrast: highContrastMode))

                        if let reviewed = card.lastReviewedAt {
                            Label(
                                reviewed.formatted(date: .abbreviated, time: .omitted),
                                systemImage: "checkmark.seal.fill"
                            )
                            .font(.metadataCaption)
                            .foregroundStyle(Color.osaHeroMetadataText(highContrast: highContrastMode))
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
                        .stroke(
                            highContrastMode ? Color.osaReadableStroke(highContrast: true) : Color.osaPrimary.opacity(0.24),
                            lineWidth: 1
                        )
                }

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if !completionBadges.isEmpty {
                        CompletionBadgeStripView(badges: completionBadges)
                    }

                    ContentMediaSectionView(attachments: card.mediaAttachments)

                    if let quizDefinition = card.quizDefinition {
                        QuickCardPracticePanelView(
                            quizDefinition: quizDefinition,
                            quizProgress: quizProgress,
                            isCurrentWeeklyDrillCard: isCurrentWeeklyDrillCard,
                            weeklyDrillMetadata: card.weeklyDrillMetadata,
                            weeklyDrillCompletion: currentWeeklyDrillCompletion
                        ) {
                            showingQuiz = true
                        }
                    }

                    if card.largeTypeLayoutVersion >= 2 {
                        QuickCardInfographicLayout(
                            card: card,
                            largePrintReadingMode: largePrintReadingMode,
                            language: appLanguage,
                            highContrastMode: highContrastMode
                        )
                    } else if let attributed = try? AttributedString(
                        markdown: MarkdownPreprocessor.prepare(card.localizedBodyMarkdown(for: appLanguage))
                    ) {
                        Text(attributed)
                            .font(largePrintReadingMode ? .system(size: 24, weight: .medium, design: .rounded) : .cardBody)
                    } else {
                        Text(card.localizedSummary(for: appLanguage))
                            .font(largePrintReadingMode ? .system(size: 24, weight: .medium, design: .rounded) : .cardBody)
                    }

                    if card.lastReviewedAt != nil || !card.tags.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            if let reviewed = card.lastReviewedAt {
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

                    if !relatedSections.isEmpty {
                        Divider()

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Related Handbook")
                                .font(.sectionHeader)
                                .accessibilityAddTraits(.isHeader)

                            ForEach(relatedSections) { section in
                                NavigationLink {
                                    HandbookSectionDetailView(sectionID: section.id)
                                } label: {
                                    Label(section.heading, systemImage: "book.closed.fill")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, Spacing.md)
                                        .padding(.vertical, Spacing.sm)
                                        .background(
                                            Color.osaReadableBackground(highContrast: highContrastMode),
                                            in: RoundedRectangle(cornerRadius: CornerRadius.md)
                                        )
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens the related handbook section.")
                            }
                        }
                    }
                }
                .padding(Spacing.lg)
                .background(Color.osaReadableSurface(highContrast: highContrastMode), in: RoundedRectangle(cornerRadius: CornerRadius.lg))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.lg)
                        .stroke(Color.osaReadableStroke(highContrast: highContrastMode), lineWidth: 1)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .padding(.bottom, Spacing.xxxl)
        }
        .background(Color.osaReadableBackground(highContrast: highContrastMode))
        .navigationTitle(card.localizedTitle(for: appLanguage))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    sharePayload = ActivitySharePayload(
                        items: [ContentShareFormatter.quickCardText(for: card, language: appLanguage)],
                        subject: card.localizedTitle(for: appLanguage)
                    )
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Share quick card")
                .accessibilityHint("Shares this quick card as text with local attribution.")

                PinToolbarButton(
                    isPinned: isPinned,
                    pinLabel: "Pin quick card",
                    unpinLabel: "Unpin quick card",
                    hint: "Adds this quick card to pinned content on Home."
                ) {
                    pinnedQuickCardIDsRawValue = PinnedContentSettings.toggled(card.id, rawValue: pinnedQuickCardIDsRawValue)
                    hapticFeedbackService?.play(.pinToggle)
                }
            }
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(payload: payload)
        }
        .sheet(isPresented: $showingQuiz) {
            if let quizDefinition = card.quizDefinition {
                QuizSessionView(
                    contentTitle: card.localizedTitle(for: appLanguage),
                    contentID: card.id,
                    quiz: quizDefinition
                ) { progress in
                    quizProgress = progress
                    completeWeeklyDrillIfNeeded(completedAt: progress.lastCompletedAt)
                }
            }
        }
        .task {
            loadRelatedSections()
            loadPracticeState()
        }
    }

    private var isPinned: Bool {
        PinnedContentSettings.isPinned(card.id, rawValue: pinnedQuickCardIDsRawValue)
    }

    private var currentWeeklyDrillCompletion: WeeklyDrillCompletion? {
        guard weeklyDrillCompletion?.contentID == card.id else { return nil }
        return weeklyDrillCompletion
    }

    private var completionBadges: [CompletionBadge] {
        CompletionBadge.derive(
            quizProgress: quizProgress,
            quizDefinition: card.quizDefinition,
            weeklyDrillCompletion: currentWeeklyDrillCompletion
        )
    }

    private func loadRelatedSections() {
        guard let handbookRepository else { return }
        relatedSections = card.relatedSectionIDs.compactMap { id in
            try? handbookRepository.section(id: id)
        }
    }

    private func loadPracticeState() {
        if let practiceProgressRepository {
            quizProgress = try? practiceProgressRepository.quizProgress(for: card.id)
            weeklyDrillCompletion = try? practiceProgressRepository.weeklyDrillCompletion(for: PracticeSchedule.weekToken())
        } else {
            quizProgress = nil
            weeklyDrillCompletion = nil
        }

        do {
            let allCards = try quickCardRepository?.listQuickCards() ?? []
            isCurrentWeeklyDrillCard = PracticeSchedule.currentWeeklyDrill(from: allCards)?.id == card.id
        } catch {
            isCurrentWeeklyDrillCard = false
        }
    }

    private func completeWeeklyDrillIfNeeded(completedAt: Date) {
        guard isCurrentWeeklyDrillCard, let practiceProgressRepository else { return }
        weeklyDrillCompletion = try? practiceProgressRepository.markWeeklyDrillCompleted(
            contentID: card.id,
            weekToken: PracticeSchedule.weekToken(),
            completedAt: completedAt
        )
    }

    private var appLanguage: AppLanguage {
        AccessibilitySettings.appLanguage(from: appLanguageRawValue)
    }
}

private struct QuickCardInfographicLayout: View {
    let card: QuickCard
    let largePrintReadingMode: Bool
    let language: AppLanguage
    let highContrastMode: Bool

    private var columns: [GridItem] {
        if largePrintReadingMode {
            [GridItem(.flexible())]
        } else {
            [
                GridItem(.flexible(), spacing: Spacing.md),
                GridItem(.flexible(), spacing: Spacing.md)
            ]
        }
    }

    private var panels: [QuickCardInfographicPanel] {
        quickCardInfographicPanels(from: card.localizedBodyMarkdown(for: language))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Infographic Layout", systemImage: "rectangle.grid.2x2.fill")
                .font(.metadataCaption)
                .foregroundStyle(.osaPrimary)

            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.md) {
                ForEach(panels) { panel in
                    VStack(alignment: .leading, spacing: Spacing.sm) {
                        Text(panel.title)
                            .font(.categoryLabel)
                            .foregroundStyle(.osaPrimary)

                        if let attributed = try? AttributedString(markdown: panel.bodyMarkdown) {
                            Text(attributed)
                                .font(
                                    largePrintReadingMode
                                        ? .system(size: 22, weight: .medium, design: .rounded)
                                        : .body.weight(.medium)
                                )
                        } else {
                            Text(panel.bodyMarkdown)
                                .font(
                                    largePrintReadingMode
                                        ? .system(size: 22, weight: .medium, design: .rounded)
                                        : .body.weight(.medium)
                                )
                        }
                    }
                    .padding(Spacing.md)
                    .frame(maxWidth: .infinity, minHeight: 144, alignment: .topLeading)
                    .background(
                        LinearGradient(
                            colors: [
                                Color.osaReadableBackground(highContrast: highContrastMode),
                                highContrastMode ? Color.osaPrimary.opacity(0.18) : Color.osaPrimary.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: CornerRadius.md)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(
                                highContrastMode ? Color.osaReadableStroke(highContrast: true) : Color.osaPrimary.opacity(0.18),
                                lineWidth: 1
                            )
                    }
                }
            }
        }
    }
}

private struct QuickCardInfographicPanel: Identifiable {
    let title: String
    let bodyMarkdown: String

    var id: String { title }
}

private func quickCardInfographicPanels(from markdown: String) -> [QuickCardInfographicPanel] {
    let prepared = MarkdownPreprocessor.prepare(markdown)
    let lines = prepared.components(separatedBy: .newlines)
    var panels: [QuickCardInfographicPanel] = []
    var currentTitle: String?
    var currentLines: [String] = []

    func flushPanel() {
        guard let currentTitle, !currentLines.isEmpty else { return }
        panels.append(
            QuickCardInfographicPanel(
                title: currentTitle,
                bodyMarkdown: currentLines.joined(separator: "\n")
            )
        )
    }

    for line in lines {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { continue }

        if trimmed.hasPrefix("## ") {
            flushPanel()
            currentTitle = String(trimmed.dropFirst(3))
            currentLines = []
        } else {
            currentLines.append(trimmed)
        }
    }

    flushPanel()

    if panels.isEmpty {
        return [
            QuickCardInfographicPanel(
                title: "Key Actions",
                bodyMarkdown: prepared
            )
        ]
    }

    return panels
}

private struct QuickCardPracticePanelView: View {
    let quizDefinition: QuizDefinition
    let quizProgress: QuizProgress?
    let isCurrentWeeklyDrillCard: Bool
    let weeklyDrillMetadata: WeeklyDrillMetadata?
    let weeklyDrillCompletion: WeeklyDrillCompletion?
    let onStartQuiz: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Practice Quiz", systemImage: "questionmark.circle.fill")
                .font(.sectionHeader)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Text(progressText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let weeklyDrillMessage {
                Label(weeklyDrillMessage, systemImage: weeklyDrillCompletion == nil ? "calendar.badge.clock" : "calendar.badge.checkmark")
                    .font(.caption)
                    .foregroundStyle(weeklyDrillCompletion == nil ? .osaPrimary : .osaLocal)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button(action: onStartQuiz) {
                Label(quizProgress == nil ? "Start Quiz" : "Retake Quiz", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.osaPrimary)
            .accessibilityIdentifier("quick-card-start-quiz")
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
    }

    private var progressText: String {
        guard let quizProgress else {
            return "Answer \(quizDefinition.questionCount) questions locally to save completion on this device."
        }

        return "Best local score: \(quizProgress.bestCorrectCount) of \(quizProgress.totalQuestionCount) correct."
    }

    private var weeklyDrillMessage: String? {
        guard let weeklyDrillMetadata else { return nil }
        if weeklyDrillCompletion != nil {
            return "\(weeklyDrillMetadata.badgeLabel) completed for this week."
        }
        if isCurrentWeeklyDrillCard {
            return weeklyDrillMetadata.prompt
        }
        return "Eligible for the weekly drill rotation."
    }
}

#Preview {
    NavigationStack {
        QuickCardDetailView(
            card: QuickCard(
                id: UUID(),
                title: "Sample Quick Card",
                slug: "sample",
                category: "First Aid",
                summary: "A brief summary of the card.",
                bodyMarkdown: "**Step 1:** Do something important.\n\n**Step 2:** Follow up.",
                priority: 10,
                relatedSectionIDs: [],
                tags: ["first-aid"],
                lastReviewedAt: AppClock.now(),
                largeTypeLayoutVersion: 1
            )
        )
    }
}
