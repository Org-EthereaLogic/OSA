import Foundation
import Testing
@testable import OSA

@Suite("RSSFeedRegistry")
struct RSSFeedRegistryTests {

    @Test("Weather alert feeds are registered under api.weather.gov")
    func weatherFeedsRegistered() {
        let feeds = RSSFeedRegistry.feeds["api.weather.gov"]
        #expect(feeds != nil)
        #expect(feeds?.count == 2)
    }

    @Test("Tsunami feed is registered under wcatwc.arh.noaa.gov")
    func tsunamiFeedRegistered() {
        let feeds = RSSFeedRegistry.feeds["wcatwc.arh.noaa.gov"]
        #expect(feeds != nil)
        #expect(feeds?.count == 1)
    }

    @Test("All feed URLs use HTTPS")
    func allFeedsUseHTTPS() {
        for entry in RSSFeedRegistry.allFeedEntries {
            #expect(entry.url.scheme == "https", "Feed \(entry.url) must use HTTPS")
        }
    }

    @Test("Original Tier 1 feeds are still present")
    func tier1FeedsPresent() {
        #expect(RSSFeedRegistry.feeds["www.ready.gov"] != nil)
        #expect(RSSFeedRegistry.feeds["www.usgs.gov"] != nil)
        #expect(RSSFeedRegistry.feeds["www.redcross.org"] != nil)
    }

    @Test("Original Tier 2 feeds are still present")
    func tier2FeedsPresent() {
        #expect(RSSFeedRegistry.feeds["theprepared.com"] != nil)
        #expect(RSSFeedRegistry.feeds["extension.oregonstate.edu"] != nil)
    }

    @Test("Total feed host count is 7")
    func totalHostCount() {
        #expect(RSSFeedRegistry.feeds.count == 7)
    }
}
