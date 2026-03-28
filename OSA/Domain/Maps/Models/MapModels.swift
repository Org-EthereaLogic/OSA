import Foundation
import CoreLocation

/// A point of interest displayed on the map.
struct MapAnnotationItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let subtitle: String?
    let latitude: Double
    let longitude: Double
    let category: MapAnnotationCategory
    let sourceURL: URL?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

enum MapAnnotationCategory: String, Codable, CaseIterable, Equatable, Sendable {
    case shelter
    case evacuationRoute
    case hazardZone
    case hospital
    case fireStation
    case waterSource

    var icon: String {
        switch self {
        case .shelter: "house.fill"
        case .evacuationRoute: "arrow.triangle.turn.up.right.diamond.fill"
        case .hazardZone: "exclamationmark.triangle.fill"
        case .hospital: "cross.fill"
        case .fireStation: "flame.fill"
        case .waterSource: "drop.fill"
        }
    }
}

/// Represents the current map display strategy.
enum MapDisplayMode: Equatable, Sendable {
    case online
    case offlineAppleMaps
    case offlineCachedTiles
    case offlineNoTiles
}

/// Represents a cached tile region.
struct CachedTileRegion: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let centerLatitude: Double
    let centerLongitude: Double
    let zoomRange: ClosedRange<Int>
    let tileCount: Int
    let downloadedAt: Date
    let sizeBytes: Int64
}
