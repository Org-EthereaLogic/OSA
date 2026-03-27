import XCTest
@testable import OSA

final class RSSFeedParserTests: XCTestCase {

    // MARK: - RSS 2.0

    func testParsesRSS20FeedWithMultipleItems() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Test Feed</title>
            <item>
              <title>First Article</title>
              <link>https://example.com/article1</link>
              <pubDate>Mon, 01 Jan 2024 12:00:00 +0000</pubDate>
            </item>
            <item>
              <title>Second Article</title>
              <link>https://example.com/article2</link>
              <pubDate>Tue, 02 Jan 2024 12:00:00 +0000</pubDate>
            </item>
          </channel>
        </rss>
        """
        let parser = RSSFeedParser(feedHost: "example.com")
        let articles = parser.parse(data: Data(xml.utf8))

        XCTAssertEqual(articles.count, 2)
        XCTAssertEqual(articles[0].title, "First Article")
        XCTAssertEqual(articles[0].articleURL.absoluteString, "https://example.com/article1")
        XCTAssertEqual(articles[1].title, "Second Article")
    }

    // MARK: - Atom

    func testParsesAtomFeedWithEntries() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <feed xmlns="http://www.w3.org/2005/Atom">
          <title>Test Atom Feed</title>
          <entry>
            <title>Atom Entry</title>
            <link href="https://example.com/entry1" rel="alternate"/>
            <published>2024-01-01T12:00:00Z</published>
          </entry>
        </feed>
        """
        let parser = RSSFeedParser(feedHost: "example.com")
        let articles = parser.parse(data: Data(xml.utf8))

        XCTAssertEqual(articles.count, 1)
        XCTAssertEqual(articles[0].title, "Atom Entry")
        XCTAssertEqual(articles[0].articleURL.absoluteString, "https://example.com/entry1")
        XCTAssertNotNil(articles[0].publishedDate)
    }

    // MARK: - Empty Feed

    func testEmptyFeedReturnsNoArticles() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Empty Feed</title>
          </channel>
        </rss>
        """
        let parser = RSSFeedParser(feedHost: "example.com")
        let articles = parser.parse(data: Data(xml.utf8))

        XCTAssertTrue(articles.isEmpty)
    }

    // MARK: - Malformed XML

    func testMalformedXMLDoesNotCrash() {
        let xml = "not valid xml at all <><>>"
        let parser = RSSFeedParser(feedHost: "example.com")
        let articles = parser.parse(data: Data(xml.utf8))

        XCTAssertTrue(articles.isEmpty)
    }

    // MARK: - Missing Date

    func testMissingPubDateReturnsNilDate() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <item>
              <title>No Date</title>
              <link>https://example.com/nodate</link>
            </item>
          </channel>
        </rss>
        """
        let parser = RSSFeedParser(feedHost: "example.com")
        let articles = parser.parse(data: Data(xml.utf8))

        XCTAssertEqual(articles.count, 1)
        XCTAssertNil(articles[0].publishedDate)
    }

    // MARK: - Host Propagation

    func testFeedHostIsSetOnArticles() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <item>
              <title>Test</title>
              <link>https://example.com/test</link>
            </item>
          </channel>
        </rss>
        """
        let parser = RSSFeedParser(feedHost: "www.ready.gov")
        let articles = parser.parse(data: Data(xml.utf8))

        XCTAssertEqual(articles[0].sourceHost, "www.ready.gov")
    }

    // MARK: - Missing Link

    func testItemWithoutLinkIsSkipped() {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <item>
              <title>No Link</title>
            </item>
          </channel>
        </rss>
        """
        let parser = RSSFeedParser(feedHost: "example.com")
        let articles = parser.parse(data: Data(xml.utf8))

        XCTAssertTrue(articles.isEmpty)
    }
}
