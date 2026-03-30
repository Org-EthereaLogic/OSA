import Foundation
import XCTest
@testable import OSA

final class OSMTileCacheServiceTests: XCTestCase {
    func testPlanRejectsOversizedRegion() {
        let service = OSMTileCacheService(
            cacheDirectory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
            downloader: StubTileDownloader(),
            regionBudget: TileRegionBudget(maxTilesPerRegion: 5, maxCacheSizeBytes: 1_000_000, estimatedBytesPerTile: 512)
        )

        XCTAssertThrowsError(
            try service.planRegionSave(
                name: "Too Big",
                region: MapRegion(centerLatitude: 45.5, centerLongitude: -122.6, latitudeDelta: 5, longitudeDelta: 5),
                zoomRange: 10...12
            )
        ) { error in
            guard case let TileRegionPlanningError.tileCountExceedsLimit(requested, limit) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertGreaterThan(requested, limit)
            XCTAssertEqual(limit, 5)
        }
    }

    func testSaveListAndDeleteRegion() async throws {
        let cacheDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let service = OSMTileCacheService(
            cacheDirectory: cacheDirectory,
            downloader: StubTileDownloader(),
            regionBudget: TileRegionBudget(maxTilesPerRegion: 100, maxCacheSizeBytes: 5_000_000, estimatedBytesPerTile: 512)
        )

        defer { try? FileManager.default.removeItem(at: cacheDirectory) }

        let plan = try service.planRegionSave(
            name: "Downtown",
            region: MapRegion(centerLatitude: 45.5152, centerLongitude: -122.6784, latitudeDelta: 0.03, longitudeDelta: 0.03),
            zoomRange: 12...12
        )
        let region = try await service.saveRegion(using: plan)

        XCTAssertEqual(service.cachedRegions().count, 1)
        XCTAssertEqual(region.name, "Downtown")
        XCTAssertGreaterThan(service.totalCacheSizeBytes(), 0)

        let sampleTile = try XCTUnwrap(plan.tileCoordinates.first)
        XCTAssertNotNil(service.tileData(x: sampleTile.x, y: sampleTile.y, z: sampleTile.z))

        try service.deleteCachedRegion(id: region.id)
        XCTAssertTrue(service.cachedRegions().isEmpty)
        XCTAssertNil(service.tileData(x: sampleTile.x, y: sampleTile.y, z: sampleTile.z))
    }
}

private struct StubTileDownloader: OSMTileDownloading {
    func data(for url: URL) async throws -> Data {
        Data([0x89, 0x50, 0x4E, 0x47])
    }
}
