import Foundation
import CoreLocation

struct MapRegion: Equatable, Sendable {
    let centerLatitude: Double
    let centerLongitude: Double
    let latitudeDelta: Double
    let longitudeDelta: Double

    static let defaultPNW = MapRegion(
        centerLatitude: 45.5152,
        centerLongitude: -122.6784,
        latitudeDelta: 2.0,
        longitudeDelta: 2.0
    )

    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }

    var latitudeRange: ClosedRange<Double> {
        let halfDelta = latitudeDelta / 2
        return (centerLatitude - halfDelta)...(centerLatitude + halfDelta)
    }

    var longitudeRange: ClosedRange<Double> {
        let halfDelta = longitudeDelta / 2
        return (centerLongitude - halfDelta)...(centerLongitude + halfDelta)
    }
}

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

enum CoordinateDisplayFormat: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case degreesDecimalMinutes
    case decimalDegrees

    var id: String { rawValue }

    var title: String {
        switch self {
        case .degreesDecimalMinutes:
            "DDM"
        case .decimalDegrees:
            "Decimal Degrees"
        }
    }
}

enum UserWaypointCategory: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
    case general
    case shelter
    case water
    case medical
    case regroup

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            "General"
        case .shelter:
            "Shelter"
        case .water:
            "Water"
        case .medical:
            "Medical"
        case .regroup:
            "Regroup"
        }
    }

    var symbolName: String {
        switch self {
        case .general:
            "mappin.circle.fill"
        case .shelter:
            "house.circle.fill"
        case .water:
            "drop.circle.fill"
        case .medical:
            "cross.circle.fill"
        case .regroup:
            "figure.2.and.child.holdinghands"
        }
    }
}

struct UserWaypoint: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var note: String?
    var latitude: Double
    var longitude: Double
    var createdAt: Date
    var category: UserWaypointCategory
    var symbolName: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct RecordedTrackPoint: Identifiable, Equatable, Sendable {
    let id: UUID
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let horizontalAccuracy: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct RecordedTrack: Identifiable, Equatable, Sendable {
    let id: UUID
    var title: String
    var startedAt: Date
    var endedAt: Date?
    var totalDistanceMeters: Double
    var points: [RecordedTrackPoint]

    var duration: TimeInterval? {
        guard let endedAt else { return nil }
        return endedAt.timeIntervalSince(startedAt)
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

    var centerCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude)
    }
}

struct TileRegionBudget: Equatable, Sendable {
    let maxTilesPerRegion: Int
    let maxCacheSizeBytes: Int64
    let estimatedBytesPerTile: Int64

    static let standard = TileRegionBudget(
        maxTilesPerRegion: 1_200,
        maxCacheSizeBytes: 256 * 1_024 * 1_024,
        estimatedBytesPerTile: 28 * 1_024
    )
}

struct MapTileCoordinate: Hashable, Codable, Sendable {
    let x: Int
    let y: Int
    let z: Int

    var identifier: String {
        "\(z)/\(x)/\(y)"
    }
}

struct TileRegionSavePlan: Identifiable, Equatable, Sendable {
    let id: UUID
    let name: String
    let region: MapRegion
    let zoomRange: ClosedRange<Int>
    let tileCount: Int
    let newTileCount: Int
    let estimatedSizeBytes: Int64
    let projectedCacheSizeBytes: Int64
    let tileCoordinates: [MapTileCoordinate]
}

enum TileRegionPlanningError: LocalizedError, Equatable, Sendable {
    case invalidZoomRange
    case tileCountExceedsLimit(requested: Int, limit: Int)
    case cacheBudgetExceeded(projectedBytes: Int64, limitBytes: Int64)

    var errorDescription: String? {
        switch self {
        case .invalidZoomRange:
            "Choose a valid zoom range before saving offline tiles."
        case .tileCountExceedsLimit(let requested, let limit):
            "That area is too large to save in one request. Requested \(requested) tiles, limit \(limit). Narrow the map view or lower the zoom range."
        case .cacheBudgetExceeded(let projectedBytes, let limitBytes):
            "Saving this region would exceed the local tile budget. Projected \(projectedBytes) bytes, limit \(limitBytes). Delete a saved region or reduce the request."
        }
    }
}
