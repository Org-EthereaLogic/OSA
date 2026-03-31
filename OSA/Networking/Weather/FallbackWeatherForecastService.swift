import Foundation
import CoreLocation
import os

final class FallbackWeatherForecastService: WeatherForecastService {
    private let primary: any WeatherForecastService
    private let fallback: any WeatherForecastService
    private let logger = Logger(subsystem: "com.etherealogic.OSA", category: "WeatherFallback")

    init(
        primary: any WeatherForecastService,
        fallback: any WeatherForecastService
    ) {
        self.primary = primary
        self.fallback = fallback
    }

    func fetchTenDayForecast(for location: CLLocationCoordinate2D) async throws -> [DailyForecast] {
        do {
            let forecasts = try await primary.fetchTenDayForecast(for: location)
            if !forecasts.isEmpty {
                return forecasts
            }
        } catch {
            logger.info("Primary weather service failed, falling back: \(error.localizedDescription)")
        }

        return try await fallback.fetchTenDayForecast(for: location)
    }

    func attribution() async -> (markURL: URL, legalURL: URL)? {
        if let attr = await primary.attribution() {
            return attr
        }
        return await fallback.attribution()
    }
}
