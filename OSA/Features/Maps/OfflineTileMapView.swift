import SwiftUI
import MapKit

struct OfflineTileMapView: UIViewRepresentable {
    let annotations: [MapAnnotationItem]
    let tileCacheService: any TileCacheService
    let userLocation: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        let overlay = CachedTileOverlay(tileCacheService: tileCacheService)
        overlay.canReplaceMapContent = true
        mapView.addOverlay(overlay, level: .aboveLabels)

        let pnwCenter = CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784)
        let region = MKCoordinateRegion(
            center: userLocation ?? pnwCenter,
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
        mapView.setRegion(region, animated: false)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        let mkAnnotations = annotations.map { item -> MKPointAnnotation in
            let annotation = MKPointAnnotation()
            annotation.title = item.title
            annotation.subtitle = item.subtitle
            annotation.coordinate = item.coordinate
            return annotation
        }
        mapView.addAnnotations(mkAnnotations)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(overlay: tileOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

/// Custom tile overlay that reads from the local OSM tile cache.
final class CachedTileOverlay: MKTileOverlay {
    private let tileCacheService: any TileCacheService

    init(tileCacheService: any TileCacheService) {
        self.tileCacheService = tileCacheService
        super.init(urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png")
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        if let cached = tileCacheService.tileData(x: path.x, y: path.y, z: path.z) {
            result(cached, nil)
            return
        }
        // Fall through to network fetch from the URL template
        super.loadTile(at: path, result: result)
    }
}
