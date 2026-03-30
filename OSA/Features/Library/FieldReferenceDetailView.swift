import SwiftUI

struct FieldReferenceDetailView: View {
    let entry: FieldReferenceEntry

    @Environment(\.handbookRepository) private var handbookRepository
    @Environment(\.practiceProgressRepository) private var practiceProgressRepository
    @AppStorage(AccessibilitySettings.largePrintReadingModeKey)
    private var largePrintReadingMode = AccessibilitySettings.largePrintReadingModeDefault
    @State private var relatedSections: [HandbookSection] = []
    @State private var quizProgress: QuizProgress?
    @State private var showingQuiz = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                heroCard

                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if !completionBadges.isEmpty {
                        CompletionBadgeStripView(badges: completionBadges)
                    }

                    ContentMediaSectionView(attachments: entry.mediaAttachments)

                    if let quizDefinition = entry.quizDefinition {
                        FieldReferencePracticePanelView(
                            quizDefinition: quizDefinition,
                            quizProgress: quizProgress
                        ) {
                            showingQuiz = true
                        }
                    }

                    ForEach(entry.sortedSections) { section in
                        FieldReferenceSectionCard(
                            section: section,
                            largePrintReadingMode: largePrintReadingMode
                        )
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
        .background(.osaBackground)
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingQuiz) {
            if let quizDefinition = entry.quizDefinition {
                QuizSessionView(
                    contentTitle: entry.title,
                    contentID: entry.id,
                    quiz: quizDefinition
                ) { progress in
                    quizProgress = progress
                }
            }
        }
        .task {
            loadRelatedSections()
            loadPracticeState()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Label {
                Text(entry.category.displayName)
                    .font(.categoryLabel)
                    .textCase(.uppercase)
            } icon: {
                Image(systemName: entry.category.systemImage)
                    .font(.caption2)
            }
            .foregroundStyle(.osaPrimary)

            Text(entry.title)
                .font(.stressTitle)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.summary)
                .font(.brandSubheadline)
                .foregroundStyle(Color.white.opacity(0.82))
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: Spacing.sm) {
                Label("Stored locally", systemImage: "internaldrive.fill")
                    .font(.metadataCaption)
                    .foregroundStyle(.osaPaperGlow)

                if entry.safetyLevel == .sensitiveStaticOnly {
                    Label("Static-only", systemImage: "exclamationmark.shield.fill")
                        .font(.metadataCaption)
                        .foregroundStyle(.osaPaperGlow)
                }

                if let reviewed = entry.lastReviewedAt {
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
    }

    private func loadRelatedSections() {
        guard let handbookRepository else { return }
        relatedSections = entry.relatedSectionIDs.compactMap { id in
            try? handbookRepository.section(id: id)
        }
    }

    private var completionBadges: [CompletionBadge] {
        CompletionBadge.derive(
            quizProgress: quizProgress,
            quizDefinition: entry.quizDefinition,
            weeklyDrillCompletion: nil
        )
    }

    private func loadPracticeState() {
        guard let practiceProgressRepository else {
            quizProgress = nil
            return
        }

        quizProgress = try? practiceProgressRepository.quizProgress(for: entry.id)
    }
}

private struct FieldReferenceSectionCard: View {
    let section: FieldReferenceSection
    let largePrintReadingMode: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(section.title)
                .font(.sectionHeader)
                .foregroundStyle(.primary)

            if let attributed = try? AttributedString(markdown: MarkdownPreprocessor.prepare(section.bodyMarkdown)) {
                Text(attributed)
                    .font(largePrintReadingMode ? .system(size: 22, weight: .medium, design: .rounded) : .cardBody)
            } else {
                Text(section.plainText)
                    .font(largePrintReadingMode ? .system(size: 22, weight: .medium, design: .rounded) : .cardBody)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
    }
}

private struct FieldReferencePracticePanelView: View {
    let quizDefinition: QuizDefinition
    let quizProgress: QuizProgress?
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

            Button(action: onStartQuiz) {
                Label(quizProgress == nil ? "Start Quiz" : "Retake Quiz", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.osaPrimary)
            .accessibilityIdentifier("field-reference-start-quiz")
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
            return "Answer \(quizDefinition.questionCount) questions locally to save completion for this reference."
        }
        return "Best local score: \(quizProgress.bestCorrectCount) of \(quizProgress.totalQuestionCount) correct."
    }
}

#Preview {
    NavigationStack {
        FieldReferenceDetailView(
            entry: FieldReferenceEntry(
                id: UUID(),
                slug: "reference-preview",
                title: "Water Treatment Reference",
                category: .waterTreatment,
                summary: "Short, local-first water treatment reference.",
                sortOrder: 100,
                sections: [
                    FieldReferenceSection(
                        title: "Immediate Actions",
                        bodyMarkdown: "- Treat only clear water when possible.\n- Keep treated and untreated containers separate.",
                        plainText: "Treat only clear water when possible. Keep treated and untreated containers separate.",
                        sortOrder: 100
                    )
                ],
                relatedSectionIDs: [],
                tags: ["water"],
                safetyLevel: .normal,
                lastReviewedAt: Date()
            )
        )
    }
}
