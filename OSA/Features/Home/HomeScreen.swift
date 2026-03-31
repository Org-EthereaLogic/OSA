import SwiftUI

struct HomeScreen: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.handbookRepository) private var handbookRepository
    @Environment(\.quickCardRepository) private var quickCardRepository
    @Environment(\.practiceProgressRepository) private var practiceProgressRepository
    @Environment(\.searchService) private var searchService
    @Environment(\.checklistRepository) private var checklistRepository
    @Environment(\.inventoryRepository) private var inventoryRepository
    @Environment(\.supplyTemplateRepository) private var supplyTemplateRepository
    @Environment(\.noteRepository) private var noteRepository
    @Environment(\.rssDiscoveryService) private var rssDiscoveryService
    @Environment(\.connectivityService) private var connectivityService
    @Environment(\.weatherAlertService) private var weatherAlertService
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @AppStorage(UserProfileSettings.regionKey)
    private var regionRawValue = UserProfileSettings.regionDefault.rawValue
    @AppStorage(UserProfileSettings.householdSizeKey)
    private var householdSize = UserProfileSettings.householdSizeDefault
    @AppStorage(UserProfileSettings.hazardsKey)
    private var hazardsRawValue = UserProfileSettings.encode(hazards: [])
    @AppStorage(PinnedContentSettings.pinnedQuickCardIDsKey)
    private var pinnedQuickCardIDsRawValue = PinnedContentSettings.encode(ids: [])
    @AppStorage(PinnedContentSettings.pinnedSectionIDsKey)
    private var pinnedSectionIDsRawValue = PinnedContentSettings.encode(ids: [])
    @AppStorage(RecentAskHistorySettings.recentQuestionsKey)
    private var recentAskQuestionsRawValue = RecentAskHistorySettings.encode(questions: [])
    @AppStorage(AccessibilitySettings.highContrastModeKey)
    private var highContrastMode = AccessibilitySettings.highContrastModeDefault

    @State private var spotlightMode: SpotlightMode = .quickCards
    @State private var quickCardsState: HomeSectionState<[QuickCard]> = .loading
    @State private var feedState: HomeSectionState<[HomeFeedItem]> = .loading
    @State private var pinnedState: HomeSectionState<[HomePinnedItem]> = .loading
    @State private var weeklyDrillState: HomeSectionState<HomeWeeklyDrillPresentation> = .loading
    @State private var suggestionsState: HomeSectionState<[HomeSuggestion]> = .loading
    @State private var checklistsState: HomeSectionState<[ChecklistRun]> = .loading
    @State private var inventoryState: HomeSectionState<[HomeInventoryReminder]> = .loading
    @State private var notesState: HomeSectionState<[NoteRecord]> = .loading
    @State private var readinessSnapshot: SupplyReadinessSnapshot?
    @State private var showEmergencyMode = false
    @State private var hasLoadedInitially = false
    @State private var connectivityPresenter = ConnectivityNoticePresenter()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HomeHeaderView(connectivity: connectivityPresenter.connectivity, onEmergencyModeTapped: openEmergencyMode)
                if let notice = connectivityPresenter.notice {
                    ConnectivityStatusCallout(notice: notice)
                }
                HomeReadinessSectionView(readinessSnapshot: readinessSnapshot)
                HomeWeeklyDrillSectionView(state: weeklyDrillState)
                HomePinnedContentSectionView(state: pinnedState)
                HomeSpotlightSectionView(
                    spotlightMode: $spotlightMode,
                    quickCardsState: quickCardsState,
                    feedState: feedState,
                    onFeedRequested: requestFeedIfNeeded
                )
                HomeSuggestionsSectionView(state: suggestionsState)
                HomeActiveChecklistsSectionView(state: checklistsState)
                HomeInventorySectionView(state: inventoryState)
                HomeRecentNotesSectionView(state: notesState)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.osaReadableBackground(highContrast: highContrastMode))
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadDashboard)
        .task {
            connectivityPresenter.updateReduceMotion(accessibilityReduceMotion)
            guard let service = connectivityService else { return }
            await connectivityPresenter.observe(service: service) { state, previous in
                Self.homeConnectivityNotice(for: state, previousState: previous)
            }
        }
        .refreshable { await refreshDashboard() }
        .fullScreenCover(isPresented: $showEmergencyMode) {
            EmergencyModeView()
        }
        .onDisappear {
            connectivityPresenter.cancelDismissTask()
        }
    }

    private func loadDashboard() {
        if hasLoadedInitially {
            // On tab re-entry, refresh only sections whose underlying data may
            // have changed (checklists, inventory, notes, readiness). Quick cards
            // keep their stable shuffle to avoid visual churn.
            reloadMutableSections()
        } else {
            hasLoadedInitially = true
            reloadAllSections()
        }
        if spotlightMode == .feed, case .loading = feedState {
            Task { await loadFeed() }
        }
    }

    private func reloadAllSections() {
        loadQuickCards()
        loadWeeklyDrill()
        loadPinnedContent()
        loadContextualSuggestions()
        loadActiveChecklists()
        loadReadinessSnapshot()
        loadInventoryReminders()
        loadRecentNotes()
    }

    /// Refreshes only the sections backed by user-mutable data.
    /// Quick cards and weekly drill keep their stable shuffle.
    private func reloadMutableSections() {
        loadPinnedContent()
        loadActiveChecklists()
        loadReadinessSnapshot()
        loadInventoryReminders()
        loadRecentNotes()
    }

    private func refreshDashboard() async {
        reloadAllSections()
        if spotlightMode == .feed {
            await loadFeed()
        }
    }

    private func openEmergencyMode() {
        hapticFeedbackService?.play(.emergencyEntry)
        showEmergencyMode = true
    }

    private func requestFeedIfNeeded() {
        guard case .loading = feedState else { return }
        Task { await loadFeed() }
    }

    private func loadQuickCards() {
        do {
            let allCards = try quickCardRepository?.listQuickCards() ?? []
            let cards = Array(allCards.shuffled().prefix(3))
            quickCardsState = cards.isEmpty ? .empty : .loaded(cards)
        } catch {
            quickCardsState = .failed("Quick cards could not be loaded.")
        }
    }

    private func loadWeeklyDrill() {
        do {
            let allCards = try quickCardRepository?.listQuickCards() ?? []
            guard let card = PracticeSchedule.currentWeeklyDrill(from: allCards) else {
                weeklyDrillState = .empty
                return
            }

            let weekToken = PracticeSchedule.weekToken()
            let quizProgress: QuizProgress?
            let weeklyCompletion: WeeklyDrillCompletion?
            if let practiceProgressRepository {
                quizProgress = try practiceProgressRepository.quizProgress(for: card.id)
                weeklyCompletion = try practiceProgressRepository.weeklyDrillCompletion(for: weekToken)
            } else {
                quizProgress = nil
                weeklyCompletion = nil
            }
            let currentCompletion = weeklyCompletion?.contentID == card.id ? weeklyCompletion : nil

            weeklyDrillState = .loaded(
                HomeWeeklyDrillPresentation(
                    card: card,
                    weekToken: weekToken,
                    prompt: card.weeklyDrillMetadata?.prompt ?? card.summary,
                    weeklyDrillCompletion: currentCompletion,
                    badges: CompletionBadge.derive(
                        quizProgress: quizProgress,
                        quizDefinition: card.quizDefinition,
                        weeklyDrillCompletion: currentCompletion
                    )
                )
            )
        } catch {
            weeklyDrillState = .failed("Weekly drill could not be loaded.")
        }
    }

    private func loadFeed() async {
        feedState = .loading
        var items: [HomeFeedItem] = []

        // Fetch RSS articles
        if let service = rssDiscoveryService {
            let articles = await service.discoverArticles()
            items.append(contentsOf: articles.map { .article($0) })
        }

        // Fetch weather alerts
        if let alertService = weatherAlertService {
            let alerts = await alertService.fetchAlerts()
            let active = alerts.filter { alert in
                guard let expires = alert.expiresDate else { return true }
                return expires > AppClock.now()
            }
            items.append(contentsOf: active.map { .weatherAlert($0) })
        }

        guard !items.isEmpty else {
            feedState = rssDiscoveryService == nil ? .failed("Feed service unavailable.") : .empty
            return
        }

        // Sort: severe/extreme alerts pinned to top, then by date descending
        let sorted = items.sorted { a, b in
            let aSeverePriority = a.isHighPriority ? 1 : 0
            let bSeverePriority = b.isHighPriority ? 1 : 0
            if aSeverePriority != bSeverePriority { return aSeverePriority > bSeverePriority }
            return a.sortDate > b.sortDate
        }
        feedState = .loaded(Array(sorted.prefix(7)))
    }

    private func loadActiveChecklists() {
        do {
            let runs = Array((try checklistRepository?.activeRuns() ?? []).prefix(3))
            checklistsState = runs.isEmpty ? .empty : .loaded(runs)
        } catch {
            checklistsState = .failed("Checklist runs could not be loaded.")
        }
    }

    private func loadPinnedContent() {
        var items: [HomePinnedItem] = []

        do {
            let quickCardIDs = PinnedContentSettings.ids(from: pinnedQuickCardIDsRawValue)
            let sectionIDs = PinnedContentSettings.ids(from: pinnedSectionIDsRawValue)

            for id in quickCardIDs {
                if let card = try quickCardRepository?.quickCard(id: id) {
                    items.append(.quickCard(card))
                }
            }

            for id in sectionIDs {
                if let section = try handbookRepository?.section(id: id) {
                    items.append(.handbookSection(section))
                }
            }

            pinnedState = items.isEmpty ? .empty : .loaded(items)
        } catch {
            pinnedState = .failed("Pinned content could not be loaded.")
        }
    }

    private func loadContextualSuggestions() {
        let selectedHazards = UserProfileSettings.hazards(from: hazardsRawValue)
        let region = UserProfileSettings.region(from: regionRawValue)
        let targetTags = Set(selectedHazards.map(\.tag) + [region.tag, homeCurrentSeasonTag()])

        var candidates: [HomeSuggestionCandidate] = []

        do {
            let cards = try quickCardRepository?.listQuickCards() ?? []
            let handbookSections = try loadHandbookSections()

            candidates.append(contentsOf: makeTagSuggestionCandidates(
                cards: cards,
                handbookSections: handbookSections,
                targetTags: targetTags
            ))
            candidates.append(contentsOf: try makeRecentAskSuggestionCandidates())
            candidates.append(contentsOf: try makeStudyGuideSuggestionCandidates(region: region))

            let suggestions = mergedSuggestions(from: candidates)

            suggestionsState = suggestions.isEmpty ? .empty : .loaded(suggestions)
        } catch {
            suggestionsState = .failed("Suggestions could not be loaded.")
        }
    }

    private func loadHandbookSections() throws -> [(section: HandbookSection, tags: Set<String>)] {
        let chapterSummaries = try handbookRepository?.listChapters() ?? []
        var sections: [(section: HandbookSection, tags: Set<String>)] = []

        for summary in chapterSummaries {
            guard let chapter = try handbookRepository?.chapter(id: summary.id) else { continue }
            let chapterTags = Set(summary.tags)
            for section in chapter.sections {
                sections.append((section: section, tags: Set(section.tags).union(chapterTags)))
            }
        }

        return sections
    }

    private func makeTagSuggestionCandidates(
        cards: [QuickCard],
        handbookSections: [(section: HandbookSection, tags: Set<String>)],
        targetTags: Set<String>
    ) -> [HomeSuggestionCandidate] {
        guard !targetTags.isEmpty else { return [] }

        var candidates: [HomeSuggestionCandidate] = []

        candidates.append(contentsOf: cards.compactMap { card in
            let matchedTags = targetTags.intersection(Set(card.tags))
            guard !matchedTags.isEmpty else { return nil }

            return HomeSuggestionCandidate(
                suggestion: HomeSuggestion(
                    title: card.title,
                    subtitle: card.summary,
                    reason: "Relevant for \(formatHomeTagText(matchedTags.sorted().first ?? ""))",
                    destination: .quickCard(card)
                ),
                score: matchedTags.count + 2
            )
        })

        candidates.append(contentsOf: handbookSections.compactMap { item in
            let matchedTags = targetTags.intersection(item.tags)
            guard !matchedTags.isEmpty else { return nil }

            return HomeSuggestionCandidate(
                suggestion: HomeSuggestion(
                    title: item.section.heading,
                    subtitle: item.section.plainText,
                    reason: "Relevant for \(formatHomeTagText(matchedTags.sorted().first ?? ""))",
                    destination: .handbookSection(item.section)
                ),
                score: matchedTags.count
            )
        })

        return candidates
    }

    private func makeRecentAskSuggestionCandidates() throws -> [HomeSuggestionCandidate] {
        guard let searchService else { return [] }

        var candidates: [HomeSuggestionCandidate] = []

        for (index, question) in RecentAskHistorySettings.questions(from: recentAskQuestionsRawValue)
            .prefix(3)
            .enumerated()
        {
            guard let normalized = QueryNormalizer.normalize(question) else { continue }

            let searchResults = try searchService.search(
                query: normalized,
                scopes: [.handbookSection, .quickCard],
                limit: 1
            )

            for result in searchResults {
                if let candidate = try makeSearchBackedSuggestionCandidate(
                    from: result,
                    reason: "Recent Ask: \(boundedQuestionLabel(question))",
                    score: max(1, 3 - index)
                ) {
                    candidates.append(candidate)
                }
            }
        }

        return candidates
    }

    private func makeSearchBackedSuggestionCandidate(
        from searchResult: SearchResult,
        reason: String,
        score: Int
    ) throws -> HomeSuggestionCandidate? {
        switch searchResult.kind {
        case .quickCard:
            guard let card = try quickCardRepository?.quickCard(id: searchResult.id) else {
                return nil
            }

            return HomeSuggestionCandidate(
                suggestion: HomeSuggestion(
                    title: card.title,
                    subtitle: card.summary,
                    reason: reason,
                    destination: .quickCard(card)
                ),
                score: score + 1
            )

        case .handbookSection:
            guard let section = try handbookRepository?.section(id: searchResult.id) else {
                return nil
            }

            return HomeSuggestionCandidate(
                suggestion: HomeSuggestion(
                    title: section.heading,
                    subtitle: section.plainText,
                    reason: reason,
                    destination: .handbookSection(section)
                ),
                score: score
            )

        case .fieldReference, .inventoryItem, .checklistTemplate, .noteRecord, .importedKnowledge:
            return nil
        }
    }

    private func makeStudyGuideSuggestionCandidates(
        region: PreparednessRegion
    ) throws -> [HomeSuggestionCandidate] {
        let notes = try noteRepository?.listNotes(type: .localReference) ?? []

        return notes
            .filter { $0.tags.contains("study-guide") }
            .prefix(2)
            .map { note in
                let isRegionSpecific = note.tags.contains(region.tag)
                let reason = isRegionSpecific
                    ? "Saved study guide for \(region.displayName)"
                    : "Saved study guide"

                return HomeSuggestionCandidate(
                    suggestion: HomeSuggestion(
                        title: note.title,
                        subtitle: boundedPreview(note.plainText),
                        reason: reason,
                        destination: .note(note)
                    ),
                    score: isRegionSpecific ? 5 : 4
                )
            }
    }

    private func mergedSuggestions(
        from candidates: [HomeSuggestionCandidate]
    ) -> [HomeSuggestion] {
        var bestByDestination: [String: HomeSuggestionCandidate] = [:]

        for candidate in candidates {
            let key = candidate.suggestion.destination.key
            if let existing = bestByDestination[key] {
                if candidate.score > existing.score {
                    bestByDestination[key] = candidate
                }
            } else {
                bestByDestination[key] = candidate
            }
        }

        return bestByDestination.values
            .sorted {
                if $0.score == $1.score {
                    return $0.suggestion.title.localizedCaseInsensitiveCompare($1.suggestion.title) == .orderedAscending
                }
                return $0.score > $1.score
            }
            .prefix(4)
            .map(\.suggestion)
    }

    private func boundedQuestionLabel(_ question: String, limit: Int = 48) -> String {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private func boundedPreview(_ text: String, limit: Int = 96) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > limit else { return trimmed }
        return String(trimmed.prefix(limit)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private func loadReadinessSnapshot() {
        let selectedHazards = UserProfileSettings.hazards(from: hazardsRawValue)
        let fallbackScenario = selectedHazards.first ?? .powerOutage
        guard let template = supplyTemplateRepository?.template(for: fallbackScenario) else {
            readinessSnapshot = nil
            return
        }

        do {
            let inventory = try inventoryRepository?.listItems(includeArchived: false) ?? []
            readinessSnapshot = evaluateSupplyReadiness(
                template: template,
                inventory: inventory,
                householdSize: householdSize
            )
        } catch {
            readinessSnapshot = nil
        }
    }

    private func loadInventoryReminders() {
        do {
            let expiring = try inventoryRepository?.itemsExpiringSoon(within: 30) ?? []
            let lowStock = try inventoryRepository?.itemsBelowReorderThreshold() ?? []
            let reminders = buildHomeInventoryReminders(expiring: expiring, lowStock: lowStock)
            inventoryState = reminders.isEmpty ? .empty : .loaded(Array(reminders.prefix(3)))
        } catch {
            inventoryState = .failed("Inventory reminders could not be loaded.")
        }
    }

    private func loadRecentNotes() {
        do {
            let notes = try noteRepository?.recentNotes(limit: 3) ?? []
            notesState = notes.isEmpty ? .empty : .loaded(notes)
        } catch {
            notesState = .failed("Recent notes could not be loaded.")
        }
    }

    private static func homeConnectivityNotice(
        for state: ConnectivityState,
        previousState: ConnectivityState?
    ) -> ConnectivityStatusNotice? {
        switch state {
        case .offline:
            return ConnectivityStatusNotice(
                state: state,
                title: "Offline mode active",
                message: "Quick cards, checklists, and notes stay available locally while feed updates pause.",
                autoDismisses: false
            )
        case .onlineConstrained:
            return ConnectivityStatusNotice(
                state: state,
                title: "Connection limited",
                message: "Local content stays ready. Feed and trusted-source refreshes may pause until the signal improves.",
                autoDismisses: false
            )
        case .onlineUsable:
            guard let previousState, previousState != .onlineUsable else { return nil }
            return ConnectivityStatusNotice(
                state: state,
                title: previousState == .syncInProgress ? "Refresh complete" : "Connection restored",
                message: previousState == .syncInProgress
                    ? "Approved-source updates finished. Local content remained available throughout."
                    : "Online enrichment is available again while local content remains ready.",
                autoDismisses: true
            )
        case .syncInProgress:
            return ConnectivityStatusNotice(
                state: state,
                title: "Refreshing approved sources",
                message: "New feed items and trusted-source updates are loading without blocking local tools.",
                autoDismisses: false
            )
        }
    }

}

#Preview {
    NavigationStack {
        HomeScreen()
    }
}
