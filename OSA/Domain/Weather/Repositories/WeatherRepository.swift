import Foundation

protocol WeatherForecastRepository: Sendable {
    func cachedForecasts() throws -> [DailyForecast]
    func replaceForecasts(_ forecasts: [DailyForecast]) throws
    func cacheInfo() throws -> ForecastCacheInfo?
    func cachedAlerts() throws -> [WeatherAlert]
    func replaceAlerts(_ alerts: [WeatherAlert]) throws
    func activeAlerts() throws -> [WeatherAlert]
}
