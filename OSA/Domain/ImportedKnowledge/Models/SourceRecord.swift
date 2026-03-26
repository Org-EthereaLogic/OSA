import Foundation

/// A trusted-source registration that tracks provenance, trust tier, and review state
/// for content imported from external sources.
struct SourceRecord: Identifiable, Equatable, Sendable {
    let id: UUID
    var sourceTitle: String
    var sourceURL: String
    var publisherDomain: String
    var publisherName: String
    var fetchedAt: Date
    var lastReviewedAt: Date
    var contentHash: String
    var trustLevel: TrustLevel
    var tags: [String]
    var localChunkIDs: [UUID]
    var reviewStatus: ReviewStatus
    var licenseSummary: String?
    var isActive: Bool
    var staleAfter: Date
}
