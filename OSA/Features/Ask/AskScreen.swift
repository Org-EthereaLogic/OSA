import SwiftUI

struct AskScreen: View {
    @Environment(\.retrievalService) private var retrievalService
    @AppStorage(AskScopeSettings.includePersonalNotesKey)
    private var includePersonalNotes = AskScopeSettings.includePersonalNotesDefault

    @State private var query = ""
    @State private var askState: AskViewState = .idle

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    scopeCard

                    switch askState {
                    case .idle:
                        zeroState

                    case .loading:
                        ProgressView("Searching local sources...")
                            .padding(.top, Spacing.xxxl)

                    case .answered(let result):
                        AnswerView(
                            result: result,
                            destinationForCitation: { citation in
                                destination(for: citation)
                            },
                            destinationForAction: { action in
                                destination(for: action)
                            }
                        )

                    case .refused(let reason):
                        RefusalView(reason: reason)
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }

            inputBar
        }
        .background(.osaBackground)
        .navigationTitle("Ask")
        .navigationDestination(for: AskDestination.self) { destination in
            switch destination {
            case .quickCard(let id):
                QuickCardRouteView(cardID: id)
            case .handbookSection(let id):
                HandbookSectionDetailView(sectionID: id)
            }
        }
    }

    private var scopeCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Approved local sources", systemImage: "internaldrive.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(scopeSummary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Toggle(isOn: $includePersonalNotes) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Include personal notes")
                    Text("Persisted locally and applied to retrieval.")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(Spacing.lg)
        .padding(.top, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }

    private var scopeSummary: String {
        if includePersonalNotes {
            return "Searching handbook, quick cards, inventory, checklists, and your notes."
        }

        return "Searching handbook, quick cards, inventory, and checklists only."
    }

    private var zeroState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "bubble.left.and.text.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("Ask a question about your handbook, inventory, or checklists.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Text("Answers stay grounded in approved local content and include citations.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, Spacing.xl)
        .padding(.top, Spacing.xxxl)
    }

    private var inputBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Ask a question...", text: $query)
                .textFieldStyle(.roundedBorder)
                .onSubmit(perform: submitQuery)

            Button(action: submitQuery) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(Spacing.lg)
        .background(.osaSurface)
    }

    private func submitQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        askState = .loading

        guard let service = retrievalService else {
            askState = .refused(.insufficientEvidence)
            return
        }

        let scopes = AskScopeSettings.retrievalScopes(includePersonalNotes: includePersonalNotes)

        Task {
            do {
                let outcome = try await service.retrieve(query: trimmed, scopes: scopes)
                await MainActor.run {
                    switch outcome {
                    case .answered(let result):
                        askState = .answered(result)
                    case .refused(let reason):
                        askState = .refused(reason)
                    }
                }
            } catch {
                await MainActor.run {
                    askState = .refused(.insufficientEvidence)
                }
            }
        }
    }

    private func destination(for citation: CitationReference) -> AskDestination? {
        switch citation.kind {
        case .quickCard:
            return .quickCard(citation.id)
        case .handbookSection:
            return .handbookSection(citation.id)
        case .inventoryItem, .checklistTemplate, .noteRecord:
            return nil
        }
    }

    private func destination(for action: SuggestedAction) -> AskDestination? {
        switch action {
        case .openQuickCard(let id, _):
            return .quickCard(id)
        case .openHandbookSection(let id, _):
            return .handbookSection(id)
        case .searchOnline:
            return nil
        }
    }
}

private enum AskViewState {
    case idle
    case loading
    case answered(AnswerResult)
    case refused(RefusalReason)
}

private enum AskDestination: Hashable {
    case quickCard(UUID)
    case handbookSection(UUID)
}

private struct AnswerView: View {
    let result: AnswerResult
    let destinationForCitation: (CitationReference) -> AskDestination?
    let destinationForAction: (SuggestedAction) -> AskDestination?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
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

            if !result.citations.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Sources")
                        .font(.headline)

                    ForEach(result.citations) { citation in
                        if let destination = destinationForCitation(citation) {
                            NavigationLink(value: destination) {
                                CitationRow(citation: citation)
                            }
                            .buttonStyle(.plain)
                        } else {
                            CitationRow(citation: citation)
                        }
                    }
                }
            }

            if !result.suggestedActions.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Related")
                        .font(.headline)

                    ForEach(Array(result.suggestedActions.enumerated()), id: \.offset) { _, action in
                        SuggestedActionButton(
                            action: action,
                            destination: destinationForAction(action)
                        )
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
}

private struct CitationRow: View {
    let citation: CitationReference

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: iconForKind(citation.kind))
                .foregroundStyle(.accent)

            Text(citation.displayLabel)
                .font(.subheadline)
                .foregroundStyle(.accent)

            Spacer()

            if isNavigable {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var isNavigable: Bool {
        switch citation.kind {
        case .handbookSection, .quickCard:
            return true
        case .inventoryItem, .checklistTemplate, .noteRecord:
            return false
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
        case .emptyQuery:
            "Empty Question"
        case .blockedSensitiveScope:
            "Outside App Scope"
        case .insufficientEvidence:
            "Not Found Locally"
        case .outsideProductScope:
            "Not Supported"
        }
    }

    private var explanation: String {
        switch reason {
        case .emptyQuery:
            "Please enter a question to search your local content."
        case .blockedSensitiveScope(let detail):
            detail
        case .insufficientEvidence:
            "No relevant content was found in your approved local sources. Try rephrasing your question."
        case .outsideProductScope:
            "This question is outside the scope of your preparedness handbook."
        }
    }
}

private struct SuggestedActionButton: View {
    let action: SuggestedAction
    let destination: AskDestination?

    var body: some View {
        if let destination {
            NavigationLink(value: destination) {
                row
            }
            .buttonStyle(.plain)
        } else {
            row
                .foregroundStyle(.secondary)
        }
    }

    private var row: some View {
        HStack {
            Image(systemName: icon)
            Text(label)
                .font(.subheadline)
            Spacer()
            if destination != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private var icon: String {
        switch action {
        case .openQuickCard:
            "bolt.fill"
        case .openHandbookSection:
            "book.closed.fill"
        case .searchOnline:
            "globe"
        }
    }

    private var label: String {
        switch action {
        case .openQuickCard(_, let title):
            "Open Quick Card: \(title)"
        case .openHandbookSection(_, let title):
            "Read: \(title)"
        case .searchOnline(let query):
            "Search online: \(query)"
        }
    }
}

#Preview {
    NavigationStack {
        AskScreen()
    }
}
