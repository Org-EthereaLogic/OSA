import Foundation
import SwiftData

@Model
final class PersistedWeatherAlert {
    @Attribute(.unique) var id: UUID
    var title: String
    var summary: String
    var alertURLString: String
    var severityRawValue: String
    var areaDescription: String
    var effectiveDate: Date?
    var expiresDate: Date?
    var sourceHost: String
    var fetchedAt: Date

    init(
        id: UUID,
        title: String,
        summary: String,
        alertURLString: String,
        severityRawValue: String,
        areaDescription: String,
        effectiveDate: Date?,
        expiresDate: Date?,
        sourceHost: String,
        fetchedAt: Date
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.alertURLString = alertURLString
        self.severityRawValue = severityRawValue
        self.areaDescription = areaDescription
        self.effectiveDate = effectiveDate
        self.expiresDate = expiresDate
        self.sourceHost = sourceHost
        self.fetchedAt = fetchedAt
    }
}
