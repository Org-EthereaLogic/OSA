import Foundation

/// A stub connectivity service that returns a fixed state.
/// Use this in SwiftUI previews and unit tests.
final class PreviewConnectivityService: ConnectivityService, @unchecked Sendable {

    @MainActor private(set) var currentState: ConnectivityState

    @MainActor private var continuations: [UUID: AsyncStream<ConnectivityState>.Continuation] = [:]

    @MainActor
    init(state: ConnectivityState = .offline) {
        self.currentState = state
    }

    // MARK: - Lifecycle (no-ops for stubs)

    func start() {}
    func stop() {}

    // MARK: - Sync Override

    @MainActor
    func setSyncInProgress() {
        updateState(.syncInProgress)
    }

    @MainActor
    func clearSyncInProgress() {
        // Restore whatever was the initial state. In a stub context
        // we default back to the state set at init, but since we don't
        // track the "underlying" state, just go offline.
        updateState(.offline)
    }

    // MARK: - Stream

    @MainActor
    func stateStream() -> AsyncStream<ConnectivityState> {
        let id = UUID()
        return AsyncStream { continuation in
            continuation.yield(self.currentState)
            self.continuations[id] = continuation

            continuation.onTermination = { @Sendable _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    // MARK: - Test Helpers

    /// Simulate a connectivity change for testing purposes.
    @MainActor
    func simulateStateChange(_ newState: ConnectivityState) {
        updateState(newState)
    }

    @MainActor
    private func updateState(_ newState: ConnectivityState) {
        currentState = newState
        for (_, continuation) in continuations {
            continuation.yield(newState)
        }
    }
}
