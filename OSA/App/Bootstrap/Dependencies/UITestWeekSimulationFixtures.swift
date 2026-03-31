import CoreLocation
import Foundation

enum WeekSimulationFixtures {
    static func discoveredArticles(now: Date) -> [DiscoveredArticle] {
        [
            DiscoveredArticle(
                title: "Build a Kit for the First 72 Hours",
                articleURL: URL(string: "https://www.ready.gov/kit")!,
                publishedDate: Calendar.current.date(byAdding: .day, value: -2, to: now),
                sourceHost: "www.ready.gov"
            ),
            DiscoveredArticle(
                title: "Water Storage and Rotation Basics",
                articleURL: URL(string: "https://www.ready.gov/water")!,
                publishedDate: Calendar.current.date(byAdding: .day, value: -1, to: now),
                sourceHost: "www.ready.gov"
            )
        ]
    }

    static func fetchResponse(for url: URL, now: Date) throws -> TrustedSourceFetchResponse {
        guard TrustedSourceAllowlist.isAllowed(url) else {
            throw TrustedSourceFetchError.disallowedHost
        }

        let body: String
        switch url.path {
        case "/kit":
            body = """
            <html>
              <head><title>Ready.gov Kit Guide</title></head>
              <body>
                <h1>Build a Kit for the First 72 Hours</h1>
                <p>Store at least one gallon of water per person per day for several days.</p>
                <p>Keep a flashlight, batteries, medications, copies of documents, and a local family contact list.</p>
                <p>Rotate food and water on a steady schedule so supplies remain current.</p>
              </body>
            </html>
            """
        case "/water":
            body = """
            <html>
              <head><title>Ready.gov Water Storage</title></head>
              <body>
                <h1>Water Storage and Rotation Basics</h1>
                <p>Label each container with the fill date and storage location.</p>
                <p>Review water storage every six months and replace anything with damaged seals or contamination risk.</p>
                <p>Keep purification tablets and a backup filter with the stored water supply.</p>
              </body>
            </html>
            """
        default:
            throw TrustedSourceFetchError.badStatusCode(404)
        }

        return TrustedSourceFetchResponse(
            requestedURL: url,
            finalURL: url,
            httpStatusCode: 200,
            contentType: "text/html",
            body: Data(body.utf8),
            fetchedAt: now
        )
    }

    static func forecasts(now: Date) -> [DailyForecast] {
        let calendar = Calendar.current
        return (0..<10).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: now) else {
                return nil
            }

            return DailyForecast(
                id: UUID(),
                date: date,
                highTemperature: 10 + Double(offset),
                lowTemperature: 4 + Double(offset / 2),
                conditionCode: offset == 0 ? "rain" : "cloud.sun",
                conditionDescription: offset == 0 ? "Rain showers" : "Partly cloudy",
                precipitationChance: offset == 0 ? 0.75 : 0.25,
                uvIndexValue: max(1, 3 + offset / 2),
                windSpeedKmh: 12 + Double(offset),
                symbolName: offset == 0 ? "cloud.rain.fill" : "cloud.sun.fill",
                fetchedAt: now
            )
        }
    }

    static func alerts(now: Date) -> [WeatherAlert] {
        [
            WeatherAlert(
                id: UUID(),
                title: "Wind Advisory",
                summary: "Gusty coastal wind expected this evening. Secure loose outdoor gear and charge devices.",
                alertURL: URL(string: "https://wcatwc.arh.noaa.gov/alerts/wind-advisory")!,
                severity: .moderate,
                areaDescription: "Pacific Northwest",
                effectiveDate: now,
                expiresDate: Calendar.current.date(byAdding: .hour, value: 12, to: now),
                sourceHost: "wcatwc.arh.noaa.gov",
                fetchedAt: now
            )
        ]
    }
}

final class WeekSimulationRSSDiscoveryService: RSSDiscoveryService, @unchecked Sendable {
    private let nowProvider: @Sendable () -> Date

    init(nowProvider: @escaping @Sendable () -> Date) {
        self.nowProvider = nowProvider
    }

    func discoverArticles() async -> [DiscoveredArticle] {
        WeekSimulationFixtures.discoveredArticles(now: nowProvider())
    }
}

final class WeekSimulationTrustedSourceHTTPClient: TrustedSourceHTTPClient, @unchecked Sendable {
    private let connectivityService: any ConnectivityService
    private let nowProvider: @Sendable () -> Date

    init(
        connectivityService: any ConnectivityService,
        nowProvider: @escaping @Sendable () -> Date
    ) {
        self.connectivityService = connectivityService
        self.nowProvider = nowProvider
    }

    func fetch(_ url: URL) async throws -> TrustedSourceFetchResponse {
        let state = await MainActor.run { connectivityService.currentState }
        guard state == .onlineUsable || state == .syncInProgress else {
            throw TrustedSourceFetchError.offline
        }

        return try WeekSimulationFixtures.fetchResponse(for: url, now: nowProvider())
    }
}

struct WeekSimulationWeatherForecastService: WeatherForecastService {
    private let nowProvider: @Sendable () -> Date

    init(nowProvider: @escaping @Sendable () -> Date) {
        self.nowProvider = nowProvider
    }

    func fetchTenDayForecast(for location: CLLocationCoordinate2D) async throws -> [DailyForecast] {
        _ = location
        return WeekSimulationFixtures.forecasts(now: nowProvider())
    }

    func attribution() async -> (markURL: URL, legalURL: URL)? {
        nil
    }
}

struct WeekSimulationWeatherAlertService: WeatherAlertService {
    private let nowProvider: @Sendable () -> Date

    init(nowProvider: @escaping @Sendable () -> Date) {
        self.nowProvider = nowProvider
    }

    func fetchAlerts() async -> [WeatherAlert] {
        WeekSimulationFixtures.alerts(now: nowProvider())
    }
}
