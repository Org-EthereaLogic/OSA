import Foundation

/// Unified coordinator that discovers new content from RSS feeds and
/// optionally Brave Search, deduplicates against already-imported sources,
/// and feeds new URLs through the existing `ImportedKnowledgeImportPipeline`.
///
/// Discovery is connectivity-gated and schedule-limited (once per day).
/// Tier 1/2 sources are auto-approved by the existing pipeline.
/// Tier 3 sources land as `.pending` for review.
final class KnowledgeDiscoveryCoordinator: @unchecked Sendable {
    private let rssDiscoveryService: any RSSDiscoveryService
    private let webSearchClient: (any WebSearchClient)?
    private let httpClient: any TrustedSourceHTTPClient
    private let importPipeline: ImportedKnowledgeImportPipeline
    private let importedKnowledgeRepository: any ImportedKnowledgeRepository
    private let connectivityService: any ConnectivityService
    private let defaults: UserDefaults
    private let now: @Sendable () -> Date

    init(
        rssDiscoveryService: any RSSDiscoveryService,
        webSearchClient: (any WebSearchClient)?,
        httpClient: any TrustedSourceHTTPClient,
        importPipeline: ImportedKnowledgeImportPipeline,
        importedKnowledgeRepository: any ImportedKnowledgeRepository,
        connectivityService: any ConnectivityService,
        defaults: UserDefaults = .standard,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.rssDiscoveryService = rssDiscoveryService
        self.webSearchClient = webSearchClient
        self.httpClient = httpClient
        self.importPipeline = importPipeline
        self.importedKnowledgeRepository = importedKnowledgeRepository
        self.connectivityService = connectivityService
        self.defaults = defaults
        self.now = now
    }

    /// Run discovery if the schedule permits and connectivity is available.
    @MainActor
    func startIfDue() async {
        guard isDue() else { return }
        guard connectivityService.currentState == .onlineUsable else { return }
        _ = await discoverAndImport()
    }

    /// Run discovery immediately, bypassing the schedule check.
    @MainActor
    func discoverAndImport() async -> DiscoveryResult {
        guard connectivityService.currentState == .onlineUsable else {
            return .empty
        }

        var candidateURLs: [(title: String, url: URL)] = []

        // RSS discovery
        if defaults.object(forKey: DiscoverySettings.isRSSDiscoveryEnabledKey) as? Bool
            ?? DiscoverySettings.isRSSDiscoveryEnabledDefault {
            let rssArticles = await rssDiscoveryService.discoverArticles()
            for article in rssArticles {
                candidateURLs.append((title: article.title, url: article.articleURL))
            }
        }

        // Brave Search discovery (optional)
        if let searchClient = webSearchClient {
            let queries = [
                "PNW earthquake preparedness",
                "Cascadia emergency kit checklist",
                "Pacific Northwest wildfire evacuation"
            ]
            for query in queries {
                if let results = try? await searchClient.search(query: query) {
                    let trustedResults = results.filter { result in
                        TrustedSourceAllowlist.isAllowed(result.url)
                    }
                    for result in trustedResults {
                        candidateURLs.append((title: result.title, url: result.url))
                    }
                }
            }
        }

        // Deduplicate by URL
        var seenURLs = Set<String>()
        let uniqueCandidates = candidateURLs.filter { candidate in
            let key = candidate.url.absoluteString
            if seenURLs.contains(key) { return false }
            seenURLs.insert(key)
            return true
        }

        // Filter out already-imported URLs
        let newCandidates = uniqueCandidates.filter { candidate in
            let existing = try? importedKnowledgeRepository.source(url: candidate.url.absoluteString)
            return existing == nil
        }

        let totalDiscovered = uniqueCandidates.count
        let skippedDuplicate = uniqueCandidates.count - newCandidates.count
        var imported = 0
        var errors: [String] = []

        // Import up to the batch limit
        let batch = Array(newCandidates.prefix(DiscoverySettings.maxArticlesPerRun))
        for candidate in batch {
            do {
                let response = try await httpClient.fetch(candidate.url)
                _ = try importPipeline.importFetchedContent(response)
                imported += 1
            } catch {
                errors.append("\(candidate.url.absoluteString): \(error.localizedDescription)")
            }
        }

        // Record discovery timestamp
        defaults.set(now().timeIntervalSince1970, forKey: DiscoverySettings.lastDiscoveryDateKey)

        return DiscoveryResult(
            articlesDiscovered: totalDiscovered,
            articlesImported: imported,
            articlesSkippedDuplicate: skippedDuplicate,
            errors: errors
        )
    }

    // MARK: - Schedule

    private func isDue() -> Bool {
        let lastTimestamp = defaults.double(forKey: DiscoverySettings.lastDiscoveryDateKey)
        guard lastTimestamp > 0 else { return true }
        let lastDate = Date(timeIntervalSince1970: lastTimestamp)
        return now().timeIntervalSince(lastDate) >= DiscoverySettings.minimumDiscoveryInterval
    }
}
