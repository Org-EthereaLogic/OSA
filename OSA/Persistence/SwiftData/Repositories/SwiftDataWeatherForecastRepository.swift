import Foundation
import SwiftData

final class SwiftDataWeatherForecastRepository: WeatherForecastRepository, @unchecked Sendable {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func cachedForecasts() throws -> [DailyForecast] {
        var descriptor = FetchDescriptor<PersistedDailyForecast>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).map { $0.toDomain() }
    }

    func replaceForecasts(_ forecasts: [DailyForecast]) throws {
        var descriptor = FetchDescriptor<PersistedDailyForecast>()
        descriptor.includePendingChanges = true
        let existing = try modelContext.fetch(descriptor)
        for record in existing { modelContext.delete(record) }
        for forecast in forecasts { modelContext.insert(PersistedDailyForecast(from: forecast)) }
        try modelContext.save()
    }

    func cacheInfo() throws -> ForecastCacheInfo? {
        var descriptor = FetchDescriptor<PersistedDailyForecast>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        descriptor.includePendingChanges = true
        guard let latest = try modelContext.fetch(descriptor).first else { return nil }
        let isStale = Date().timeIntervalSince(latest.fetchedAt) > 3600
        return ForecastCacheInfo(fetchedAt: latest.fetchedAt, isStale: isStale)
    }

    func cachedAlerts() throws -> [WeatherAlert] {
        var descriptor = FetchDescriptor<PersistedWeatherAlert>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        return try modelContext.fetch(descriptor).compactMap { $0.toDomain() }
    }

    func replaceAlerts(_ alerts: [WeatherAlert]) throws {
        var descriptor = FetchDescriptor<PersistedWeatherAlert>()
        descriptor.includePendingChanges = true
        let existing = try modelContext.fetch(descriptor)
        for record in existing { modelContext.delete(record) }
        for alert in alerts { modelContext.insert(PersistedWeatherAlert(from: alert)) }
        try modelContext.save()
    }

    func activeAlerts() throws -> [WeatherAlert] {
        let now = Date()
        return try cachedAlerts().filter { alert in
            guard let expires = alert.expiresDate else { return true }
            return expires > now
        }
    }
}
