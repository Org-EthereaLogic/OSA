import CoreLocation

struct HeadingReading: Equatable, Sendable {
    let magneticHeading: Double
    let trueHeading: Double?
    let accuracy: Double

    var displayHeading: Double {
        trueHeading ?? magneticHeading
    }
}

protocol LocationService: AnyObject, Sendable {
    @MainActor var currentLocation: CLLocationCoordinate2D? { get }
    @MainActor var authorizationStatus: CLAuthorizationStatus { get }
    @MainActor var currentHeading: HeadingReading? { get }
    @MainActor var isHeadingAvailable: Bool { get }
    func requestWhenInUseAuthorization()
    @MainActor func locationStream() -> AsyncStream<CLLocationCoordinate2D>
    @MainActor func locationUpdateStream() -> AsyncStream<CLLocation>
    @MainActor func headingStream() -> AsyncStream<HeadingReading>
    @MainActor func authorizationStatusStream() -> AsyncStream<CLAuthorizationStatus>
}

final class CLLocationManagerService: NSObject, LocationService, CLLocationManagerDelegate,
    @unchecked Sendable {

    private let manager = CLLocationManager()
    @MainActor private(set) var currentLocation: CLLocationCoordinate2D?
    @MainActor private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @MainActor private(set) var currentHeading: HeadingReading?
    @MainActor private var coordinateContinuations: [UUID: AsyncStream<CLLocationCoordinate2D>.Continuation] = [:]
    @MainActor private var locationContinuations: [UUID: AsyncStream<CLLocation>.Continuation] = [:]
    @MainActor private var headingContinuations: [UUID: AsyncStream<HeadingReading>.Continuation] = [:]
    @MainActor private var authorizationContinuations: [UUID: AsyncStream<CLAuthorizationStatus>.Continuation] = [:]

    @MainActor
    var isHeadingAvailable: Bool {
        CLLocationManager.headingAvailable()
    }

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.headingFilter = 2
        manager.distanceFilter = 10
    }

    func requestWhenInUseAuthorization() {
        manager.requestWhenInUseAuthorization()
    }

    @MainActor
    func locationStream() -> AsyncStream<CLLocationCoordinate2D> {
        let id = UUID()
        return AsyncStream { continuation in
            coordinateContinuations[id] = continuation
            if let currentLocation {
                continuation.yield(currentLocation)
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.coordinateContinuations.removeValue(forKey: id)
                    self?.updateLocationMonitoring()
                }
            }
            updateLocationMonitoring()
        }
    }

    @MainActor
    func locationUpdateStream() -> AsyncStream<CLLocation> {
        let id = UUID()
        return AsyncStream { continuation in
            locationContinuations[id] = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.locationContinuations.removeValue(forKey: id)
                    self?.updateLocationMonitoring()
                }
            }
            updateLocationMonitoring()
        }
    }

    @MainActor
    func headingStream() -> AsyncStream<HeadingReading> {
        let id = UUID()
        return AsyncStream { continuation in
            headingContinuations[id] = continuation
            if let currentHeading {
                continuation.yield(currentHeading)
            }
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.headingContinuations.removeValue(forKey: id)
                    self?.updateHeadingMonitoring()
                }
            }
            updateHeadingMonitoring()
        }
    }

    @MainActor
    func authorizationStatusStream() -> AsyncStream<CLAuthorizationStatus> {
        let id = UUID()
        return AsyncStream { continuation in
            authorizationContinuations[id] = continuation
            continuation.yield(authorizationStatus)
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor in
                    self?.authorizationContinuations.removeValue(forKey: id)
                }
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let coordinate = location.coordinate
        Task { @MainActor in
            currentLocation = coordinate
            for continuation in coordinateContinuations.values {
                continuation.yield(coordinate)
            }
            for continuation in locationContinuations.values {
                continuation.yield(location)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.authorizationStatus = status
            for continuation in self.authorizationContinuations.values {
                continuation.yield(status)
            }
            self.updateLocationMonitoring()
            self.updateHeadingMonitoring()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let headingReading = HeadingReading(
            magneticHeading: newHeading.magneticHeading,
            trueHeading: newHeading.trueHeading >= 0 ? newHeading.trueHeading : nil,
            accuracy: newHeading.headingAccuracy
        )
        Task { @MainActor [weak self] in
            self?.currentHeading = headingReading
            self?.headingContinuations.values.forEach { $0.yield(headingReading) }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Non-fatal — location is supplementary
    }

    @MainActor
    private func updateLocationMonitoring() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            manager.stopUpdatingLocation()
            return
        }

        if !coordinateContinuations.isEmpty || !locationContinuations.isEmpty {
            manager.startUpdatingLocation()
        } else {
            manager.stopUpdatingLocation()
        }
    }

    @MainActor
    private func updateHeadingMonitoring() {
        guard isHeadingAvailable,
              authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
        else {
            manager.stopUpdatingHeading()
            return
        }

        if !headingContinuations.isEmpty {
            manager.startUpdatingHeading()
        } else {
            manager.stopUpdatingHeading()
        }
    }
}
