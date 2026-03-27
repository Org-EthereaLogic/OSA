import Foundation

/// Parses RSS 2.0 and Atom XML feeds into `DiscoveredArticle` values.
///
/// Uses Foundation's `XMLParser` with no third-party dependencies.
/// Handles both RSS `<item><link>` and Atom `<entry><link href="...">` formats.
final class RSSFeedParser: NSObject, XMLParserDelegate, @unchecked Sendable {

    private var articles: [DiscoveredArticle] = []
    private let feedHost: String

    // Parsing state
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var insideItem = false
    private var isAtomFeed = false

    init(feedHost: String) {
        self.feedHost = feedHost
    }

    func parse(data: Data) -> [DiscoveredArticle] {
        articles = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return articles
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes attributeDict: [String: String]
    ) {
        currentElement = elementName

        switch elementName {
        case "item":
            insideItem = true
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""

        case "entry":
            insideItem = true
            isAtomFeed = true
            currentTitle = ""
            currentLink = ""
            currentPubDate = ""

        case "link" where insideItem && isAtomFeed:
            if let href = attributeDict["href"] {
                let rel = attributeDict["rel"] ?? "alternate"
                if rel == "alternate" || currentLink.isEmpty {
                    currentLink = href
                }
            }

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        if elementName == "item" || elementName == "entry" {
            insideItem = false
            let trimmedLink = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)

            if let url = URL(string: trimmedLink), !trimmedTitle.isEmpty {
                let date = parseDate(currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
                articles.append(DiscoveredArticle(
                    title: trimmedTitle,
                    articleURL: url,
                    publishedDate: date,
                    sourceHost: feedHost
                ))
            }
        }
    }

    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        guard insideItem else { return }

        switch currentElement {
        case "title":
            currentTitle += string
        case "link" where !isAtomFeed:
            currentLink += string
        case "pubDate", "published", "updated":
            currentPubDate += string
        default:
            break
        }
    }

    // MARK: - Date Parsing

    private static let rfc822Formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return f
    }()

    private static nonisolated(unsafe) let iso8601Formatter = ISO8601DateFormatter()

    private func parseDate(_ string: String) -> Date? {
        guard !string.isEmpty else { return nil }
        return Self.rfc822Formatter.date(from: string)
            ?? Self.iso8601Formatter.date(from: string)
    }
}
