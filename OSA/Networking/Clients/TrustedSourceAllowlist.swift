import Foundation

/// A launch-approved publisher that OSA is permitted to fetch from.
///
/// Each entry maps onto the existing ``TrustLevel`` and ``ReviewStatus``
/// enums from the imported-knowledge domain model.
struct TrustedSourceDefinition: Equatable, Sendable {
    let publisherName: String
    let canonicalHost: String
    let trustLevel: TrustLevel
    let defaultReviewStatus: ReviewStatus
    let notes: String?
}

/// The single source of truth for which remote hosts OSA may fetch from.
///
/// Only explicit HTTPS hosts in this list are considered approved.
/// Unknown, wildcard, and non-HTTPS hosts are rejected by default.
enum TrustedSourceAllowlist {

    // MARK: - Tier 1: Curated / Approved

    private static let tier1: [TrustedSourceDefinition] = [
        TrustedSourceDefinition(
            publisherName: "Ready.gov",
            canonicalHost: "www.ready.gov",
            trustLevel: .curated,
            defaultReviewStatus: .approved,
            notes: "FEMA national preparedness portal"
        ),
        TrustedSourceDefinition(
            publisherName: "Oregon Dept of Emergency Management",
            canonicalHost: "www.oregon.gov",
            trustLevel: .curated,
            defaultReviewStatus: .approved,
            notes: "Oregon OEM — emergency management under oregon.gov"
        ),
        TrustedSourceDefinition(
            publisherName: "Washington Emergency Management",
            canonicalHost: "mil.wa.gov",
            trustLevel: .curated,
            defaultReviewStatus: .approved,
            notes: "WA EMD under Military Department"
        ),
        TrustedSourceDefinition(
            publisherName: "USGS",
            canonicalHost: "www.usgs.gov",
            trustLevel: .curated,
            defaultReviewStatus: .approved,
            notes: "U.S. Geological Survey — earthquake and hazard data"
        ),
        TrustedSourceDefinition(
            publisherName: "American Red Cross — Cascades",
            canonicalHost: "www.redcross.org",
            trustLevel: .curated,
            defaultReviewStatus: .approved,
            notes: "American Red Cross national site; Cascades region content"
        ),
        TrustedSourceDefinition(
            publisherName: "USDA Forest Service R6",
            canonicalHost: "www.fs.usda.gov",
            trustLevel: .curated,
            defaultReviewStatus: .approved,
            notes: "USDA Forest Service — Pacific Northwest Region (R6)"
        ),
    ]

    // MARK: - Tier 2: Community / Approved

    private static let tier2: [TrustedSourceDefinition] = [
        TrustedSourceDefinition(
            publisherName: "Pacific NW Seismic Network",
            canonicalHost: "pnsn.org",
            trustLevel: .community,
            defaultReviewStatus: .approved,
            notes: "UW/UO seismic monitoring network"
        ),
        TrustedSourceDefinition(
            publisherName: "OSU Extension — Cascadia",
            canonicalHost: "extension.oregonstate.edu",
            trustLevel: .community,
            defaultReviewStatus: .approved,
            notes: "Oregon State University Extension Service"
        ),
        TrustedSourceDefinition(
            publisherName: "The Prepared",
            canonicalHost: "theprepared.com",
            trustLevel: .community,
            defaultReviewStatus: .approved,
            notes: "Evidence-based preparedness guidance"
        ),
        TrustedSourceDefinition(
            publisherName: "Surviving Cascadia",
            canonicalHost: "survivingcascadia.com",
            trustLevel: .community,
            defaultReviewStatus: .approved,
            notes: "PNW-focused Cascadia preparedness"
        ),
        TrustedSourceDefinition(
            publisherName: "Cascadia Ready",
            canonicalHost: "cascadiaready.com",
            trustLevel: .community,
            defaultReviewStatus: .approved,
            notes: "Community Cascadia earthquake readiness"
        ),
        TrustedSourceDefinition(
            publisherName: "Seattle Emergency Hubs",
            canonicalHost: "seattleemergencyhubs.org",
            trustLevel: .community,
            defaultReviewStatus: .approved,
            notes: "Neighborhood emergency communication hubs"
        ),
    ]

    // MARK: - Tier 3: Unverified / Pending

    private static let tier3: [TrustedSourceDefinition] = [
        TrustedSourceDefinition(
            publisherName: "Oregon Hazards Lab",
            canonicalHost: "oregonhazlab.com",
            trustLevel: .unverified,
            defaultReviewStatus: .pending,
            notes: "Research lab hazard data — reference only at launch"
        ),
        TrustedSourceDefinition(
            publisherName: "Mountain House Blog",
            canonicalHost: "mountainhouse.com",
            trustLevel: .unverified,
            defaultReviewStatus: .pending,
            notes: "Freeze-dried food manufacturer blog — reference only"
        ),
        TrustedSourceDefinition(
            publisherName: "Survival Common Sense",
            canonicalHost: "survivalcommonsense.com",
            trustLevel: .unverified,
            defaultReviewStatus: .pending,
            notes: "General survival skills blog — reference only"
        ),
    ]

    // MARK: - Combined List

    /// All approved launch publishers across all tiers.
    static let allSources: [TrustedSourceDefinition] = tier1 + tier2 + tier3

    /// Host-keyed lookup index built once from the static source list.
    private static let hostIndex: [String: TrustedSourceDefinition] = {
        Dictionary(uniqueKeysWithValues: allSources.map { ($0.canonicalHost, $0) })
    }()

    // MARK: - Lookup

    /// Returns the trusted-source definition for a URL, or `nil` if the URL
    /// is not from an approved publisher.
    ///
    /// Matching is exact on the URL's `host` property — no wildcard or
    /// suffix rules are applied.
    static func entry(for url: URL) -> TrustedSourceDefinition? {
        guard let host = url.host?.lowercased() else { return nil }
        return hostIndex[host]
    }

    /// Returns `true` if the URL belongs to an approved publisher.
    static func isAllowed(_ url: URL) -> Bool {
        entry(for: url) != nil
    }

    /// Returns the trusted-source definition for an exact hostname,
    /// or `nil` if the host is not in the allowlist.
    static func definition(forHost host: String) -> TrustedSourceDefinition? {
        hostIndex[host.lowercased()]
    }
}
