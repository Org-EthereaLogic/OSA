import SwiftUI

struct AskScreen: View {
    @Environment(\.retrievalService) private var retrievalService
    @State private var query = ""
    @State private var askState: AskViewState = .idle

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Scope label
                    Label("Local sources only", systemImage: "internaldrive.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, Spacing.md)

                    switch askState {
                    case .idle:
                        zeroState

                    case .loading:
                        ProgressView("Searching local sources...")
                            .padding(.top, Spacing.xxxl)

                    case .answered(let result):
                        AnswerView(result: result)

                    case .refused(let reason):
                        RefusalView(reason: reason)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }

            // Input composer
            inputBar
        }
        .navigationTitle("Ask")
    }

    // MARK: - Zero State

    private var zeroState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Ask a question about your handbook, inventory, or notes.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Answers are grounded in approved local content with citations.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xxxl)
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Ask a question...", text: $query)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submitQuery() }
            Button {
                submitQuery()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(Spacing.lg)
        .background(.osaSurface)
    }

    // MARK: - Submit

    private func submitQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        askState = .loading

        guard let service = retrievalService else {
            askState = .refused(.insufficientEvidence)
            return
        }

        Task {
            do {
                let outcome = try await service.retrieve(query: trimmed, scopes: nil)
                switch outcome {
                case .answered(let result):
                    askState = .answered(result)
                case .refused(let reason):
                    askState = .refused(reason)
                }
            } catch {
                askState = .refused(.insufficientEvidence)
            }
        }
    }
}

// MARK: - View State

private enum AskViewState {
    case idle
    case loading
    case answered(AnswerResult)
    case refused(RefusalReason)
}

// MARK: - Answer View

private struct AnswerView: View {
    let result: AnswerResult

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            // Answer text
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: confidenceIcon)
                        .foregroundStyle(confidenceColor)
                    Text(confidenceLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(result.answerText)
                    .font(.body)
                    .textSelection(.enabled)
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))

            // Citations
            if !result.citations.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Sources")
                        .font(.headline)

                    ForEach(result.citations) { citation in
                        Label(citation.displayLabel, systemImage: iconForKind(citation.kind))
                            .font(.subheadline)
                            .foregroundStyle(.accent)
                    }
                }
            }

            // Suggested actions
            if !result.suggestedActions.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Related")
                        .font(.headline)

                    ForEach(Array(result.suggestedActions.enumerated()), id: \.offset) { _, action in
                        SuggestedActionButton(action: action)
                    }
                }
            }
        }
    }

    private var confidenceIcon: String {
        switch result.confidence {
        case .groundedHigh: "checkmark.shield.fill"
        case .groundedMedium: "checkmark.shield"
        case .insufficientLocalEvidence: "exclamationmark.triangle"
        }
    }

    private var confidenceColor: Color {
        switch result.confidence {
        case .groundedHigh: .green
        case .groundedMedium: .orange
        case .insufficientLocalEvidence: .red
        }
    }

    private var confidenceLabel: String {
        switch result.confidence {
        case .groundedHigh: "Multiple approved sources"
        case .groundedMedium: "Limited local evidence"
        case .insufficientLocalEvidence: "Insufficient evidence"
        }
    }

    private func iconForKind(_ kind: SearchResultKind) -> String {
        switch kind {
        case .handbookSection: "book.closed.fill"
        case .quickCard: "bolt.fill"
        case .inventoryItem: "archivebox.fill"
        case .checklistTemplate: "checklist"
        case .noteRecord: "note.text"
        }
    }
}

// MARK: - Refusal View

private struct RefusalView: View {
    let reason: RefusalReason

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.headline)

            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .padding(.top, Spacing.xl)
    }

    private var title: String {
        switch reason {
        case .emptyQuery: "Empty Question"
        case .blockedSensitiveScope: "Outside App Scope"
        case .insufficientEvidence: "Not Found Locally"
        case .outsideProductScope: "Not Supported"
        }
    }

    private var explanation: String {
        switch reason {
        case .emptyQuery:
            "Please enter a question to search your local content."
        case .blockedSensitiveScope(let detail):
            detail
        case .insufficientEvidence:
            "No relevant content was found in your local handbook, inventory, or notes. Try rephrasing your question."
        case .outsideProductScope:
            "This question is outside the scope of your preparedness handbook."
        }
    }
}

// MARK: - Suggested Action Button

private struct SuggestedActionButton: View {
    let action: SuggestedAction

    var body: some View {
        Button {
            // Navigation will be wired through coordinator later
        } label: {
            HStack {
                Image(systemName: icon)
                Text(label)
                    .font(.subheadline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }

    private var icon: String {
        switch action {
        case .openQuickCard: "bolt.fill"
        case .openHandbookSection: "book.closed.fill"
        case .searchOnline: "globe"
        }
    }

    private var label: String {
        switch action {
        case .openQuickCard(_, let title): "Open Quick Card: \(title)"
        case .openHandbookSection(_, let title): "Read: \(title)"
        case .searchOnline(let query): "Search online: \(query)"
        }
    }
}

#Preview {
    NavigationStack {
        AskScreen()
    }
}
