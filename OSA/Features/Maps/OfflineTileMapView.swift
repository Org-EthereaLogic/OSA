import SwiftUI
import MapKit

struct OfflineTileMapView: UIViewRepresentable {
    let annotations: [MapAnnotationItem]
    let waypoints: [UserWaypoint]
    let measurementPoints: [CLLocationCoordinate2D]
    let recordedTrackPoints: [RecordedTrackPoint]
    let tileCacheService: any TileCacheService
    let userLocation: CLLocationCoordinate2D?
    @Binding var visibleRegion: MapRegion

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.pointOfInterestFilter = .excludingAll

        let overlay = CachedTileOverlay(tileCacheService: tileCacheService)
        overlay.canReplaceMapContent = true
        mapView.addOverlay(overlay, level: .aboveLabels)
        mapView.setRegion(visibleRegion.mkRegion, animated: false)

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.visibleRegion = $visibleRegion

        if !mapView.region.isApproximatelyEqual(to: visibleRegion.mkRegion) {
            mapView.setRegion(visibleRegion.mkRegion, animated: false)
        }

        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        mapView.addAnnotations(makeAnnotations())

        let nonTileOverlays = mapView.overlays.filter { !($0 is CachedTileOverlay) }
        mapView.removeOverlays(nonTileOverlays)

        if measurementPoints.count > 1 {
            mapView.addOverlay(MeasurementPolyline(coordinates: measurementPoints, count: measurementPoints.count))
        }

        let trackCoordinates = recordedTrackPoints.map(\.coordinate)
        if trackCoordinates.count > 1 {
            mapView.addOverlay(RecordedTrackPolyline(coordinates: trackCoordinates, count: trackCoordinates.count))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(visibleRegion: $visibleRegion)
    }

    private func makeAnnotations() -> [MKAnnotation] {
        let bundled = annotations.map { item -> BundledMapPointAnnotation in
            let annotation = BundledMapPointAnnotation(category: item.category)
            annotation.title = item.title
            annotation.subtitle = item.subtitle
            annotation.coordinate = item.coordinate
            return annotation
        }

        let userWaypoints = waypoints.map { waypoint -> UserWaypointMapAnnotation in
            let annotation = UserWaypointMapAnnotation(waypoint: waypoint)
            annotation.title = waypoint.title
            annotation.subtitle = waypoint.note
            annotation.coordinate = waypoint.coordinate
            return annotation
        }

        return bundled + userWaypoints
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var visibleRegion: Binding<MapRegion>

        init(visibleRegion: Binding<MapRegion>) {
            self.visibleRegion = visibleRegion
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let tileOverlay = overlay as? MKTileOverlay {
                return MKTileOverlayRenderer(overlay: tileOverlay)
            }

            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(overlay: polyline)
                if overlay is RecordedTrackPolyline {
                    renderer.strokeColor = UIColor(Color.osaEmergency)
                    renderer.lineWidth = 4
                } else {
                    renderer.strokeColor = UIColor(Color.osaPrimary)
                    renderer.lineWidth = 3
                    renderer.lineDashPattern = [6, 4]
                }
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            visibleRegion.wrappedValue = mapView.region.domainRegion
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }

            if let waypointAnnotation = annotation as? UserWaypointMapAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier,
                    for: annotation
                ) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(
                    annotation: annotation,
                    reuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier
                )
                view.annotation = annotation
                view.markerTintColor = UIColor(waypointAnnotation.waypoint.category.pinColor)
                view.glyphImage = UIImage(systemName: waypointAnnotation.waypoint.symbolName ?? waypointAnnotation.waypoint.category.symbolName)
                view.canShowCallout = true
                return view
            }

            if let bundledAnnotation = annotation as? BundledMapPointAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: "bundled-annotation",
                    for: annotation
                ) as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "bundled-annotation")
                view.annotation = annotation
                view.markerTintColor = UIColor(bundledAnnotation.category.pinColor)
                view.glyphImage = UIImage(systemName: bundledAnnotation.category.icon)
                view.canShowCallout = true
                return view
            }

            return nil
        }
    }
}

private final class MeasurementPolyline: MKPolyline {}
private final class RecordedTrackPolyline: MKPolyline {}

private final class BundledMapPointAnnotation: MKPointAnnotation {
    let category: MapAnnotationCategory

    init(category: MapAnnotationCategory) {
        self.category = category
        super.init()
    }
}

private final class UserWaypointMapAnnotation: MKPointAnnotation {
    let waypoint: UserWaypoint

    init(waypoint: UserWaypoint) {
        self.waypoint = waypoint
        super.init()
    }
}

/// Custom tile overlay that reads from the local OSM tile cache.
final class CachedTileOverlay: MKTileOverlay {
    private let tileCacheService: any TileCacheService

    init(tileCacheService: any TileCacheService) {
        self.tileCacheService = tileCacheService
        super.init(urlTemplate: nil)
    }

    override func loadTile(at path: MKTileOverlayPath, result: @escaping (Data?, Error?) -> Void) {
        result(tileCacheService.tileData(x: path.x, y: path.y, z: path.z), nil)
    }
}

private extension MKCoordinateRegion {
    func isApproximatelyEqual(to other: MKCoordinateRegion) -> Bool {
        abs(center.latitude - other.center.latitude) < 0.0001
            && abs(center.longitude - other.center.longitude) < 0.0001
            && abs(span.latitudeDelta - other.span.latitudeDelta) < 0.0001
            && abs(span.longitudeDelta - other.span.longitudeDelta) < 0.0001
    }

    var domainRegion: MapRegion {
        MapRegion(
            centerLatitude: center.latitude,
            centerLongitude: center.longitude,
            latitudeDelta: span.latitudeDelta,
            longitudeDelta: span.longitudeDelta
        )
    }
}
