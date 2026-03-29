import XCTest
@testable import OSA

final class WidgetSnapshotBuilderTests: XCTestCase {
    func testBuildAssemblesBoundedReadinessExpiryAndTipData() {
        let builder = WidgetSnapshotBuilder(
            now: fixedDate(year: 2026, month: 3, day: 29, hour: 9),
            calendar: utcCalendar()
        )
        let tomorrow = fixedDate(year: 2026, month: 3, day: 30, hour: 10)
        let template = SupplyTemplate(
            id: UUID(),
            title: "72-Hour Kit",
            slug: "72-hour-kit",
            scenario: .powerOutage,
            summary: "Core outage supplies.",
            items: [
                SupplyTemplateItem(
                    id: UUID(),
                    title: "Stored Water",
                    inventoryCategory: .water,
                    targetQuantity: 4,
                    unit: "bottles",
                    matchKeywords: ["water"],
                    isCritical: true,
                    scalesWithHouseholdSize: false
                )
            ]
        )
        let inventory = [
            inventoryItem(
                name: "Stored Water",
                category: .water,
                quantity: 4,
                expiryDate: nil,
                notes: "drinking water"
            ),
            inventoryItem(
                name: "Energy Bar",
                category: .food,
                quantity: 1,
                expiryDate: tomorrow
            )
        ]
        let quickCards = [
            quickCard(
                title: "Boil Water",
                priority: 2,
                summary: String(repeating: "b", count: SystemSurfaceConfiguration.widgetTipExcerptLimit + 20)
            ),
            quickCard(
                title: "Air Quality",
                priority: 2,
                summary: "Seal windows and move clean air supplies near sleeping areas."
            ),
            quickCard(
                title: "Backup Power",
                priority: 1,
                summary: "Stage flashlights and charge packs before conditions worsen."
            )
        ]

        let snapshot = builder.build(
            template: template,
            inventory: inventory,
            householdSize: 1,
            quickCards: quickCards
        )

        XCTAssertEqual(snapshot.readiness?.title, "72-Hour Kit")
        XCTAssertEqual(snapshot.readiness?.scenarioTitle, "Power Outage")
        XCTAssertEqual(snapshot.readiness?.readinessPercent, 100)
        XCTAssertEqual(snapshot.readiness?.missingCriticalCount, 0)
        XCTAssertEqual(snapshot.readiness?.nearExpiryCount, 0)
        XCTAssertEqual(snapshot.nextExpiringItem?.name, "Energy Bar")
        XCTAssertEqual(snapshot.nextExpiringItem?.categoryTitle, "Food")
        XCTAssertEqual(snapshot.nextExpiringItem?.dateSummary, "Expires tomorrow")
        XCTAssertEqual(snapshot.tipCandidates.map(\.title), ["Air Quality", "Boil Water", "Backup Power"])
        XCTAssertEqual(snapshot.tipCandidates.first?.excerpt.hasSuffix("..."), false)
        XCTAssertTrue(snapshot.tipCandidates[1].excerpt.hasSuffix("..."))
        XCTAssertEqual(snapshot.emergencyAction.destinationURL, SystemSurfaceDeepLink.emergencyMode.url)
    }

    func testExpiringSummaryIgnoresArchivedAndOutsideWindow() {
        let builder = WidgetSnapshotBuilder(
            now: fixedDate(year: 2026, month: 3, day: 29, hour: 9),
            calendar: utcCalendar()
        )
        let archivedSoon = inventoryItem(
            name: "Archived Water",
            category: .water,
            quantity: 1,
            expiryDate: fixedDate(year: 2026, month: 3, day: 30, hour: 9),
            isArchived: true
        )
        let outsideWindow = inventoryItem(
            name: "Far Future Meal",
            category: .food,
            quantity: 1,
            expiryDate: fixedDate(year: 2026, month: 5, day: 15, hour: 9)
        )
        let inWindow = inventoryItem(
            name: "First Aid Ointment",
            category: .firstAid,
            quantity: 1,
            expiryDate: fixedDate(year: 2026, month: 4, day: 5, hour: 9)
        )

        let summary = builder.makeExpiringItemSummary(from: [outsideWindow, archivedSoon, inWindow])

        XCTAssertEqual(summary?.name, "First Aid Ointment")
        XCTAssertEqual(summary?.categoryTitle, "First Aid")
        XCTAssertEqual(summary?.dateSummary, "Expires in 7 days")
    }

    func testRotatingTipSelectionIsDeterministicAndReturnsNilWhenEmpty() {
        let snapshot = WidgetSnapshot(
            updatedAt: fixedDate(year: 2026, month: 1, day: 1),
            readiness: nil,
            nextExpiringItem: nil,
            tipCandidates: [
                .init(quickCardID: UUID(), title: "First", excerpt: "A", categoryTitle: "One"),
                .init(quickCardID: UUID(), title: "Second", excerpt: "B", categoryTitle: "Two"),
                .init(quickCardID: UUID(), title: "Third", excerpt: "C", categoryTitle: "Three")
            ],
            emergencyAction: WidgetSnapshot.empty.emergencyAction
        )
        let calendar = utcCalendar()

        XCTAssertEqual(snapshot.rotatingTip(for: fixedDate(year: 2026, month: 1, day: 1), calendar: calendar)?.title, "Second")
        XCTAssertEqual(snapshot.rotatingTip(for: fixedDate(year: 2026, month: 1, day: 2), calendar: calendar)?.title, "Third")
        XCTAssertEqual(snapshot.rotatingTip(for: fixedDate(year: 2026, month: 1, day: 3), calendar: calendar)?.title, "First")
        XCTAssertNil(WidgetSnapshot.empty.rotatingTip(for: fixedDate(year: 2026, month: 1, day: 1), calendar: calendar))
    }
}

private extension WidgetSnapshotBuilderTests {
    func inventoryItem(
        name: String,
        category: InventoryCategory,
        quantity: Int,
        expiryDate: Date?,
        notes: String = "",
        isArchived: Bool = false
    ) -> InventoryItem {
        InventoryItem(
            id: UUID(),
            name: name,
            category: category,
            quantity: quantity,
            unit: "count",
            location: "Closet",
            notes: notes,
            expiryDate: expiryDate,
            reorderThreshold: nil,
            tags: [],
            createdAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 0),
            isArchived: isArchived
        )
    }

    func quickCard(
        title: String,
        priority: Int,
        summary: String
    ) -> QuickCard {
        QuickCard(
            id: UUID(),
            title: title,
            slug: title.lowercased().replacingOccurrences(of: " ", with: "-"),
            category: "emergency",
            summary: summary,
            bodyMarkdown: summary,
            priority: priority,
            relatedSectionIDs: [],
            tags: [],
            lastReviewedAt: nil,
            largeTypeLayoutVersion: 1
        )
    }

    func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func fixedDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int = 0
    ) -> Date {
        let components = DateComponents(
            calendar: utcCalendar(),
            timeZone: TimeZone(secondsFromGMT: 0),
            year: year,
            month: month,
            day: day,
            hour: hour
        )
        return components.date!
    }
}
