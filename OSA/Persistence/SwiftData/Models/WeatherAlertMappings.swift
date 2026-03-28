import Foundation

extension PersistedWeatherAlert {
    convenience init(from alert: WeatherAlert) {
        self.init(
            id: alert.id,
            title: alert.title,
            summary: alert.summary,
            alertURLString: alert.alertURL.absoluteString,
            severityRawValue: alert.severity.rawValue,
            areaDescription: alert.areaDescription,
            effectiveDate: alert.effectiveDate,
            expiresDate: alert.expiresDate,
            sourceHost: alert.sourceHost,
            fetchedAt: alert.fetchedAt
        )
    }

    func update(from alert: WeatherAlert) {
        title = alert.title
        summary = alert.summary
        alertURLString = alert.alertURL.absoluteString
        severityRawValue = alert.severity.rawValue
        areaDescription = alert.areaDescription
        effectiveDate = alert.effectiveDate
        expiresDate = alert.expiresDate
        sourceHost = alert.sourceHost
        fetchedAt = alert.fetchedAt
    }

    func toDomain() -> WeatherAlert? {
        guard let url = URL(string: alertURLString) else { return nil }
        return WeatherAlert(
            id: id,
            title: title,
            summary: summary,
            alertURL: url,
            severity: WeatherAlertSeverity(rawValue: severityRawValue) ?? .unknown,
            areaDescription: areaDescription,
            effectiveDate: effectiveDate,
            expiresDate: expiresDate,
            sourceHost: sourceHost,
            fetchedAt: fetchedAt
        )
    }
}
