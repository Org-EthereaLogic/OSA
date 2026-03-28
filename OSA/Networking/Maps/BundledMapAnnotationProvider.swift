import Foundation
import CoreLocation

/// Provides map annotations from a bundled JSON file of PNW shelters,
/// evacuation routes, and hazard zones. Always available offline.
final class BundledMapAnnotationProvider: MapAnnotationProvider {
    private let annotations: [MapAnnotationItem]

    init(bundle: Bundle = .main) {
        guard let url = Self.resourceURL(in: bundle),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([BundledAnnotation].self, from: data)
        else {
            self.annotations = []
            return
        }
        self.annotations = decoded.map { item in
            MapAnnotationItem(
                id: UUID(),
                title: item.title,
                subtitle: item.subtitle,
                latitude: item.latitude,
                longitude: item.longitude,
                category: MapAnnotationCategory(rawValue: item.category) ?? .shelter,
                sourceURL: item.sourceURL.flatMap { URL(string: $0) }
            )
        }
    }

    func annotations(near coordinate: CLLocationCoordinate2D, radiusKm: Double) -> [MapAnnotationItem] {
        let center = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return annotations.filter { item in
            let itemLocation = CLLocation(latitude: item.latitude, longitude: item.longitude)
            return center.distance(from: itemLocation) / 1000.0 <= radiusKm
        }
    }

    func allAnnotations() -> [MapAnnotationItem] { annotations }

    private static func resourceURL(in bundle: Bundle) -> URL? {
        let candidates = [bundle, Bundle.main] + Bundle.allBundles + Bundle.allFrameworks
        for candidate in candidates {
            if let url = candidate.url(
                forResource: "pnw-map-annotations",
                withExtension: "json",
                subdirectory: "SeedContent"
            ) {
                return url
            }
        }

        return nil
    }
}

private struct BundledAnnotation: Codable {
    let title: String
    let subtitle: String?
    let latitude: Double
    let longitude: Double
    let category: String
    let sourceURL: String?
}
