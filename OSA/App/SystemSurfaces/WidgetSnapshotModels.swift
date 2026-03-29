import Foundation

struct WidgetSnapshot: Codable, Equatable, Sendable {
    struct ReadinessSummary: Codable, Equatable, Sendable {
        let title: String
        let scenarioTitle: String
        let readinessPercent: Int
        let missingCriticalCount: Int
        let nearExpiryCount: Int
    }

    struct ExpiringItemSummary: Codable, Equatable, Sendable {
        let itemID: UUID
        let name: String
        let categoryTitle: String
        let expiryDate: Date
        let dateSummary: String
    }

    struct TipSummary: Codable, Equatable, Sendable, Identifiable {
        let quickCardID: UUID
        let title: String
        let excerpt: String
        let categoryTitle: String

        var id: UUID { quickCardID }
    }

    struct EmergencyActionSummary: Codable, Equatable, Sendable {
        let title: String
        let subtitle: String
        let destinationURL: URL
    }

    let updatedAt: Date
    let readiness: ReadinessSummary?
    let nextExpiringItem: ExpiringItemSummary?
    let tipCandidates: [TipSummary]
    let emergencyAction: EmergencyActionSummary

    func rotatingTip(
        for date: Date = Date(),
        calendar: Calendar = .current
    ) -> TipSummary? {
        guard !tipCandidates.isEmpty else { return nil }
        let ordinal = calendar.ordinality(of: .day, in: .year, for: date) ?? 0
        let index = abs(ordinal) % tipCandidates.count
        return tipCandidates[index]
    }
}

extension WidgetSnapshot {
    static let empty = WidgetSnapshot(
        updatedAt: Date(timeIntervalSince1970: 0),
        readiness: nil,
        nextExpiringItem: nil,
        tipCandidates: [],
        emergencyAction: .init(
            title: "Emergency Mode",
            subtitle: "Open large-target emergency actions",
            destinationURL: SystemSurfaceDeepLink.emergencyMode.url
        )
    )

    static let placeholder = WidgetSnapshot(
        updatedAt: Date(timeIntervalSince1970: 0),
        readiness: .init(
            title: "Power Outage Kit",
            scenarioTitle: "Power Outage",
            readinessPercent: 78,
            missingCriticalCount: 1,
            nearExpiryCount: 2
        ),
        nextExpiringItem: .init(
            itemID: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa")!,
            name: "Bottled water",
            categoryTitle: "Water",
            expiryDate: Date(timeIntervalSince1970: 86_400 * 30),
            dateSummary: "Expires in 30 days"
        ),
        tipCandidates: [
            .init(
                quickCardID: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb")!,
                title: "Gas Leak Response",
                excerpt: "Leave the building immediately and call for help from outside.",
                categoryTitle: "Emergency"
            )
        ],
        emergencyAction: .init(
            title: "Emergency Mode",
            subtitle: "Open large-target emergency actions",
            destinationURL: SystemSurfaceDeepLink.emergencyMode.url
        )
    )
}
