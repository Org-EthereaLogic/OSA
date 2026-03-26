import Foundation

/// The execution status of a pending operation in the import pipeline.
enum OperationStatus: String, Codable, CaseIterable, Equatable, Sendable {
    case queued
    case inProgress = "in-progress"
    case completed
    case failed
}
