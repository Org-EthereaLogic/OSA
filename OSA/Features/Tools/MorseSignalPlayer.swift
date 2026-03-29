import Foundation
import Observation

@MainActor
@Observable
final class MorseSignalPlayer {
    var isRunning = false
    var isPulseActive = false

    private let unitDurationNanoseconds: UInt64
    private var task: Task<Void, Never>?

    init(unitDurationNanoseconds: UInt64 = 220_000_000) {
        self.unitDurationNanoseconds = unitDurationNanoseconds
    }

    func play(
        tokens: [SurvivalToolKit.MorsePlaybackToken],
        repeats: Bool = false,
        haptics: (any HapticFeedbackService)? = nil
    ) {
        stop()

        let pulses = SurvivalToolKit.signalPulses(for: tokens)
        guard !pulses.isEmpty else { return }

        isRunning = true
        let feedbackService = haptics

        task = Task { @MainActor [weak self] in
            guard let self else { return }

            repeat {
                for pulse in pulses {
                    guard !Task.isCancelled else { break }

                    switch pulse {
                    case .signal(let units):
                        isPulseActive = true
                        feedbackService?.play(.cprMetronomeBeat)
                        try? await Task.sleep(nanoseconds: unitDurationNanoseconds * UInt64(units))
                    case .pause(let units):
                        isPulseActive = false
                        try? await Task.sleep(nanoseconds: unitDurationNanoseconds * UInt64(units))
                    }
                }

                if repeats, !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: unitDurationNanoseconds * 4)
                }
            } while repeats && !Task.isCancelled

            finishPlayback()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        finishPlayback()
    }

    private func finishPlayback() {
        isRunning = false
        isPulseActive = false
    }
}
