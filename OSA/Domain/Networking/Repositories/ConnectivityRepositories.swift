import Foundation

/// A service that monitors device network connectivity and publishes
/// the current ``ConnectivityState``.
///
/// Implementations must be safe to observe from the main actor.
/// The `.syncInProgress` state is set programmatically by callers
/// (e.g., the import pipeline) and is never produced by the monitor itself.
protocol ConnectivityService: AnyObject, Sendable {
    /// The current connectivity state. Reads must happen on the main actor.
    @MainActor var currentState: ConnectivityState { get }

    /// An asynchronous stream of connectivity state changes.
    /// Consumers should use this to react to network transitions.
    @MainActor func stateStream() -> AsyncStream<ConnectivityState>

    /// Begin monitoring network path changes.
    /// Calling this when already started has no effect.
    func start()

    /// Stop monitoring network path changes and release resources.
    func stop()

    /// Programmatically override the state to `.syncInProgress`.
    /// Call this when the import pipeline begins a sync operation.
    @MainActor func setSyncInProgress()

    /// Clear the `.syncInProgress` override and resume reflecting
    /// the actual network state.
    @MainActor func clearSyncInProgress()
}
