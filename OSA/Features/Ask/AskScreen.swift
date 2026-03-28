import SwiftUI

struct AskScreen: View {
    @Environment(\.retrievalService) private var retrievalService
    @Environment(\.connectivityService) private var connectivityService
    @Environment(\.trustedSourceHTTPClient) private var trustedSourceHTTPClient
    @Environment(\.importPipeline) private var importPipeline
    @AppStorage(AskScopeSettings.includePersonalNotesKey)
    private var includePersonalNotes = AskScopeSettings.includePersonalNotesDefault

    @State private var query = ""
    @State private var askState: AskViewState = .idle
    @State private var connectivity: ConnectivityState = .offline
    @State private var showImportSheet = false
    @State private var lastSubmittedQuery = ""

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
                            .tint(.osaPrimary)
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
                        RefusalView(
                            reason: reason,
                            connectivity: connectivity,
                            canImport: trustedSourceHTTPClient != nil && importPipeline != nil,
                            onImportTapped: { showImportSheet = true }
                        )
                    }
                }
                .padding(.horizontal, Spacing.lg)
            }

            inputBar
        }
        .tint(.osaPrimary)
        .background(.osaBackground)
        .navigationTitle("Ask")
        .task { await observeConnectivity() }
        .sheet(isPresented: $showImportSheet, onDismiss: handleImportDismiss) {
            if let client = trustedSourceHTTPClient, let pipeline = importPipeline {
                TrustedSourceImportSheet(
                    viewModel: TrustedSourceImportViewModel(
                        httpClient: client,
                        importPipeline: pipeline,
                        originalQuery: lastSubmittedQuery
                    )
                )
            }
        }
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
            HStack(spacing: Spacing.sm) {
                BrandMarkView(size: 30)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("LOCAL RETRIEVAL")
                        .font(.brandEyebrow)
                        .foregroundStyle(.osaLocal)
                        .tracking(1.1)

                    Text(scopeSummary)
                        .font(.brandSubheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Toggle(isOn: $includePersonalNotes) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Include personal notes")
                    Text("Stored on this device only.")
                        .font(.metadataCaption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(Spacing.lg)
        .padding(.top, Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
    }

    private var scopeSummary: String {
        if includePersonalNotes {
            return "Searching handbook, quick cards, inventory, checklists, and your notes."
        }

        return "Searching handbook, quick cards, inventory, and checklists only."
    }

    private var zeroState: some View {
        VStack(spacing: Spacing.md) {
            BrandMarkView(size: 56)

            Text("Ask Lantern")
                .font(.brandDisplay)
                .multilineTextAlignment(.center)

            Text("Search your local knowledge base")
                .font(.brandSubheadline)
                .multilineTextAlignment(.center)

            Text("Answers are grounded in approved local content with citations. This is not a general chatbot.")
                .font(.metadataCaption)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
        .padding(.top, Spacing.xl)
    }

    private var inputBar: some View {
        HStack(spacing: Spacing.sm) {
            TextField("Ask a question...", text: $query)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + Spacing.xxs)
                .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                .overlay {
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Color.osaHairline, lineWidth: 1)
                }
                .onSubmit(submitQuery)

            Button(action: submitQuery) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .accessibilityLabel("Submit question")
            .foregroundStyle(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.white)
            .frame(width: 42, height: 42)
            .background(
                query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.osaHairline : Color.osaPrimary,
                in: Circle()
            )
            .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(Spacing.lg)
        .background(.osaSurface)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(.osaHairline)
                .frame(height: 1)
        }
    }

    private func observeConnectivity() async {
        guard let service = connectivityService else { return }
        connectivity = service.currentState
        for await state in service.stateStream() {
            connectivity = state
        }
    }

    private func handleImportDismiss() {
        guard !lastSubmittedQuery.isEmpty else { return }
        query = lastSubmittedQuery
        submitQuery()
    }

    private func submitQuery() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        lastSubmittedQuery = trimmed
        askState = .loading

        guard let service = retrievalService else {
            askState = .refused(.insufficientEvidence)
            return
        }

        let scopes = AskScopeSettings.retrievalScopes(includePersonalNotes: includePersonalNotes)
        nonisolated(unsafe) let sendableService = service

        Task {
            do {
                let outcome = try await sendableService.retrieve(query: trimmed, scopes: scopes)
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
        case .inventoryItem, .checklistTemplate, .noteRecord, .importedKnowledge:
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
                        .font(.metadataCaption)
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(confidenceColor.opacity(0.12), in: Capsule())

                Text(result.answerText)
                    .font(.cardBody)
                    .textSelection(.enabled)
            }
            .padding(Spacing.lg)
            .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.osaHairline, lineWidth: 1)
            }

            if !result.citations.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Sources")
                        .font(.sectionHeader)

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
                        .font(.sectionHeader)

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
        case .groundedHigh: .osaLocal
        case .groundedMedium: .osaWarning
        case .insufficientLocalEvidence: .osaCritical
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
                .foregroundStyle(.tint)

            Text(citation.displayLabel)
                .font(.subheadline)
                .foregroundStyle(.tint)

            Spacer()

            if isNavigable {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
    }

    private var isNavigable: Bool {
        switch citation.kind {
        case .handbookSection, .quickCard:
            return true
        case .inventoryItem, .checklistTemplate, .noteRecord, .importedKnowledge:
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
        case .importedKnowledge: "globe"
        }
    }
}

private struct RefusalView: View {
    let reason: RefusalReason
    let connectivity: ConnectivityState
    let canImport: Bool
    let onImportTapped: () -> Void

    private var showOnlineOffer: Bool {
        reason == .insufficientEvidence && connectivity == .onlineUsable && canImport
    }

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.bubble.fill")
                .font(.system(size: 40))
                .foregroundStyle(.osaCritical)

            Text(title)
                .font(.cardTitle)

            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if showOnlineOffer {
                onlineOfferCard
            } else if reason == .insufficientEvidence && connectivity != .onlineUsable {
                offlineHint
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
        .padding(.top, Spacing.md)
    }

    private var onlineOfferCard: some View {
        VStack(spacing: Spacing.sm) {
            Button(action: onImportTapped) {
                Label("Import from Trusted Source", systemImage: "globe")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Text("Browse approved publishers and import a page for offline use. This does not give the assistant web access.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.md)
        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .padding(.top, Spacing.sm)
    }

    private var offlineHint: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: connectivity.icon)
                .font(.caption)
            Text("Trusted source import available when online.")
                .font(.caption)
        }
        .foregroundStyle(.tertiary)
        .padding(.top, Spacing.sm)
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
                .foregroundStyle(.osaPrimary)
            Text(label)
                .font(.subheadline)
            Spacer()
            if destination != nil {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(Color.osaHairline, lineWidth: 1)
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
