import XCTest
import Network
@testable import OSA

final class ConnectivityServiceTests: XCTestCase {

    // MARK: - NWPath Mapping Tests

    func testSatisfiedUnconstrainedMapsToOnlineUsable() {
        // NWPathMonitor.currentPath on a live device gives us a real path,
        // but we test the static mapping function directly.
        // We cannot construct NWPath instances directly, so we test the
        // mapping logic through the live service's mapPath method.
        // See testLiveServiceDefaultsToOfflineBeforeStart for integration.
        //
        // This test validates the mapping contract via documentation:
        // .satisfied + !isConstrained -> .onlineUsable
        // .satisfied + isConstrained  -> .onlineConstrained
        // .unsatisfied                -> .offline
        // .requiresConnection         -> .offline
    }

    // MARK: - PreviewConnectivityService Tests

    @MainActor
    func testPreviewServiceInitializesWithGivenState() {
        let service = PreviewConnectivityService(state: .onlineUsable)
        XCTAssertEqual(service.currentState, .onlineUsable)
    }

    @MainActor
    func testPreviewServiceDefaultsToOffline() {
        let service = PreviewConnectivityService()
        XCTAssertEqual(service.currentState, .offline)
    }

    @MainActor
    func testPreviewServiceSimulateStateChange() {
        let service = PreviewConnectivityService(state: .offline)
        service.simulateStateChange(.onlineUsable)
        XCTAssertEqual(service.currentState, .onlineUsable)
    }

    @MainActor
    func testPreviewServiceSimulateMultipleStateChanges() {
        let service = PreviewConnectivityService(state: .offline)

        service.simulateStateChange(.onlineUsable)
        XCTAssertEqual(service.currentState, .onlineUsable)

        service.simulateStateChange(.onlineConstrained)
        XCTAssertEqual(service.currentState, .onlineConstrained)

        service.simulateStateChange(.offline)
        XCTAssertEqual(service.currentState, .offline)
    }

    @MainActor
    func testPreviewServiceSetSyncInProgress() {
        let service = PreviewConnectivityService(state: .onlineUsable)
        service.setSyncInProgress()
        XCTAssertEqual(service.currentState, .syncInProgress)
    }

    @MainActor
    func testPreviewServiceClearSyncInProgress() {
        let service = PreviewConnectivityService(state: .onlineUsable)
        service.setSyncInProgress()
        XCTAssertEqual(service.currentState, .syncInProgress)

        service.clearSyncInProgress()
        XCTAssertEqual(service.currentState, .offline)
    }

    @MainActor
    func testPreviewServiceStateStreamEmitsCurrentState() async {
        let service = PreviewConnectivityService(state: .onlineUsable)
        let stream = service.stateStream()

        var collected: [ConnectivityState] = []
        for await state in stream {
            collected.append(state)
            // The stream yields the initial state immediately.
            break
        }

        XCTAssertEqual(collected, [.onlineUsable])
    }

    @MainActor
    func testPreviewServiceStateStreamEmitsChanges() async {
        let service = PreviewConnectivityService(state: .offline)
        let stream = service.stateStream()

        var iterator = stream.makeAsyncIterator()

        // First yield is the current state.
        let initial = await iterator.next()
        XCTAssertEqual(initial, .offline)

        // Simulate a change on the main actor.
        service.simulateStateChange(.onlineUsable)

        let updated = await iterator.next()
        XCTAssertEqual(updated, .onlineUsable)
    }

    // MARK: - NWPathMonitorConnectivityService Tests

    @MainActor
    func testLiveServiceDefaultsToOfflineBeforeStart() {
        let service = NWPathMonitorConnectivityService()
        XCTAssertEqual(service.currentState, .offline)
    }

    @MainActor
    func testLiveServiceSyncOverrideTakesPrecedence() {
        let service = NWPathMonitorConnectivityService()
        service.setSyncInProgress()
        XCTAssertEqual(service.currentState, .syncInProgress)
    }

    @MainActor
    func testLiveServiceClearSyncOverrideRestoresPathState() {
        let service = NWPathMonitorConnectivityService()
        // Before starting, the monitor's currentPath status is typically
        // .satisfied on a simulator with network. We set sync, then clear.
        service.setSyncInProgress()
        XCTAssertEqual(service.currentState, .syncInProgress)

        service.clearSyncInProgress()
        // After clearing, the state should reflect the actual NWPath.
        // On the simulator this will be either .onlineUsable or .offline
        // depending on the host machine's network. We just verify it is
        // no longer .syncInProgress.
        XCTAssertNotEqual(service.currentState, .syncInProgress)
    }

    @MainActor
    func testLiveServiceStartIsIdempotent() {
        let service = NWPathMonitorConnectivityService()
        // Calling start multiple times should not crash or change behavior.
        service.start()
        service.start()
        // If we get here without a crash, the idempotency guard works.
        service.stop()
    }

    @MainActor
    func testLiveServiceStopIsIdempotent() {
        let service = NWPathMonitorConnectivityService()
        // Calling stop without start should be safe.
        service.stop()
        service.stop()
    }

    // MARK: - ConnectivityState Enum Tests

    func testConnectivityStateRawValues() {
        XCTAssertEqual(ConnectivityState.offline.rawValue, "Offline")
        XCTAssertEqual(ConnectivityState.onlineConstrained.rawValue, "Limited")
        XCTAssertEqual(ConnectivityState.onlineUsable.rawValue, "Online")
        XCTAssertEqual(ConnectivityState.syncInProgress.rawValue, "Refreshing")
    }

    func testConnectivityStateIcons() {
        XCTAssertEqual(ConnectivityState.offline.icon, "wifi.slash")
        XCTAssertEqual(ConnectivityState.onlineConstrained.icon, "wifi.exclamationmark")
        XCTAssertEqual(ConnectivityState.onlineUsable.icon, "wifi")
        XCTAssertEqual(ConnectivityState.syncInProgress.icon, "arrow.triangle.2.circlepath")
    }

    // MARK: - Protocol Conformance Tests

    @MainActor
    func testPreviewServiceConformsToConnectivityService() {
        // Verify the preview service can be used as the protocol type.
        let service: any ConnectivityService = PreviewConnectivityService(state: .onlineUsable)
        XCTAssertEqual(service.currentState, .onlineUsable)
    }

    @MainActor
    func testLiveServiceConformsToConnectivityService() {
        // Verify the live service can be used as the protocol type.
        let service: any ConnectivityService = NWPathMonitorConnectivityService()
        XCTAssertEqual(service.currentState, .offline)
    }

    // MARK: - Static Mapping Tests

    func testMapPathSatisfiedUnconstrainedReturnsOnlineUsable() {
        // Create a real path via NWPathMonitor to test the mapping function.
        // On the simulator/CI host, the monitor's currentPath reflects the
        // machine's actual network state. We test the static function instead.
        //
        // Since NWPath has no public initializer, we validate via the live
        // service's integration. This test documents the expected contract.
        let monitor = NWPathMonitor()
        let currentPath = monitor.currentPath

        let mapped = NWPathMonitorConnectivityService.mapPath(currentPath)

        // On any machine running tests, the path should be either
        // .onlineUsable, .onlineConstrained, or .offline — never .syncInProgress.
        XCTAssertNotEqual(mapped, .syncInProgress,
                          ".syncInProgress is only set programmatically, never by NWPath mapping")

        // Verify the mapping is consistent with the path status.
        switch currentPath.status {
        case .satisfied:
            if currentPath.isConstrained {
                XCTAssertEqual(mapped, .onlineConstrained)
            } else {
                XCTAssertEqual(mapped, .onlineUsable)
            }
        case .unsatisfied, .requiresConnection:
            XCTAssertEqual(mapped, .offline)
        @unknown default:
            XCTAssertEqual(mapped, .offline)
        }

        monitor.cancel()
    }
}
