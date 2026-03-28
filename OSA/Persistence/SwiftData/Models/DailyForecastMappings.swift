import Foundation

extension PersistedDailyForecast {
    convenience init(from forecast: DailyForecast) {
        self.init(
            id: forecast.id,
            date: forecast.date,
            highTemperature: forecast.highTemperature,
            lowTemperature: forecast.lowTemperature,
            conditionCode: forecast.conditionCode,
            conditionDescription: forecast.conditionDescription,
            precipitationChance: forecast.precipitationChance,
            uvIndexValue: forecast.uvIndexValue,
            windSpeedKmh: forecast.windSpeedKmh,
            symbolName: forecast.symbolName,
            fetchedAt: forecast.fetchedAt
        )
    }

    func update(from forecast: DailyForecast) {
        date = forecast.date
        highTemperature = forecast.highTemperature
        lowTemperature = forecast.lowTemperature
        conditionCode = forecast.conditionCode
        conditionDescription = forecast.conditionDescription
        precipitationChance = forecast.precipitationChance
        uvIndexValue = forecast.uvIndexValue
        windSpeedKmh = forecast.windSpeedKmh
        symbolName = forecast.symbolName
        fetchedAt = forecast.fetchedAt
    }

    func toDomain() -> DailyForecast {
        DailyForecast(
            id: id,
            date: date,
            highTemperature: highTemperature,
            lowTemperature: lowTemperature,
            conditionCode: conditionCode,
            conditionDescription: conditionDescription,
            precipitationChance: precipitationChance,
            uvIndexValue: uvIndexValue,
            windSpeedKmh: windSpeedKmh,
            symbolName: symbolName,
            fetchedAt: fetchedAt
        )
    }
}
