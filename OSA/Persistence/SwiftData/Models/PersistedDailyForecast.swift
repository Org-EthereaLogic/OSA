import Foundation
import SwiftData

@Model
final class PersistedDailyForecast {
    @Attribute(.unique) var id: UUID
    var date: Date
    var highTemperature: Double
    var lowTemperature: Double
    var conditionCode: String
    var conditionDescription: String
    var precipitationChance: Double
    var uvIndexValue: Int
    var windSpeedKmh: Double
    var symbolName: String
    var fetchedAt: Date

    init(
        id: UUID,
        date: Date,
        highTemperature: Double,
        lowTemperature: Double,
        conditionCode: String,
        conditionDescription: String,
        precipitationChance: Double,
        uvIndexValue: Int,
        windSpeedKmh: Double,
        symbolName: String,
        fetchedAt: Date
    ) {
        self.id = id
        self.date = date
        self.highTemperature = highTemperature
        self.lowTemperature = lowTemperature
        self.conditionCode = conditionCode
        self.conditionDescription = conditionDescription
        self.precipitationChance = precipitationChance
        self.uvIndexValue = uvIndexValue
        self.windSpeedKmh = windSpeedKmh
        self.symbolName = symbolName
        self.fetchedAt = fetchedAt
    }
}
