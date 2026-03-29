import MessageUI
import SwiftUI

struct HomeScreen: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.handbookRepository) private var handbookRepository
    @Environment(\.quickCardRepository) private var quickCardRepository
    @Environment(\.checklistRepository) private var checklistRepository
    @Environment(\.inventoryRepository) private var inventoryRepository
    @Environment(\.supplyTemplateRepository) private var supplyTemplateRepository
    @Environment(\.emergencyContactRepository) private var emergencyContactRepository
    @Environment(\.noteRepository) private var noteRepository
    @Environment(\.rssDiscoveryService) private var rssDiscoveryService
    @Environment(\.connectivityService) private var connectivityService
    @Environment(\.weatherAlertService) private var weatherAlertService
    @Environment(\.locationService) private var locationService
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

    @State private var spotlightMode: SpotlightMode = .quickCards
    @State private var connectivity: ConnectivityState = .offline
    @State private var quickCardsState: HomeSectionState<[QuickCard]> = .loading
    @State private var feedState: HomeSectionState<[HomeFeedItem]> = .loading
    @State private var pinnedState: HomeSectionState<[HomePinnedItem]> = .loading
    @State private var suggestionsState: HomeSectionState<[HomeSuggestion]> = .loading
    @State private var checklistsState: HomeSectionState<[ChecklistRun]> = .loading
    @State private var inventoryState: HomeSectionState<[HomeInventoryReminder]> = .loading
    @State private var notesState: HomeSectionState<[NoteRecord]> = .loading
    @State private var readinessSnapshot: SupplyReadinessSnapshot?
    @State private var emergencyContacts: [EmergencyContact] = []
    @State private var showEmergencyMode = false
    @State private var showSafeMessageComposer = false
    @State private var showSafeMessageAlert = false
    @State private var safeMessageAlertText = ""
    @State private var connectivityNotice: ConnectivityStatusNotice?
    @State private var connectivityNoticeDismissTask: Task<Void, Never>?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                HomeHeaderView(connectivity: connectivity, onEmergencyModeTapped: openEmergencyMode)
                if let connectivityNotice {
                    ConnectivityStatusCallout(notice: connectivityNotice)
                }
                HomeReadinessSectionView(readinessSnapshot: readinessSnapshot)
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
        .background(.osaBackground)
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadDashboard)
        .task { await observeConnectivity() }
        .refreshable { await refreshDashboard() }
        .fullScreenCover(isPresented: $showEmergencyMode) {
            EmergencyModeView(
                safeMessageAvailable: !emergencyContacts.isEmpty,
                onComposeSafeMessage: composeSafeMessage
            )
        }
        .sheet(isPresented: $showSafeMessageComposer) {
            MessageComposeView(
                recipients: emergencyContacts.map(\.phoneNumber),
                body: safeMessageBody
            )
        }
        .alert("I’m Safe Unavailable", isPresented: $showSafeMessageAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(safeMessageAlertText)
        }
        .onDisappear {
            connectivityNoticeDismissTask?.cancel()
        }
    }

    private func loadDashboard() {
        reloadLocalSections()
        if spotlightMode == .feed, case .loading = feedState {
            Task { await loadFeed() }
        }
    }

    private func reloadLocalSections() {
        loadQuickCards()
        loadPinnedContent()
        loadContextualSuggestions()
        loadActiveChecklists()
        loadReadinessSnapshot()
        loadEmergencyContacts()
        loadInventoryReminders()
        loadRecentNotes()
    }

    private func refreshDashboard() async {
        reloadLocalSections()
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
                return expires > Date()
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

        guard !targetTags.isEmpty else {
            suggestionsState = .empty
            return
        }

        var candidates: [HomeSuggestionCandidate] = []

        do {
            let cards = try quickCardRepository?.listQuickCards() ?? []
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

            let chapterSummaries = try handbookRepository?.listChapters() ?? []
            for summary in chapterSummaries {
                guard let chapter = try handbookRepository?.chapter(id: summary.id) else { continue }
                let chapterTags = Set(summary.tags)
                for section in chapter.sections {
                    let matchedTags = targetTags.intersection(Set(section.tags).union(chapterTags))
                    guard !matchedTags.isEmpty else { continue }
                    candidates.append(
                        HomeSuggestionCandidate(
                            suggestion: HomeSuggestion(
                                title: section.heading,
                                subtitle: section.plainText,
                                reason: "Relevant for \(formatHomeTagText(matchedTags.sorted().first ?? ""))",
                                destination: .handbookSection(section)
                            ),
                            score: matchedTags.count
                        )
                    )
                }
            }

            let suggestions = candidates
                .sorted {
                    if $0.score == $1.score {
                        return $0.suggestion.title.localizedCaseInsensitiveCompare($1.suggestion.title) == .orderedAscending
                    }
                    return $0.score > $1.score
                }
                .prefix(4)
                .map(\.suggestion)

            suggestionsState = suggestions.isEmpty ? .empty : .loaded(suggestions)
        } catch {
            suggestionsState = .failed("Suggestions could not be loaded.")
        }
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

    private func loadEmergencyContacts() {
        do {
            emergencyContacts = try emergencyContactRepository?.listContacts() ?? []
        } catch {
            emergencyContacts = []
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

    private func composeSafeMessage() {
        guard !emergencyContacts.isEmpty else {
            hapticFeedbackService?.play(.warning)
            safeMessageAlertText = "Add at least one emergency contact in Settings before using the I’m Safe shortcut."
            showSafeMessageAlert = true
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            hapticFeedbackService?.play(.warning)
            safeMessageAlertText = "Text messaging is not available on this device."
            showSafeMessageAlert = true
            return
        }

        hapticFeedbackService?.play(.emergencyPrimaryAction)
        showEmergencyMode = false
        showSafeMessageComposer = true
    }

    private var safeMessageBody: String {
        var body = "I am safe."

        if let coordinate = locationService?.currentLocation {
            body += " My location is \(String(format: "%.4f", coordinate.latitude)), \(String(format: "%.4f", coordinate.longitude))."
        }

        body += " I will contact you when I can."
        return body
    }

    private func observeConnectivity() async {
        guard let service = connectivityService else { return }
        var previousState: ConnectivityState?
        for await state in service.stateStream() {
            handleConnectivityChange(from: previousState, to: state)
            previousState = state
        }
    }

    private func handleConnectivityChange(from previousState: ConnectivityState?, to newState: ConnectivityState) {
        guard previousState != newState else { return }
        withAnimation(connectivityAnimation) {
            connectivity = newState
        }
        presentConnectivityNotice(homeConnectivityNotice(for: newState, previousState: previousState))
    }

    private func presentConnectivityNotice(_ notice: ConnectivityStatusNotice?) {
        connectivityNoticeDismissTask?.cancel()

        withAnimation(connectivityAnimation) {
            connectivityNotice = notice
        }

        guard let notice, notice.autoDismisses else { return }

        connectivityNoticeDismissTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(4))
            guard !Task.isCancelled, connectivityNotice == notice else { return }
            withAnimation(connectivityAnimation) {
                connectivityNotice = nil
            }
        }
    }

    private func homeConnectivityNotice(
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

    private var connectivityAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.2)
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
}
