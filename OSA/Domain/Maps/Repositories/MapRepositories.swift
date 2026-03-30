import Foundation
import CoreLocation

protocol MapAnnotationProvider: Sendable {
    func annotations(near coordinate: CLLocationCoordinate2D, radiusKm: Double) -> [MapAnnotationItem]
    func allAnnotations() -> [MapAnnotationItem]
}

protocol WaypointRepository {
    func listWaypoints() throws -> [UserWaypoint]
    func waypoint(id: UUID) throws -> UserWaypoint?
    func createWaypoint(_ waypoint: UserWaypoint) throws
    func updateWaypoint(_ waypoint: UserWaypoint) throws
    func deleteWaypoint(id: UUID) throws
}

protocol RecordedTrackRepository {
    func listTracks() throws -> [RecordedTrack]
    func track(id: UUID) throws -> RecordedTrack?
    func createTrack(_ track: RecordedTrack) throws
    func updateTrack(_ track: RecordedTrack) throws
    func deleteTrack(id: UUID) throws
}

protocol TileCacheService: Sendable {
    var regionBudget: TileRegionBudget { get }

    func hasCachedTiles(for region: CachedTileRegion) -> Bool
    func cachedRegions() -> [CachedTileRegion]
    func totalCacheSizeBytes() -> Int64
    func planRegionSave(
        name: String,
        region: MapRegion,
        zoomRange: ClosedRange<Int>
    ) throws -> TileRegionSavePlan
    func saveRegion(using plan: TileRegionSavePlan) async throws -> CachedTileRegion
    func deleteCachedRegion(id: UUID) throws
    func tileData(x: Int, y: Int, z: Int) -> Data?
}
