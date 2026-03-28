import Foundation
import WeatherKit
import CoreLocation

protocol WeatherForecastService: Sendable {
    func fetchTenDayForecast(for location: CLLocationCoordinate2D) async throws -> [DailyForecast]
    func attribution() async -> (markURL: URL, legalURL: URL)?
}

final class LiveWeatherKitForecastService: WeatherForecastService {
    private let weatherService = WeatherService.shared

    func fetchTenDayForecast(for location: CLLocationCoordinate2D) async throws -> [DailyForecast] {
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let weather = try await weatherService.weather(for: clLocation, including: .daily)
        let now = Date()
        return weather.forecast.prefix(10).map { day in
            DailyForecast(
                id: UUID(),
                date: day.date,
                highTemperature: day.highTemperature.converted(to: .celsius).value,
                lowTemperature: day.lowTemperature.converted(to: .celsius).value,
                conditionCode: day.condition.rawValue,
                conditionDescription: day.condition.description,
                precipitationChance: day.precipitationChance,
                uvIndexValue: day.uvIndex.value,
                windSpeedKmh: day.wind.speed.converted(to: .kilometersPerHour).value,
                symbolName: day.symbolName,
                fetchedAt: now
            )
        }
    }

    func attribution() async -> (markURL: URL, legalURL: URL)? {
        do {
            let attr = try await weatherService.attribution
            return (markURL: attr.combinedMarkDarkURL, legalURL: attr.legalPageURL)
        } catch {
            return nil
        }
    }
}
