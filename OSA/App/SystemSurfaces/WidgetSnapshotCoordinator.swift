import Foundation
#if canImport(WidgetKit)
import WidgetKit
#endif

protocol WidgetSnapshotRefreshing: AnyObject, Sendable {
    func refreshSnapshot() async
}

protocol WidgetTimelineReloading: Sendable {
    func reloadAllTimelines()
}

struct LiveWidgetTimelineReloader: WidgetTimelineReloading {
    func reloadAllTimelines() {
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

struct WidgetSnapshotBuilder {
    let calendar: Calendar
    let now: Date

    init(
        now: Date = Date(),
        calendar: Calendar = .current
    ) {
        self.now = now
        self.calendar = calendar
    }

    func build(
        template: SupplyTemplate?,
        inventory: [InventoryItem],
        householdSize: Int,
        quickCards: [QuickCard]
    ) -> WidgetSnapshot {
        WidgetSnapshot(
            updatedAt: now,
            readiness: makeReadinessSummary(
                template: template,
                inventory: inventory,
                householdSize: householdSize
            ),
            nextExpiringItem: makeExpiringItemSummary(from: inventory),
            tipCandidates: makeTipCandidates(from: quickCards),
            emergencyAction: WidgetSnapshot.EmergencyActionSummary(
                title: "Emergency Mode",
                subtitle: "Open large-target emergency actions",
                destinationURL: SystemSurfaceDeepLink.emergencyMode.url
            )
        )
    }

    func makeReadinessSummary(
        template: SupplyTemplate?,
        inventory: [InventoryItem],
        householdSize: Int
    ) -> WidgetSnapshot.ReadinessSummary? {
        guard let template else { return nil }

        let snapshot = evaluateSupplyReadiness(
            template: template,
            inventory: inventory,
            householdSize: householdSize
        )

        return WidgetSnapshot.ReadinessSummary(
            title: snapshot.title,
            scenarioTitle: snapshot.scenario.displayName,
            readinessPercent: snapshot.readinessPercent,
            missingCriticalCount: snapshot.missingCriticalCount,
            nearExpiryCount: snapshot.nearExpiryCount
        )
    }

    func makeExpiringItemSummary(from inventory: [InventoryItem]) -> WidgetSnapshot.ExpiringItemSummary? {
        let candidate = inventory
            .filter { !$0.isArchived }
            .filter { item in
                guard let expiryDate = item.expiryDate else { return false }
                let cutoff = calendar.date(byAdding: .day, value: SystemSurfaceConfiguration.widgetExpiryWindowDays, to: now) ?? .distantFuture
                return expiryDate <= cutoff
            }
            .sorted { lhs, rhs in
                switch (lhs.expiryDate, rhs.expiryDate) {
                case let (left?, right?) where left != right:
                    return left < right
                default:
                    return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
                }
            }
            .first

        guard let candidate, let expiryDate = candidate.expiryDate else {
            return nil
        }

        return WidgetSnapshot.ExpiringItemSummary(
            itemID: candidate.id,
            name: candidate.name,
            categoryTitle: inventoryCategoryDisplayName(candidate.category),
            expiryDate: expiryDate,
            dateSummary: expirySummary(for: expiryDate)
        )
    }

    func makeTipCandidates(from quickCards: [QuickCard]) -> [WidgetSnapshot.TipSummary] {
        quickCards
            .sorted {
                if $0.priority == $1.priority {
                    return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
                }
                return $0.priority > $1.priority
            }
            .prefix(SystemSurfaceConfiguration.widgetTipCandidateLimit)
            .map { card in
                WidgetSnapshot.TipSummary(
                    quickCardID: card.id,
                    title: card.title,
                    excerpt: boundedTipExcerpt(card.summary),
                    categoryTitle: card.category.capitalized.replacingOccurrences(of: "-", with: " ")
                )
            }
    }

    private func boundedTipExcerpt(_ summary: String) -> String {
        let trimmed = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > SystemSurfaceConfiguration.widgetTipExcerptLimit else {
            return trimmed
        }
        return String(trimmed.prefix(SystemSurfaceConfiguration.widgetTipExcerptLimit)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }

    private func expirySummary(for expiryDate: Date) -> String {
        let startOfNow = calendar.startOfDay(for: now)
        let startOfExpiry = calendar.startOfDay(for: expiryDate)
        let dayDelta = calendar.dateComponents([.day], from: startOfNow, to: startOfExpiry).day ?? 0

        switch dayDelta {
        case Int.min ..< 0:
            return "Expired \(expiryDate.formatted(date: .abbreviated, time: .omitted))"
        case 0:
            return "Expires today"
        case 1:
            return "Expires tomorrow"
        default:
            return "Expires in \(dayDelta) days"
        }
    }

    private func inventoryCategoryDisplayName(_ category: InventoryCategory) -> String {
        category.rawValue
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}

@MainActor
final class WidgetSnapshotCoordinator: WidgetSnapshotRefreshing, Sendable {
    private let quickCardRepository: any QuickCardRepository
    private let inventoryRepository: any InventoryRepository
    private let supplyTemplateRepository: any SupplyTemplateRepository
    private let userDefaults: UserDefaults
    private let store: WidgetSnapshotStore?
    private let timelineReloader: any WidgetTimelineReloading
    private let calendar: Calendar
    private let nowProvider: @Sendable () -> Date

    init(
        quickCardRepository: any QuickCardRepository,
        inventoryRepository: any InventoryRepository,
        supplyTemplateRepository: any SupplyTemplateRepository,
        userDefaults: UserDefaults = .standard,
        store: WidgetSnapshotStore? = WidgetSnapshotStore(),
        timelineReloader: any WidgetTimelineReloading = LiveWidgetTimelineReloader(),
        calendar: Calendar = .current,
        nowProvider: @escaping @Sendable () -> Date = Date.init
    ) {
        self.quickCardRepository = quickCardRepository
        self.inventoryRepository = inventoryRepository
        self.supplyTemplateRepository = supplyTemplateRepository
        self.userDefaults = userDefaults
        self.store = store
        self.timelineReloader = timelineReloader
        self.calendar = calendar
        self.nowProvider = nowProvider
    }

    func refreshSnapshot() async {
        guard let store else { return }

        do {
            let selectedHazards = UserProfileSettings.hazards(
                from: userDefaults.string(forKey: UserProfileSettings.hazardsKey) ?? UserProfileSettings.encode(hazards: [])
            )
            let scenario = selectedHazards.first ?? .powerOutage
            let template = supplyTemplateRepository.template(for: scenario)
            let inventory = try inventoryRepository.listItems(includeArchived: false)
            let quickCards = try quickCardRepository.listQuickCards()
            let householdSize = userDefaults.object(forKey: UserProfileSettings.householdSizeKey) as? Int
                ?? UserProfileSettings.householdSizeDefault

            let snapshot = WidgetSnapshotBuilder(
                now: nowProvider(),
                calendar: calendar
            )
            .build(
                template: template,
                inventory: inventory,
                householdSize: householdSize,
                quickCards: quickCards
            )

            try store.save(snapshot)
            timelineReloader.reloadAllTimelines()
        } catch {
            // Keep the last successful snapshot rather than replacing it with a failed state.
        }
    }
}
