import AVFoundation
import Observation

@MainActor
@Observable
final class WhistleToneController {
    var isPlaying = false

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var isConfigured = false

    func start() {
        guard !isPlaying else { return }

        do {
            try configureIfNeeded()
            try configureAudioSession()
            if !engine.isRunning {
                try engine.start()
            }
            playerNode.play()
            isPlaying = true
        } catch {
            stop()
        }
    }

    func stop() {
        playerNode.pause()
        engine.pause()
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func configureIfNeeded() throws {
        guard !isConfigured else { return }

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
        guard let format else {
            throw WhistleToneError.audioFormatUnavailable
        }

        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.mainMixerNode, format: format)
        playerNode.scheduleBuffer(
            try makeToneBuffer(format: format),
            at: nil,
            options: [.loops]
        )
        isConfigured = true
    }

    private func configureAudioSession() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }

    private func makeToneBuffer(format: AVAudioFormat) throws -> AVAudioPCMBuffer {
        let duration = 0.32
        let sampleRate = format.sampleRate
        let frameCount = AVAudioFrameCount(sampleRate * duration)

        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let channel = buffer.floatChannelData?.pointee else {
            throw WhistleToneError.bufferCreationFailed
        }

        buffer.frameLength = frameCount

        let fundamental = 1_850.0
        let harmonic = 3_700.0

        for frame in 0..<Int(frameCount) {
            let progress = Double(frame) / Double(frameCount)
            let theta = 2 * Double.pi * fundamental * Double(frame) / sampleRate
            let harmonicTheta = 2 * Double.pi * harmonic * Double(frame) / sampleRate
            let attack = min(progress / 0.12, 1)
            let release = min((1 - progress) / 0.18, 1)
            let envelope = max(0, min(attack, release))
            let sample = (sin(theta) * 0.68) + (sin(harmonicTheta) * 0.18)
            channel[frame] = Float(sample * envelope * 0.35)
        }

        return buffer
    }
}

private enum WhistleToneError: Error {
    case audioFormatUnavailable
    case bufferCreationFailed
}
