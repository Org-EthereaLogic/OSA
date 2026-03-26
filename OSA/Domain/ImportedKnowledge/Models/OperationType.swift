import Foundation

/// The kind of work a pending operation represents in the import pipeline.
enum OperationType: String, Codable, CaseIterable, Equatable, Sendable {
    case fetch
    case normalize
    case chunk
    case index
}
