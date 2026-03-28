import Foundation

/// A single day's forecast from WeatherKit, cached for offline access.
struct DailyForecast: Identifiable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let highTemperature: Double
    let lowTemperature: Double
    let conditionCode: String
    let conditionDescription: String
    let precipitationChance: Double
    let uvIndexValue: Int
    let windSpeedKmh: Double
    let symbolName: String
    let fetchedAt: Date
}

/// A weather alert from NWS ATOM feeds.
struct WeatherAlert: Identifiable, Equatable, Sendable {
    let id: UUID
    let title: String
    let summary: String
    let alertURL: URL
    let severity: WeatherAlertSeverity
    let areaDescription: String
    let effectiveDate: Date?
    let expiresDate: Date?
    let sourceHost: String
    let fetchedAt: Date
}

enum WeatherAlertSeverity: String, Codable, CaseIterable, Equatable, Sendable {
    case extreme
    case severe
    case moderate
    case minor
    case unknown
}

/// Metadata about a cached forecast for staleness display.
struct ForecastCacheInfo: Equatable, Sendable {
    let fetchedAt: Date
    let isStale: Bool

    var stalenessDescription: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return "Updated \(formatter.localizedString(for: fetchedAt, relativeTo: Date()))"
    }
}
