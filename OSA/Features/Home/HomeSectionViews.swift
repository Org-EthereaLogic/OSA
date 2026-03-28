import SwiftUI

struct HomeHeaderView: View {
    let connectivity: ConnectivityState
    let onEmergencyModeTapped: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
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

                    let chipLayout = dynamicTypeSize.isAccessibilitySize
                        ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.sm))
                        : AnyLayout(HStackLayout(spacing: Spacing.sm))
                    chipLayout {
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

                    Button(action: onEmergencyModeTapped) {
                        Label("Emergency Mode", systemImage: "exclamationmark.triangle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.osaEmber.opacity(0.18), in: RoundedRectangle(cornerRadius: CornerRadius.md))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens large-target emergency actions and nearby resource shortcuts.")
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
}

struct HomeReadinessSectionView: View {
    let readinessSnapshot: SupplyReadinessSnapshot?

    var body: some View {
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
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(readinessSnapshot.title) readiness")
                .accessibilityValue(
                    "\(readinessSnapshot.readinessPercent) percent. Based on your \(readinessSnapshot.scenario.displayName.lowercased()) profile and current inventory."
                )
            } else {
                HomeSectionEmptyView(message: "Add inventory items to start tracking readiness.")
            }
        }
    }
}

struct HomePinnedContentSectionView: View {
    let state: HomeSectionState<[HomePinnedItem]>

    var body: some View {
        HomeSectionCard(title: "Pinned Content", systemImage: "pin.fill") {
            switch state {
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
                            .hapticTap(.prominentNavigation)
                            .accessibilityHint("Opens pinned quick card details.")
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
                            .hapticTap(.prominentNavigation)
                            .accessibilityHint("Opens pinned handbook section.")
                        }
                    }
                }
            }
        }
    }
}

struct HomeSpotlightSectionView: View {
    @Binding var spotlightMode: SpotlightMode
    let quickCardsState: HomeSectionState<[QuickCard]>
    let feedState: HomeSectionState<[HomeFeedItem]>
    let onFeedRequested: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label("Quick Cards", systemImage: "bolt.fill")
                .font(.sectionHeader)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

            Picker("", selection: $spotlightMode) {
                ForEach(SpotlightMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.icon)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Spotlight content")
            .accessibilityValue(spotlightMode.title)
            .accessibilityHint("Switches between quick cards and the local feed.")

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
        .onChange(of: spotlightMode) { _, newValue in
            if newValue == .feed {
                onFeedRequested()
            }
        }
    }

    @ViewBuilder
    private var quickCardsContent: some View {
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
                    .hapticTap(.prominentNavigation)
                    .accessibilityHint("Opens quick card details.")
                }
            }
        }
    }

    @ViewBuilder
    private var feedContent: some View {
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

struct HomeSuggestionsSectionView: View {
    let state: HomeSectionState<[HomeSuggestion]>

    var body: some View {
        HomeSectionCard(title: "Suggested For You", systemImage: "sparkles") {
            switch state {
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
                            .hapticTap(.prominentNavigation)
                            .accessibilityHint("Opens the suggested quick card.")
                        case .handbookSection(let section):
                            NavigationLink {
                                HandbookSectionDetailView(sectionID: section.id)
                            } label: {
                                HomeSuggestionRow(suggestion: suggestion)
                            }
                            .buttonStyle(.plain)
                            .hapticTap(.prominentNavigation)
                            .accessibilityHint("Opens the suggested handbook section.")
                        }
                    }
                }
            }
        }
    }
}

struct HomeActiveChecklistsSectionView: View {
    let state: HomeSectionState<[ChecklistRun]>

    var body: some View {
        HomeSectionCard(title: "Active Checklists", systemImage: "checklist") {
            switch state {
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
                        .accessibilityHint("Opens the active checklist run.")
                    }
                }
            }
        }
    }
}

struct HomeInventorySectionView: View {
    let state: HomeSectionState<[HomeInventoryReminder]>

    var body: some View {
        HomeSectionCard(title: "Inventory", systemImage: "archivebox.fill") {
            switch state {
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
                        .accessibilityHint("Opens inventory item details.")
                    }
                }
            }
        }
    }
}

struct HomeRecentNotesSectionView: View {
    let state: HomeSectionState<[NoteRecord]>

    var body: some View {
        HomeSectionCard(title: "Recent Notes", systemImage: "note.text") {
            switch state {
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
                        .accessibilityHint("Opens note details.")
                    }
                }
            }
        }
    }
}

struct HomeSectionCard<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Label(title, systemImage: systemImage)
                .font(.sectionHeader)
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)

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

struct HomeHeaderChip: View {
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

struct HomeSectionLoadingView: View {
    let label: String

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ProgressView()
                .tint(.osaPrimary)
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(label)
    }
}

struct HomeSectionEmptyView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

struct HomeSectionFailureView: View {
    let message: String

    var body: some View {
        Label(message, systemImage: "exclamationmark.triangle")
            .font(.subheadline)
            .foregroundStyle(.osaCritical)
    }
}

struct HomeQuickCardRow: View {
    let card: QuickCard

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "bolt.fill")
                .foregroundStyle(.osaEmergency)
                .font(.body)
                .frame(width: 30, height: 30)
                .background(Color.osaPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))
                .accessibilityHidden(true)

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
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Quick card, \(card.title). \(card.summary)")
    }
}

struct HomeChecklistRow: View {
    let run: ChecklistRun

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "checklist")
                .foregroundStyle(.osaCalm)
                .frame(width: 30, height: 30)
                .background(Color.osaCanopy.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))
                .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel(run.title)
        .accessibilityValue("\(run.items.filter(\.isComplete).count) of \(run.items.count) complete. \(Int(run.completionFraction * 100)) percent.")
    }
}

struct HomeInventoryRow: View {
    let reminder: HomeInventoryReminder

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "archivebox.fill")
                .foregroundStyle(.osaTrust)
                .frame(width: 30, height: 30)
                .background(Color.osaPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))
                .accessibilityHidden(true)

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
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(reminder.title). \(reminder.detail)")
    }
}

struct ReadinessBadge: View {
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

struct HomePinnedRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(.osaPrimary)
                .frame(width: 30, height: 30)
                .background(Color.osaPrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))
                .accessibilityHidden(true)

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
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

struct HomeSuggestionRow: View {
    let suggestion: HomeSuggestion

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: icon)
                .foregroundStyle(.osaCalm)
                .frame(width: 30, height: 30)
                .background(Color.osaCanopy.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))
                .accessibilityHidden(true)

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
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(suggestion.title). \(suggestion.subtitle). \(suggestion.reason)")
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

struct HomeNoteRow: View {
    let note: NoteRecord

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: "note.text")
                .foregroundStyle(note.noteType.brandColor)
                .frame(width: 30, height: 30)
                .background(note.noteType.brandColor.opacity(0.14), in: RoundedRectangle(cornerRadius: CornerRadius.sm))
                .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(note.title). \(note.plainText)")
        .accessibilityValue("Updated \(note.updatedAt.formatted(date: .abbreviated, time: .shortened)).")
    }
}

struct HomeFeedArticleRow: View {
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
                    .accessibilityHidden(true)

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
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the article in the browser.")
    }
}
