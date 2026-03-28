import Foundation
import Testing
@testable import OSA

@Suite("TrustedSourceAllowlist")
struct TrustedSourceAllowlistTests {

    // MARK: - Tier 1 Resolution

    @Test("Tier 1 host resolves with curated trust and approved status")
    func tier1HostResolves() {
        let url = URL(string: "https://www.ready.gov/plan")!
        let entry = TrustedSourceAllowlist.entry(for: url)
        #expect(entry != nil)
        #expect(entry?.publisherName == "Ready.gov")
        #expect(entry?.trustLevel == .curated)
        #expect(entry?.defaultReviewStatus == .approved)
    }

    @Test("All Tier 1 hosts are present in the allowlist")
    func allTier1HostsPresent() {
        let tier1Hosts = [
            "www.ready.gov",
            "www.oregon.gov",
            "mil.wa.gov",
            "www.usgs.gov",
            "www.redcross.org",
            "www.fs.usda.gov",
            "api.weather.gov",
            "wcatwc.arh.noaa.gov",
        ]
        for host in tier1Hosts {
            let url = URL(string: "https://\(host)/")!
            let entry = TrustedSourceAllowlist.entry(for: url)
            #expect(entry != nil, "Expected Tier 1 host \(host) to be in allowlist")
            #expect(entry?.trustLevel == .curated)
            #expect(entry?.defaultReviewStatus == .approved)
        }
    }

    // MARK: - Tier 2 Resolution

    @Test("Tier 2 host resolves with community trust and approved status")
    func tier2HostResolves() {
        let url = URL(string: "https://theprepared.com/guides")!
        let entry = TrustedSourceAllowlist.entry(for: url)
        #expect(entry != nil)
        #expect(entry?.publisherName == "The Prepared")
        #expect(entry?.trustLevel == .community)
        #expect(entry?.defaultReviewStatus == .approved)
    }

    @Test("All Tier 2 hosts are present in the allowlist")
    func allTier2HostsPresent() {
        let tier2Hosts = [
            "pnsn.org",
            "extension.oregonstate.edu",
            "theprepared.com",
            "survivingcascadia.com",
            "cascadiaready.com",
            "seattleemergencyhubs.org",
        ]
        for host in tier2Hosts {
            let url = URL(string: "https://\(host)/")!
            let entry = TrustedSourceAllowlist.entry(for: url)
            #expect(entry != nil, "Expected Tier 2 host \(host) to be in allowlist")
            #expect(entry?.trustLevel == .community)
            #expect(entry?.defaultReviewStatus == .approved)
        }
    }

    // MARK: - Tier 3 Resolution

    @Test("Tier 3 host resolves with unverified trust and pending status")
    func tier3HostResolves() {
        let url = URL(string: "https://mountainhouse.com/blog")!
        let entry = TrustedSourceAllowlist.entry(for: url)
        #expect(entry != nil)
        #expect(entry?.publisherName == "Mountain House Blog")
        #expect(entry?.trustLevel == .unverified)
        #expect(entry?.defaultReviewStatus == .pending)
    }

    @Test("All Tier 3 hosts are present in the allowlist")
    func allTier3HostsPresent() {
        let tier3Hosts = [
            "oregonhazlab.com",
            "mountainhouse.com",
            "survivalcommonsense.com",
        ]
        for host in tier3Hosts {
            let url = URL(string: "https://\(host)/")!
            let entry = TrustedSourceAllowlist.entry(for: url)
            #expect(entry != nil, "Expected Tier 3 host \(host) to be in allowlist")
            #expect(entry?.trustLevel == .unverified)
            #expect(entry?.defaultReviewStatus == .pending)
        }
    }

    // MARK: - Total Count

    @Test("Allowlist contains exactly 17 launch publishers")
    func allowlistCountIs17() {
        #expect(TrustedSourceAllowlist.allSources.count == 17)
    }

    // MARK: - Rejection

    @Test("Unknown domain is rejected")
    func unknownDomainRejected() {
        let url = URL(string: "https://example.com/page")!
        #expect(TrustedSourceAllowlist.isAllowed(url) == false)
        #expect(TrustedSourceAllowlist.entry(for: url) == nil)
    }

    @Test("Subdomain of approved host is rejected when not exact match")
    func subdomainRejected() {
        let url = URL(string: "https://evil.ready.gov/phishing")!
        // "evil.ready.gov" != "www.ready.gov"
        #expect(TrustedSourceAllowlist.isAllowed(url) == false)
    }

    @Test("URL without host is rejected")
    func missingHostRejected() {
        let url = URL(string: "file:///etc/passwd")!
        #expect(TrustedSourceAllowlist.isAllowed(url) == false)
    }

    @Test("Empty host string lookup returns nil")
    func emptyHostReturnsNil() {
        #expect(TrustedSourceAllowlist.definition(forHost: "") == nil)
    }

    // MARK: - Host Lookup

    @Test("definition(forHost:) resolves a known host")
    func definitionForHostResolves() {
        let def = TrustedSourceAllowlist.definition(forHost: "pnsn.org")
        #expect(def != nil)
        #expect(def?.publisherName == "Pacific NW Seismic Network")
    }

    @Test("definition(forHost:) is case-insensitive")
    func hostLookupCaseInsensitive() {
        let def = TrustedSourceAllowlist.definition(forHost: "WWW.READY.GOV")
        #expect(def != nil)
        #expect(def?.publisherName == "Ready.gov")
    }
}
