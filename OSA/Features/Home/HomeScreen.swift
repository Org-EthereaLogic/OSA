import SwiftUI

struct HomeScreen: View {
    @Environment(\.quickCardRepository) private var quickCardRepository
    @Environment(\.checklistRepository) private var checklistRepository
    @Environment(\.inventoryRepository) private var inventoryRepository
    @Environment(\.noteRepository) private var noteRepository

    @State private var quickCardsState: HomeSectionState<[QuickCard]> = .loading
    @State private var checklistsState: HomeSectionState<[ChecklistRun]> = .loading
    @State private var inventoryState: HomeSectionState<[HomeInventoryReminder]> = .loading
    @State private var notesState: HomeSectionState<[NoteRecord]> = .loading

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                header
                quickCardsSection
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
        .refreshable {
            loadDashboard()
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
                }

                Spacer(minLength: Spacing.md)

                VStack(alignment: .trailing, spacing: Spacing.sm) {
                    ConnectivityBadge(state: .offline)
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

    private var quickCardsSection: some View {
        HomeSectionCard(title: "Quick Cards", systemImage: "bolt.fill") {
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
        loadQuickCards()
        loadActiveChecklists()
        loadInventoryReminders()
        loadRecentNotes()
    }

    private func loadQuickCards() {
        do {
            let cards = Array((try quickCardRepository?.listQuickCards() ?? []).prefix(3))
            quickCardsState = cards.isEmpty ? .empty : .loaded(cards)
        } catch {
            quickCardsState = .failed("Quick cards could not be loaded.")
        }
    }

    private func loadActiveChecklists() {
        do {
            let runs = Array((try checklistRepository?.activeRuns() ?? []).prefix(3))
            checklistsState = runs.isEmpty ? .empty : .loaded(runs)
        } catch {
            checklistsState = .failed("Checklist runs could not be loaded.")
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
}

private enum HomeSectionState<Value> {
    case loading
    case loaded(Value)
    case empty
    case failed(String)
}

private struct HomeInventoryReminder: Identifiable {
    let itemID: UUID
    let title: String
    var detail: String
    var priority: Int

    var id: UUID { itemID }
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

#Preview {
    NavigationStack {
        HomeScreen()
    }
}
