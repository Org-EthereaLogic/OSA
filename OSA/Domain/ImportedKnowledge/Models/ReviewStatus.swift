import Foundation

/// The editorial review status of an imported source record.
enum ReviewStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case pending
    case approved
    case rejected
}
