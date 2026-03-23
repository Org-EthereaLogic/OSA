import Foundation

enum PersistenceValueCoding {
    static func encode(_ values: [String]) -> String {
        encodeValue(values)
    }

    static func decodeStrings(from rawValue: String) -> [String] {
        decodeValue([String].self, from: rawValue) ?? []
    }

    static func encode(_ values: [UUID]) -> String {
        encodeValue(values.map(\.uuidString))
    }

    static func decodeUUIDs(from rawValue: String) -> [UUID] {
        decodeStrings(from: rawValue).compactMap(UUID.init(uuidString:))
    }

    private static func encodeValue<T: Encodable>(_ value: T) -> String {
        let encoder = JSONEncoder()

        guard let data = try? encoder.encode(value),
              let stringValue = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }

        return stringValue
    }

    private static func decodeValue<T: Decodable>(_ type: T.Type, from rawValue: String) -> T? {
        let decoder = JSONDecoder()

        guard let data = rawValue.data(using: .utf8) else {
            return nil
        }

        return try? decoder.decode(type, from: data)
    }
}
