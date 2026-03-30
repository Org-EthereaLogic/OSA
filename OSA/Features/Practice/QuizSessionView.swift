import SwiftUI

struct QuizSessionView: View {
    let contentTitle: String
    let contentID: UUID
    let quiz: QuizDefinition
    let onCompleted: (QuizProgress) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.practiceProgressRepository) private var practiceProgressRepository

    @State private var currentQuestionIndex = 0
    @State private var selectedOptionIDs: [String: String] = [:]
    @State private var isAnswerRevealed = false
    @State private var completedProgress: QuizProgress?

    var body: some View {
        NavigationStack {
            Group {
                if let completedProgress {
                    resultView(progress: completedProgress)
                } else {
                    questionView
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .navigationTitle(quiz.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .background(.osaBackground)
        }
    }

    private var currentQuestion: QuizQuestion {
        quiz.questions[currentQuestionIndex]
    }

    private var selectedOptionID: String? {
        selectedOptionIDs[currentQuestion.id]
    }

    private var questionView: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                Text(contentTitle)
                    .font(.brandEyebrow)
                    .foregroundStyle(.secondary)

                Text("Question \(currentQuestionIndex + 1) of \(quiz.questionCount)")
                    .font(.categoryLabel)
                    .foregroundStyle(.osaPrimary)

                ProgressView(value: Double(currentQuestionIndex + (isAnswerRevealed ? 1 : 0)), total: Double(max(quiz.questionCount, 1)))
                    .tint(.osaPrimary)

                Text(currentQuestion.prompt)
                    .font(.sectionHeader)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(spacing: Spacing.sm) {
                ForEach(currentQuestion.options) { option in
                    Button {
                        guard !isAnswerRevealed else { return }
                        selectedOptionIDs[currentQuestion.id] = option.id
                        isAnswerRevealed = true
                    } label: {
                        HStack(alignment: .top, spacing: Spacing.sm) {
                            Image(systemName: icon(for: option))
                                .foregroundStyle(color(for: option))
                                .frame(width: 20)

                            Text(option.text)
                                .font(.body)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)

                            Spacer(minLength: 0)
                        }
                        .padding(Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(background(for: option), in: RoundedRectangle(cornerRadius: CornerRadius.md))
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(border(for: option), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(isAnswerRevealed)
                }
            }

            if isAnswerRevealed {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Label(answerTitle, systemImage: answerIcon)
                        .font(.headline)
                        .foregroundStyle(answerColor)

                    Text(currentQuestion.explanation)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.osaHairline, lineWidth: 1)
                }
            }

            Spacer(minLength: 0)

            Button(action: advanceQuiz) {
                Text(currentQuestionIndex == quiz.questionCount - 1 ? "Finish Quiz" : "Next Question")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.osaPrimary)
            .disabled(!isAnswerRevealed)
        }
    }

    private func resultView(progress: QuizProgress) -> some View {
        let badges = CompletionBadge.derive(
            quizProgress: progress,
            quizDefinition: quiz,
            weeklyDrillCompletion: nil
        )

        return VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(contentTitle)
                .font(.brandEyebrow)
                .foregroundStyle(.secondary)

            Text("\(progress.bestCorrectCount) of \(progress.totalQuestionCount) correct")
                .font(.stressTitle)

            Text(progress.isMastered(masteryScorePercent: quiz.masteryScorePercent) ? "Mastery earned for this quiz." : "Saved locally. You can retake this quiz anytime to improve your score.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            CompletionBadgeStripView(badges: badges)

            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(.osaPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func advanceQuiz() {
        guard currentQuestionIndex < quiz.questionCount else {
            return
        }

        if currentQuestionIndex == quiz.questionCount - 1 {
            finishQuiz()
            return
        }

        currentQuestionIndex += 1
        isAnswerRevealed = false
    }

    private func finishQuiz() {
        let correctCount = quiz.questions.reduce(into: 0) { count, question in
            if selectedOptionIDs[question.id] == question.correctOptionID {
                count += 1
            }
        }

        let completedAt = Date()
        let savedProgress: QuizProgress?
        if let practiceProgressRepository {
            savedProgress = try? practiceProgressRepository.saveQuizProgress(
                for: contentID,
                correctCount: correctCount,
                totalQuestionCount: quiz.questionCount,
                completedAt: completedAt
            )
        } else {
            savedProgress = nil
        }

        let progress = savedProgress ?? QuizProgress(
            contentID: contentID,
            bestCorrectCount: correctCount,
            totalQuestionCount: quiz.questionCount,
            lastCompletedAt: completedAt
        )

        completedProgress = progress
        onCompleted(progress)
    }

    private func icon(for option: QuizOption) -> String {
        guard isAnswerRevealed else {
            return selectedOptionID == option.id ? "largecircle.fill.circle" : "circle"
        }
        if option.id == currentQuestion.correctOptionID {
            return "checkmark.circle.fill"
        }
        if selectedOptionID == option.id {
            return "xmark.circle.fill"
        }
        return "circle"
    }

    private func color(for option: QuizOption) -> Color {
        guard isAnswerRevealed else {
            return selectedOptionID == option.id ? .osaPrimary : .secondary
        }
        if option.id == currentQuestion.correctOptionID {
            return .osaLocal
        }
        if selectedOptionID == option.id {
            return .osaEmergency
        }
        return .secondary
    }

    private func background(for option: QuizOption) -> Color {
        guard isAnswerRevealed else {
            return selectedOptionID == option.id ? Color.osaPrimary.opacity(0.1) : .osaSurface
        }
        if option.id == currentQuestion.correctOptionID {
            return Color.osaLocal.opacity(0.12)
        }
        if selectedOptionID == option.id {
            return Color.osaEmergency.opacity(0.1)
        }
        return .osaSurface
    }

    private func border(for option: QuizOption) -> Color {
        guard isAnswerRevealed else {
            return selectedOptionID == option.id ? .osaPrimary.opacity(0.4) : .osaHairline
        }
        if option.id == currentQuestion.correctOptionID {
            return .osaLocal.opacity(0.4)
        }
        if selectedOptionID == option.id {
            return .osaEmergency.opacity(0.4)
        }
        return .osaHairline
    }

    private var answerTitle: String {
        selectedOptionID == currentQuestion.correctOptionID ? "Correct" : "Review This One"
    }

    private var answerIcon: String {
        selectedOptionID == currentQuestion.correctOptionID ? "checkmark.seal.fill" : "exclamationmark.triangle.fill"
    }

    private var answerColor: Color {
        selectedOptionID == currentQuestion.correctOptionID ? .osaLocal : .osaEmergency
    }
}
