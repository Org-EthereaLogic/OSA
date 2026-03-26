import Foundation

/// The trust tier assigned to an imported knowledge source.
///
/// Maps to the three-tier trust model defined in the trusted-source allowlist:
/// - `curated`: Vetted by editorial review; highest confidence.
/// - `community`: Reputable community sources; moderate confidence.
/// - `unverified`: User-submitted or unreviewed; lowest confidence.
enum TrustLevel: String, Codable, CaseIterable, Equatable, Sendable {
    case curated
    case community
    case unverified
}
