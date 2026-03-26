import Foundation
import Network

/// Live connectivity service backed by `NWPathMonitor`.
///
/// All published state lives on `@MainActor` so SwiftUI views can
/// read `currentState` directly. The underlying `NWPathMonitor`
/// dispatches path updates to a dedicated serial queue, which are
/// then forwarded to the main actor.
final class NWPathMonitorConnectivityService: ConnectivityService, @unchecked Sendable {

    // MARK: - State

    /// The current connectivity state, readable from the main actor.
    @MainActor private(set) var currentState: ConnectivityState = .offline

    /// When `true`, `currentState` is locked to `.syncInProgress`
    /// regardless of the underlying network path.
    @MainActor private var isSyncOverrideActive = false

    /// Continuations for active `stateStream()` consumers.
    @MainActor private var continuations: [UUID: AsyncStream<ConnectivityState>.Continuation] = [:]

    // MARK: - Monitor

    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "com.etherealogic.osa.connectivity", qos: .utility)
    private let lock = NSLock()
    private var isMonitoring = false

    // MARK: - Init

    init(monitor: NWPathMonitor = NWPathMonitor()) {
        self.monitor = monitor
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Lifecycle

    func start() {
        lock.lock()
        defer { lock.unlock() }
        guard !isMonitoring else { return }
        isMonitoring = true

        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let mapped = Self.mapPath(path)
            Task { @MainActor in
                self.handlePathUpdate(mapped)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    func stop() {
        lock.lock()
        defer { lock.unlock() }
        guard isMonitoring else { return }
        isMonitoring = false

        monitor.cancel()
    }

    // MARK: - Sync Override

    @MainActor
    func setSyncInProgress() {
        isSyncOverrideActive = true
        updateState(.syncInProgress)
    }

    @MainActor
    func clearSyncInProgress() {
        isSyncOverrideActive = false
        // Re-derive state from the last known path.
        let mapped = Self.mapPath(monitor.currentPath)
        updateState(mapped)
    }

    // MARK: - Stream

    @MainActor
    func stateStream() -> AsyncStream<ConnectivityState> {
        let id = UUID()
        return AsyncStream { continuation in
            // Emit the current state immediately so consumers have a starting value.
            continuation.yield(self.currentState)
            self.continuations[id] = continuation

            continuation.onTermination = { @Sendable _ in
                Task { @MainActor [weak self] in
                    self?.continuations.removeValue(forKey: id)
                }
            }
        }
    }

    // MARK: - Internal

    @MainActor
    private func handlePathUpdate(_ mappedState: ConnectivityState) {
        guard !isSyncOverrideActive else { return }
        updateState(mappedState)
    }

    @MainActor
    private func updateState(_ newState: ConnectivityState) {
        guard currentState != newState else { return }
        currentState = newState
        for (_, continuation) in continuations {
            continuation.yield(newState)
        }
    }

    // MARK: - Path Mapping

    /// Maps an `NWPath` to the appropriate ``ConnectivityState``.
    ///
    /// - `.satisfied` + `isConstrained` -> `.onlineConstrained`
    /// - `.satisfied` (unconstrained)   -> `.onlineUsable`
    /// - `.unsatisfied` / `.requiresConnection` / unknown -> `.offline`
    static func mapPath(_ path: NWPath) -> ConnectivityState {
        switch path.status {
        case .satisfied:
            return path.isConstrained ? .onlineConstrained : .onlineUsable
        case .unsatisfied, .requiresConnection:
            return .offline
        @unknown default:
            return .offline
        }
    }
}
