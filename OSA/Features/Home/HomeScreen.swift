import MessageUI
import SwiftUI

struct HomeScreen: View {
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                readinessSection
                pinnedContentSection
                spotlightSection
                contextualSuggestionsSection
                activeChecklistsSection
                inventorySection
                recentNotesSection
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            HStack(alignment: .top, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("OFFLINE-FIRST PREPAREDNESS")
                        .font(.brandEyebrow)
                        .foregroundStyle(Color.white.opacity(0.72))
                        .tracking(1.2)

                    BrandWordmarkView(variant: .reversed, height: 34)

                    Text(AppBrand.reassurance)
                        .font(.brandSubheadline)
                        .foregroundStyle(Color.white.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.sm) {
                        HomeHeaderChip(
                            title: "Stored locally",
                            systemImage: "internaldrive.fill",
                            tint: .osaLocal
                        )
                        HomeHeaderChip(
                            title: "Cited answers",
                            systemImage: "checkmark.shield.fill",
                            tint: .osaTrust
                        )
                    }

                    Button {
                        showEmergencyMode = true
                    } label: {
                        Label("Emergency Mode", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.osaEmber.opacity(0.18), in: RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
                    .buttonStyle(.plain)
                }

                Spacer(minLength: Spacing.md)

                VStack(alignment: .trailing, spacing: Spacing.sm) {
                    ConnectivityBadge(state: connectivity)
                    BrandMarkView(size: 68)
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
        .shadow(color: Color.osaNight.opacity(0.16), radius: 20, y: 10)
    }

    private var readinessSection: some View {
        HomeSectionCard(title: "Readiness", systemImage: "gauge.with.dots.needle.50percent") {
            if let readinessSnapshot {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(readinessSnapshot.title)
                                .font(.cardTitle)
                            Text("Based on your \(readinessSnapshot.scenario.displayName.lowercased()) profile and current inventory.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("\(readinessSnapshot.readinessPercent)%")
                            .font(.stressTitle)
                            .foregroundStyle(readinessSnapshot.readinessPercent >= 75 ? .osaLocal : .osaWarning)
                    }

                    HStack(spacing: Spacing.md) {
                        ReadinessBadge(
                            title: "Missing Critical",
                            value: "\(readinessSnapshot.missingCriticalCount)",
                            tint: readinessSnapshot.missingCriticalCount == 0 ? .osaLocal : .osaCritical
                        )
                        ReadinessBadge(
                            title: "Near Expiry",
                            value: "\(readinessSnapshot.nearExpiryCount)",
                            tint: readinessSnapshot.nearExpiryCount == 0 ? .osaTrust : .osaWarning
                        )
                    }
                }
            } else {
                HomeSectionEmptyView(message: "Add inventory items to start tracking readiness.")
            }
        }
    }

    private var pinnedContentSection: some View {
        HomeSectionCard(title: "Pinned Content", systemImage: "pin.fill") {
            switch pinnedState {
            case .loading:
                HomeSectionLoadingView(label: "Loading pinned items...")
            case .empty:
                HomeSectionEmptyView(message: "Pin quick cards or handbook sections for one-tap access.")
            case .failed(let message):
                HomeSectionFailureView(message: message)
            case .loaded(let items):
                VStack(spacing: Spacing.sm) {
                    ForEach(items) { item in
                        switch item {
                        case .quickCard(let card):
                            NavigationLink {
                                QuickCardDetailView(card: card)
                            } label: {
                                HomePinnedRow(
                                    icon: "bolt.fill",
                                    title: card.title,
                                    subtitle: card.summary
                                )
                            }
                            .buttonStyle(.plain)
                        case .handbookSection(let section):
                            NavigationLink {
                                HandbookSectionDetailView(sectionID: section.id)
                            } label: {
                                HomePinnedRow(
                                    icon: "book.closed.fill",
                                    title: section.heading,
                                    subtitle: section.plainText
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var spotlightSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Quick Cards", systemImage: "bolt.fill")
                .font(.sectionHeader)
                .foregroundStyle(.primary)

            Picker("", selection: $spotlightMode) {
                ForEach(SpotlightMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            switch spotlightMode {
            case .quickCards:
                quickCardsContent
            case .feed:
                feedContent
            }
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
        .onChange(of: spotlightMode) {
            if spotlightMode == .feed, case .loading = feedState {
                Task { await loadFeed() }
            }
        }
    }

    private var quickCardsContent: some View {
        Group {
            switch quickCardsState {
            case .loading:
                HomeSectionLoadingView(label: "Loading quick cards...")
            case .empty:
                HomeSectionEmptyView(message: "No quick cards available yet.")
            case .failed(let message):
                HomeSectionFailureView(message: message)
            case .loaded(let cards):
                VStack(spacing: Spacing.sm) {
                    ForEach(cards) { card in
                        NavigationLink {
                            QuickCardDetailView(card: card)
                        } label: {
                            HomeQuickCardRow(card: card)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var feedContent: some View {
        Group {
            switch feedState {
            case .loading:
                HomeSectionLoadingView(label: "Fetching latest articles...")
            case .empty:
                HomeSectionEmptyView(message: "No articles available. Connect to the internet to fetch feeds.")
            case .failed(let message):
                HomeSectionFailureView(message: message)
            case .loaded(let items):
                VStack(spacing: Spacing.sm) {
                    ForEach(items) { item in
                        switch item {
                        case .article(let article):
                            HomeFeedArticleRow(article: article)
                        case .weatherAlert(let alert):
                            WeatherAlertRow(alert: alert)
                        }
                    }
                }
            }
        }
    }

    private var activeChecklistsSection: some View {
        HomeSectionCard(title: "Active Checklists", systemImage: "checklist") {
            switch checklistsState {
            case .loading:
                HomeSectionLoadingView(label: "Loading active runs...")

            case .empty:
                HomeSectionEmptyView(message: "No checklist runs are currently in progress.")

            case .failed(let message):
                HomeSectionFailureView(message: message)

            case .loaded(let runs):
                VStack(spacing: Spacing.sm) {
                    ForEach(runs) { run in
                        NavigationLink {
                            ChecklistRunView(runID: run.id)
                        } label: {
                            HomeChecklistRow(run: run)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var contextualSuggestionsSection: some View {
        HomeSectionCard(title: "Suggested For You", systemImage: "sparkles") {
            switch suggestionsState {
            case .loading:
                HomeSectionLoadingView(label: "Finding relevant content...")
            case .empty:
                HomeSectionEmptyView(message: "Finish onboarding or pin a hazard profile to see contextual suggestions.")
            case .failed(let message):
                HomeSectionFailureView(message: message)
            case .loaded(let suggestions):
                VStack(spacing: Spacing.sm) {
                    ForEach(suggestions) { suggestion in
                        switch suggestion.destination {
                        case .quickCard(let card):
                            NavigationLink {
                                QuickCardDetailView(card: card)
                            } label: {
                                HomeSuggestionRow(suggestion: suggestion)
                            }
                            .buttonStyle(.plain)
                        case .handbookSection(let section):
                            NavigationLink {
                                HandbookSectionDetailView(sectionID: section.id)
                            } label: {
                                HomeSuggestionRow(suggestion: suggestion)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private var inventorySection: some View {
        HomeSectionCard(title: "Inventory", systemImage: "archivebox.fill") {
            switch inventoryState {
            case .loading:
                HomeSectionLoadingView(label: "Loading reminders...")

            case .empty:
                HomeSectionEmptyView(message: "No low-stock or expiring items need attention.")

            case .failed(let message):
                HomeSectionFailureView(message: message)

            case .loaded(let reminders):
                VStack(spacing: Spacing.sm) {
                    ForEach(reminders) { reminder in
                        NavigationLink {
                            InventoryItemDetailView(itemID: reminder.itemID)
                        } label: {
                            HomeInventoryRow(reminder: reminder)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var recentNotesSection: some View {
        HomeSectionCard(title: "Recent Notes", systemImage: "note.text") {
            switch notesState {
            case .loading:
                HomeSectionLoadingView(label: "Loading recent notes...")

            case .empty:
                HomeSectionEmptyView(message: "No notes yet. Add one from the Notes tab.")

            case .failed(let message):
                HomeSectionFailureView(message: message)

            case .loaded(let notes):
                VStack(spacing: Spacing.sm) {
                    ForEach(notes) { note in
                        NavigationLink {
                            NoteDetailView(noteID: note.id)
                        } label: {
                            HomeNoteRow(note: note)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
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
        let targetTags = Set(selectedHazards.map(\.tag) + [region.tag, currentSeasonTag])

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
                        reason: "Relevant for \(formatTagText(matchedTags.sorted().first ?? ""))",
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
                                reason: "Relevant for \(formatTagText(matchedTags.sorted().first ?? ""))",
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
            readinessSnapshot = evaluateReadiness(template: template, inventory: inventory)
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
            let reminders = buildInventoryReminders(expiring: expiring, lowStock: lowStock)
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
            safeMessageAlertText = "Add at least one emergency contact in Settings before using the I’m Safe shortcut."
            showSafeMessageAlert = true
            return
        }

        guard MFMessageComposeViewController.canSendText() else {
            safeMessageAlertText = "Text messaging is not available on this device."
            showSafeMessageAlert = true
            return
        }

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
        connectivity = service.currentState
        for await state in service.stateStream() {
            connectivity = state
        }
    }

    private func buildInventoryReminders(
        expiring: [InventoryItem],
        lowStock: [InventoryItem]
    ) -> [HomeInventoryReminder] {
        let now = Date()
        var reminders: [UUID: HomeInventoryReminder] = [:]

        for item in expiring {
            guard let expiryDate = item.expiryDate else { continue }
            let detail = expiryDate < now
                ? "Expired \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
                : "Expires \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
            let priority = expiryDate < now ? 0 : 1

            reminders[item.id] = HomeInventoryReminder(
                itemID: item.id,
                title: item.name,
                detail: detail,
                priority: priority
            )
        }

        for item in lowStock {
            let detail: String
            if let threshold = item.reorderThreshold {
                detail = "Low stock: \(item.quantity) \(item.unit) left, reorder at \(threshold)"
            } else {
                detail = "Low stock: \(item.quantity) \(item.unit) left"
            }

            if var existing = reminders[item.id] {
                existing.detail += " | \(detail)"
                existing.priority = min(existing.priority, 2)
                reminders[item.id] = existing
            } else {
                reminders[item.id] = HomeInventoryReminder(
                    itemID: item.id,
                    title: item.name,
                    detail: detail,
                    priority: 2
                )
            }
        }

        return reminders.values.sorted { lhs, rhs in
            if lhs.priority == rhs.priority {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            return lhs.priority < rhs.priority
        }
    }

    private func evaluateReadiness(
        template: SupplyTemplate,
        inventory: [InventoryItem]
    ) -> SupplyReadinessSnapshot {
        var completedScore = 0.0
        var missingCriticalCount = 0
        var nearExpiryCount = 0

        for templateItem in template.items {
            let targetQuantity = templateItem.targetQuantity * (templateItem.scalesWithHouseholdSize ? householdSize : 1)
            let matches = inventory.filter { item in
                guard item.category == templateItem.inventoryCategory else { return false }
                let searchableText = "\(item.name) \(item.notes) \(item.location)".lowercased()
                return templateItem.matchKeywords.isEmpty
                    || templateItem.matchKeywords.contains { searchableText.contains($0.lowercased()) }
            }

            let matchedQuantity = matches.reduce(0) { $0 + $1.quantity }
            completedScore += min(Double(matchedQuantity) / Double(max(targetQuantity, 1)), 1.0)

            if templateItem.isCritical && matchedQuantity < targetQuantity {
                missingCriticalCount += 1
            }

            nearExpiryCount += matches.filter {
                guard let expiryDate = $0.expiryDate else { return false }
                return expiryDate <= Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? .distantFuture
            }.count
        }

        let readinessPercent = Int((completedScore / Double(max(template.items.count, 1))) * 100.0)
        return SupplyReadinessSnapshot(
            title: template.title,
            scenario: template.scenario,
            readinessPercent: readinessPercent,
            missingCriticalCount: missingCriticalCount,
            nearExpiryCount: nearExpiryCount
        )
    }

    private var currentSeasonTag: String {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5:
            return "season:spring"
        case 6...8:
            return "season:summer"
        case 9...11:
            return "season:fall"
        default:
            return "season:winter"
        }
    }
}

private enum SpotlightMode: String, CaseIterable, Identifiable {
    case quickCards
    case feed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickCards: "Quick Cards"
        case .feed: "Feed"
        }
    }

    var icon: String {
        switch self {
        case .quickCards: "bolt.fill"
        case .feed: "antenna.radiowaves.left.and.right"
        }
    }
}

// HomeSectionState is defined in OSA/Shared/Support/HomeSectionState.swift

/// Unified feed item that merges RSS articles and weather alerts for the Home feed.
enum HomeFeedItem: Identifiable {
    case article(DiscoveredArticle)
    case weatherAlert(WeatherAlert)

    var id: String {
        switch self {
        case .article(let a): "article-\(a.articleURL.absoluteString)"
        case .weatherAlert(let a): "alert-\(a.id.uuidString)"
        }
    }

    var sortDate: Date {
        switch self {
        case .article(let a): a.publishedDate ?? .distantPast
        case .weatherAlert(let a): a.effectiveDate ?? a.fetchedAt
        }
    }

    var isHighPriority: Bool {
        switch self {
        case .article: false
        case .weatherAlert(let a): a.severity == .extreme || a.severity == .severe
        }
    }
}

private struct HomeInventoryReminder: Identifiable {
    let itemID: UUID
    let title: String
    var detail: String
    var priority: Int

    var id: UUID { itemID }
}

private enum HomePinnedItem: Identifiable {
    case quickCard(QuickCard)
    case handbookSection(HandbookSection)

    var id: String {
        switch self {
        case .quickCard(let card):
            "card-\(card.id.uuidString)"
        case .handbookSection(let section):
            "section-\(section.id.uuidString)"
        }
    }
}

private enum HomeSuggestionDestination {
    case quickCard(QuickCard)
    case handbookSection(HandbookSection)
}

private struct HomeSuggestion: Identifiable {
    let title: String
    let subtitle: String
    let reason: String
    let destination: HomeSuggestionDestination

    var id: String { title + reason }
}

private struct HomeSuggestionCandidate {
    let suggestion: HomeSuggestion
    let score: Int
}

private struct HomeSectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label(title, systemImage: systemImage)
                .font(.sectionHeader)
                .foregroundStyle(.primary)

            content()
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
    }
}

private struct HomeHeaderChip: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.metadataCaption)
            .foregroundStyle(.osaPaperGlow)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(tint.opacity(0.18), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(0.35), lineWidth: 1)
            }
    }
}

private struct HomeSectionLoadingView: View {
    let label: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(.osaPrimary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct HomeSectionEmptyView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

private struct HomeSectionFailureView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.subheadline)
            .foregroundStyle(.osaCritical)
    }
}

private struct HomeQuickCardRow: View {
    let card: QuickCard

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.osaEmergency)
                .font(.body)
                .frame(width: 30, height: 30)
                .background(Color.osaPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(card.title)
                    .font(.cardTitle)
                    .foregroundStyle(.primary)

                Text(card.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct HomeChecklistRow: View {
    let run: ChecklistRun

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "checklist")
                .foregroundStyle(.osaCalm)
                .frame(width: 30, height: 30)
                .background(Color.osaCanopy.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(run.title)
                    .font(.cardTitle)
                    .foregroundStyle(.primary)

                Text("\(run.items.filter(\.isComplete).count) of \(run.items.count) complete")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            Text("\(Int(run.completionFraction * 100))%")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct HomeInventoryRow: View {
    let reminder: HomeInventoryReminder

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "archivebox.fill")
                .foregroundStyle(.osaTrust)
                .frame(width: 30, height: 30)
                .background(Color.osaPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(reminder.title)
                    .font(.cardTitle)
                    .foregroundStyle(.primary)

                Text(reminder.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct ReadinessBadge: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

private struct HomePinnedRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(.osaPrimary)
                .frame(width: 30, height: 30)
                .background(Color.osaPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(title)
                    .font(.cardTitle)
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
}

private struct HomeSuggestionRow: View {
    let suggestion: HomeSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(.osaCalm)
                .frame(width: 30, height: 30)
                .background(Color.osaCanopy.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(suggestion.title)
                    .font(.cardTitle)
                    .foregroundStyle(.primary)
                Text(suggestion.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Text(suggestion.reason)
                    .font(.caption)
                    .foregroundStyle(.osaPrimary)
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }

    private var icon: String {
        switch suggestion.destination {
        case .quickCard:
            "bolt.fill"
        case .handbookSection:
            "book.closed.fill"
        }
    }
}

private struct HomeNoteRow: View {
    let note: NoteRecord

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "note.text")
                .foregroundStyle(note.noteType.brandColor)
                .frame(width: 30, height: 30)
                .background(note.noteType.brandColor.opacity(0.14), in: RoundedRectangle(cornerRadius: CornerRadius.sm))

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(note.title)
                    .font(.cardTitle)
                    .foregroundStyle(.primary)

                Text(note.plainText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer(minLength: 0)

            Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct HomeFeedArticleRow: View {
    let article: DiscoveredArticle
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button {
            openURL(article.articleURL)
        } label: {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundStyle(.osaCalm)
                    .font(.body)
                    .frame(width: 30, height: 30)
                    .background(Color.osaCanopy.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(article.title)
                        .font(.cardTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    HStack(spacing: Spacing.xs) {
                        Text(article.sourceHost)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        if let date = article.publishedDate {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text(date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Text("Read more")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.osaPrimary)
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
    }
}

private func formatTagText(_ rawTag: String) -> String {
    rawTag
        .replacingOccurrences(of: "scenario:", with: "")
        .replacingOccurrences(of: "season:", with: "")
        .replacingOccurrences(of: "region:", with: "")
        .replacingOccurrences(of: "-", with: " ")
        .split(separator: " ")
        .map { $0.capitalized }
        .joined(separator: " ")
}
