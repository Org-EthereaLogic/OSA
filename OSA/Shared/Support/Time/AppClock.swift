import Foundation

enum AppClock {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var provider: @Sendable () -> Date = Date.init

    static func install(_ newProvider: @escaping @Sendable () -> Date) {
        lock.lock()
        provider = newProvider
        lock.unlock()
    }

    static func reset() {
        install(Date.init)
    }

    static func now() -> Date {
        lock.lock()
        let provider = provider
        lock.unlock()
        return provider()
    }
}
