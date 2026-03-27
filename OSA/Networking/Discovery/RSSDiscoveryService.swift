import Foundation

/// Discovers new articles by fetching and parsing RSS/Atom feeds
/// from trusted sources listed in `RSSFeedRegistry`.
protocol RSSDiscoveryService: Sendable {
    func discoverArticles() async -> [DiscoveredArticle]
}

/// Live implementation that fetches feeds over the network.
final class LiveRSSDiscoveryService: RSSDiscoveryService, @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func discoverArticles() async -> [DiscoveredArticle] {
        var allArticles: [DiscoveredArticle] = []
        var seenURLs = Set<String>()

        for entry in RSSFeedRegistry.allFeedEntries {
            guard entry.url.scheme == "https" else { continue }

            do {
                let (data, response) = try await session.data(from: entry.url)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    continue
                }

                let parser = RSSFeedParser(feedHost: entry.host)
                let articles = parser.parse(data: data)

                for article in articles {
                    let urlString = article.articleURL.absoluteString
                    if !seenURLs.contains(urlString) {
                        seenURLs.insert(urlString)
                        allArticles.append(article)
                    }
                }
            } catch {
                // Non-fatal: skip feeds that fail
                continue
            }
        }

        return allArticles
    }
}
