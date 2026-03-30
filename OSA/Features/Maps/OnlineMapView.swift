import SwiftUI
import MapKit

struct OnlineMapView: View {
    let annotations: [MapAnnotationItem]
    let waypoints: [UserWaypoint]
    let measurementPoints: [CLLocationCoordinate2D]
    let recordedTrackPoints: [RecordedTrackPoint]
    let userLocation: CLLocationCoordinate2D?
    @Binding var visibleRegion: MapRegion

    @State private var cameraPosition: MapCameraPosition

    init(
        annotations: [MapAnnotationItem],
        waypoints: [UserWaypoint],
        measurementPoints: [CLLocationCoordinate2D],
        recordedTrackPoints: [RecordedTrackPoint],
        userLocation: CLLocationCoordinate2D?,
        visibleRegion: Binding<MapRegion>
    ) {
        self.annotations = annotations
        self.waypoints = waypoints
        self.measurementPoints = measurementPoints
        self.recordedTrackPoints = recordedTrackPoints
        self.userLocation = userLocation
        self._visibleRegion = visibleRegion
        self._cameraPosition = State(initialValue: .region(visibleRegion.wrappedValue.mkRegion))
    }

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(annotations) { item in
                Annotation(item.title, coordinate: item.coordinate) {
                    MapAnnotationPin(item: item)
                }
            }

            ForEach(waypoints) { waypoint in
                Annotation(waypoint.title, coordinate: waypoint.coordinate) {
                    UserWaypointPin(waypoint: waypoint)
                }
            }

            if measurementPoints.count > 1 {
                MapPolyline(coordinates: measurementPoints)
                    .stroke(.osaPrimary, style: StrokeStyle(lineWidth: 3, dash: [6, 4]))
            }

            let recordedCoordinates = recordedTrackPoints.map(\.coordinate)
            if recordedCoordinates.count > 1 {
                MapPolyline(coordinates: recordedCoordinates)
                    .stroke(.osaEmergency, lineWidth: 4)
            }

            UserAnnotation()
        }
        .onMapCameraChange(frequency: .continuous) { context in
            visibleRegion = context.region.domainRegion
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .realistic, showsTraffic: false))
    }
}

extension MapRegion {
    var mkRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: centerCoordinate,
            span: MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }
}

private extension MKCoordinateRegion {
    var domainRegion: MapRegion {
        MapRegion(
            centerLatitude: center.latitude,
            centerLongitude: center.longitude,
            latitudeDelta: span.latitudeDelta,
            longitudeDelta: span.longitudeDelta
        )
    }
}
