import Foundation

protocol WeatherAlertService: Sendable {
    func fetchAlerts() async -> [WeatherAlert]
}

final class LiveWeatherAlertService: WeatherAlertService, @unchecked Sendable {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchAlerts() async -> [WeatherAlert] {
        let weatherFeeds: [(host: String, url: URL)] = RSSFeedRegistry.allFeedEntries
            .filter { $0.host == "api.weather.gov" || $0.host == "wcatwc.arh.noaa.gov" }

        var allAlerts: [WeatherAlert] = []
        var seenURLs = Set<String>()

        for entry in weatherFeeds {
            guard entry.url.scheme == "https" else { continue }
            do {
                let (data, response) = try await session.data(from: entry.url)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode) else { continue }

                let parser = NWSAlertParser(feedHost: entry.host)
                let alerts = parser.parse(data: data)
                for alert in alerts {
                    let key = alert.alertURL.absoluteString
                    if !seenURLs.contains(key) {
                        seenURLs.insert(key)
                        allAlerts.append(alert)
                    }
                }
            } catch {
                continue
            }
        }
        return allAlerts
    }
}
