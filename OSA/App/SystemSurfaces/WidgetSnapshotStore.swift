import Foundation

struct WidgetSnapshotStore {
    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init?(userDefaults: UserDefaults? = UserDefaults(suiteName: SystemSurfaceConfiguration.appGroupIdentifier)) {
        guard let userDefaults else { return nil }
        self.userDefaults = userDefaults

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func load() -> WidgetSnapshot? {
        guard let data = userDefaults.data(forKey: SystemSurfaceConfiguration.sharedDefaultsKey) else {
            return nil
        }
        return try? decoder.decode(WidgetSnapshot.self, from: data)
    }

    func save(_ snapshot: WidgetSnapshot) throws {
        let data = try encoder.encode(snapshot)
        userDefaults.set(data, forKey: SystemSurfaceConfiguration.sharedDefaultsKey)
    }

    func clear() {
        userDefaults.removeObject(forKey: SystemSurfaceConfiguration.sharedDefaultsKey)
    }
}
