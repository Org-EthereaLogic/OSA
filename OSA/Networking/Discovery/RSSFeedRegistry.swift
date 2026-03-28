import Foundation

/// Static mapping of trusted source hosts to their known RSS/Atom feed URLs.
///
/// Only sources from `TrustedSourceAllowlist` that publish known feeds are
/// included. The registry is developer-curated and not dynamically discovered.
enum RSSFeedRegistry {
    /// Known RSS/Atom feed URLs keyed by canonical host.
    static let feeds: [String: [URL]] = {
        var map: [String: [URL]] = [:]
        func add(_ host: String, _ urls: String...) {
            map[host] = urls.compactMap { URL(string: $0) }
        }

        // Tier 1 — Curated
        add("www.ready.gov",
            "https://www.ready.gov/rss.xml")
        add("www.usgs.gov",
            "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.atom")
        add("www.redcross.org",
            "https://www.redcross.org/content/dam/redcross/about-us/news/rss/news-rss.xml")

        // Tier 2 — Community
        add("theprepared.com",
            "https://theprepared.com/feed/")
        add("extension.oregonstate.edu",
            "https://extension.oregonstate.edu/rss.xml")

        // Weather Alerts — NWS / NOAA
        add("api.weather.gov",
            "https://api.weather.gov/alerts/active.atom?area=WA",
            "https://api.weather.gov/alerts/active.atom?area=OR")
        add("wcatwc.arh.noaa.gov",
            "https://wcatwc.arh.noaa.gov/rss/tsunamirss.xml")

        return map
    }()

    /// All feed URLs flattened for iteration.
    static var allFeedEntries: [(host: String, url: URL)] {
        feeds.flatMap { host, urls in
            urls.map { (host: host, url: $0) }
        }
    }
}
