import SwiftData
import XCTest
@testable import OSA

@MainActor
final class WaypointRepositoryTests: XCTestCase {
    func testCreateUpdateAndDeleteWaypoint() throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataWaypointRepository(modelContext: container.mainContext)

        var waypoint = UserWaypoint(
            id: UUID(),
            title: "Creek Access",
            note: "Filtered water nearby",
            latitude: 45.51,
            longitude: -122.67,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            category: .water,
            symbolName: nil
        )

        try repository.createWaypoint(waypoint)
        XCTAssertEqual(try repository.listWaypoints().count, 1)

        waypoint.title = "Updated Creek Access"
        waypoint.note = "Bring extra containers"
        waypoint.category = .regroup
        try repository.updateWaypoint(waypoint)

        let fetched = try XCTUnwrap(repository.waypoint(id: waypoint.id))
        XCTAssertEqual(fetched.title, "Updated Creek Access")
        XCTAssertEqual(fetched.note, "Bring extra containers")
        XCTAssertEqual(fetched.category, .regroup)

        try repository.deleteWaypoint(id: waypoint.id)
        XCTAssertNil(try repository.waypoint(id: waypoint.id))
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([PersistedWaypoint.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
