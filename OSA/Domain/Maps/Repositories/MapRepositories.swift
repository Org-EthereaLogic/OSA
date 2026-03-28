import Foundation
import CoreLocation

protocol MapAnnotationProvider: Sendable {
    func annotations(near coordinate: CLLocationCoordinate2D, radiusKm: Double) -> [MapAnnotationItem]
    func allAnnotations() -> [MapAnnotationItem]
}

protocol TileCacheService: Sendable {
    func hasCachedTiles(for region: CachedTileRegion) -> Bool
    func cachedRegions() -> [CachedTileRegion]
    func tileData(x: Int, y: Int, z: Int) -> Data?
}
