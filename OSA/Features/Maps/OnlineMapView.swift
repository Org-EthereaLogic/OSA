import SwiftUI
import MapKit

struct OnlineMapView: View {
    let annotations: [MapAnnotationItem]
    let userLocation: CLLocationCoordinate2D?

    @State private var cameraPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 45.5152, longitude: -122.6784),
            span: MKCoordinateSpan(latitudeDelta: 2.0, longitudeDelta: 2.0)
        )
    )

    var body: some View {
        Map(position: $cameraPosition) {
            ForEach(annotations) { item in
                Annotation(item.title, coordinate: item.coordinate) {
                    MapAnnotationPin(category: item.category)
                }
            }
            UserAnnotation()
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .mapStyle(.standard(elevation: .realistic, showsTraffic: false))
    }
}
