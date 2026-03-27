import Foundation

/// An article discovered from an RSS feed or web search.
struct DiscoveredArticle: Equatable, Sendable {
    let title: String
    let articleURL: URL
    let publishedDate: Date?
    let sourceHost: String
}

/// Summary of a discovery run.
struct DiscoveryResult: Equatable, Sendable {
    let articlesDiscovered: Int
    let articlesImported: Int
    let articlesSkippedDuplicate: Int
    let errors: [String]

    static let empty = DiscoveryResult(
        articlesDiscovered: 0,
        articlesImported: 0,
        articlesSkippedDuplicate: 0,
        errors: []
    )
}

/// Settings keys for knowledge discovery.
enum DiscoverySettings {
    static let isRSSDiscoveryEnabledKey = "osa_rss_discovery_enabled"
    static let braveSearchAPIKeyKey = "osa_brave_search_api_key"
    static let braveSearchQueryCountKey = "osa_brave_query_count"
    static let braveSearchQueryMonthKey = "osa_brave_query_month"
    static let lastDiscoveryDateKey = "osa_last_discovery_date"

    static let isRSSDiscoveryEnabledDefault = true
    static let monthlyQueryBudget = 1800
    static let minimumDiscoveryInterval: TimeInterval = 24 * 60 * 60
    static let maxArticlesPerRun = 10
}
