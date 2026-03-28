import CoreLocation

protocol LocationService: AnyObject, Sendable {
    @MainActor var currentLocation: CLLocationCoordinate2D? { get }
    @MainActor var authorizationStatus: CLAuthorizationStatus { get }
    func requestWhenInUseAuthorization()
    @MainActor func locationStream() -> AsyncStream<CLLocationCoordinate2D>
}

final class CLLocationManagerService: NSObject, LocationService, CLLocationManagerDelegate,
    @unchecked Sendable {

    private let manager = CLLocationManager()
    @MainActor private(set) var currentLocation: CLLocationCoordinate2D?
    @MainActor private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @MainActor private var continuations: [UUID: AsyncStream<CLLocationCoordinate2D>.Continuation] = [:]

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    @MainActor
    func locationStream() -> AsyncStream<CLLocationCoordinate2D> {
        let id = UUID()
        return AsyncStream { continuation in
            continuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.continuations.removeValue(forKey: id)
                    if self?.continuations.isEmpty == true {
                        self?.manager.stopUpdatingLocation()
                    }
                }
            }
            manager.startUpdatingLocation()
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        Task { @MainActor in
            currentLocation = coordinate
            for continuation in continuations.values {
                continuation.yield(coordinate)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.manager.startUpdatingLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Non-fatal — location is supplementary
    }
}
