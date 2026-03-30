import CoreLocation
import Foundation

enum RescueCoordinateFormatter {
    static func string(
        from coordinate: CLLocationCoordinate2D,
        format: CoordinateDisplayFormat
    ) -> String {
        switch format {
        case .degreesDecimalMinutes:
            return degreesDecimalMinutesString(from: coordinate)
        case .decimalDegrees:
            return decimalDegreesString(from: coordinate)
        }
    }

    static func decimalDegreesString(from coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }

    static func degreesDecimalMinutesString(from coordinate: CLLocationCoordinate2D) -> String {
        [
            degreesDecimalMinutesComponent(for: coordinate.latitude, positiveHemisphere: "N", negativeHemisphere: "S"),
            degreesDecimalMinutesComponent(for: coordinate.longitude, positiveHemisphere: "E", negativeHemisphere: "W")
        ]
        .joined(separator: ", ")
    }

    private static func degreesDecimalMinutesComponent(
        for value: Double,
        positiveHemisphere: String,
        negativeHemisphere: String
    ) -> String {
        let hemisphere = value >= 0 ? positiveHemisphere : negativeHemisphere
        let absoluteValue = abs(value)
        let degrees = Int(absoluteValue)
        let minutes = (absoluteValue - Double(degrees)) * 60
        return String(format: "%d° %.3f' %@", degrees, minutes, hemisphere)
    }
}

enum NavigationDistanceCalculator {
    static func cumulativeDistance(for coordinates: [CLLocationCoordinate2D]) -> CLLocationDistance {
        guard coordinates.count > 1 else { return 0 }

        return zip(coordinates, coordinates.dropFirst()).reduce(0) { partial, pair in
            partial + CLLocation(latitude: pair.0.latitude, longitude: pair.0.longitude)
                .distance(from: CLLocation(latitude: pair.1.latitude, longitude: pair.1.longitude))
        }
    }

    static func cumulativeDistance(for points: [RecordedTrackPoint]) -> CLLocationDistance {
        cumulativeDistance(for: points.map(\.coordinate))
    }

    static func formattedDistance(_ meters: CLLocationDistance) -> String {
        let kilometers = meters / 1_000
        let miles = meters / 1_609.344

        if meters < 1_000 {
            return String(format: "%.0f m / %.2f mi", meters, miles)
        }

        return String(format: "%.2f km / %.2f mi", kilometers, miles)
    }

    static func formattedDuration(_ duration: TimeInterval?) -> String {
        guard let duration else { return "Not finished" }

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = duration >= 3_600 ? [.hour, .minute] : [.minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0s"
    }
}

struct SunCompassReading: Equatable {
    let azimuthDegrees: Double
    let cardinalDirection: String
    let guidance: String
}

enum SunCompassCalculator {
    static func reading(
        at date: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone = .current
    ) -> SunCompassReading? {
        guard let azimuth = azimuth(at: date, coordinate: coordinate, timeZone: timeZone) else {
            return nil
        }

        let facingDirection = cardinalDirection(for: azimuth)
        let reverseDirection = cardinalDirection(for: normalizedDegrees(azimuth + 180))
        let guidance = "The sun is roughly \(facingDirection). If you face it, \(reverseDirection.lowercased()) is behind you."

        return SunCompassReading(
            azimuthDegrees: azimuth,
            cardinalDirection: facingDirection,
            guidance: guidance
        )
    }

    static func azimuth(
        at date: Date,
        coordinate: CLLocationCoordinate2D,
        timeZone: TimeZone = .current
    ) -> Double? {
        let calendar = Calendar(identifier: .gregorian)
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let components = calendar.dateComponents(in: timeZone, from: date)
        let hours = Double(components.hour ?? 0)
        let minutes = Double(components.minute ?? 0)
        let seconds = Double(components.second ?? 0)
        let fractionalHour = hours + (minutes / 60) + (seconds / 3_600)
        let gamma = (2 * Double.pi / 365)
            * (Double(dayOfYear - 1) + ((fractionalHour - 12) / 24))

        let equationOfTime = 229.18 * (
            0.000_075
                + 0.001_868 * cos(gamma)
                - 0.032_077 * sin(gamma)
                - 0.014_615 * cos(2 * gamma)
                - 0.040_849 * sin(2 * gamma)
        )

        let declination =
            0.006_918
            - 0.399_912 * cos(gamma)
            + 0.070_257 * sin(gamma)
            - 0.006_758 * cos(2 * gamma)
            + 0.000_907 * sin(2 * gamma)
            - 0.002_697 * cos(3 * gamma)
            + 0.001_48 * sin(3 * gamma)

        let timeOffsetMinutes = equationOfTime
            + (4 * coordinate.longitude)
            - (Double(timeZone.secondsFromGMT(for: date)) / 60)
        let trueSolarTimeMinutes = (fractionalHour * 60) + timeOffsetMinutes
        let normalizedSolarTime = trueSolarTimeMinutes
            .truncatingRemainder(dividingBy: 1_440)
        let hourAngleDegrees = (normalizedSolarTime / 4) - 180
        let hourAngle = degreesToRadians(hourAngleDegrees)
        let latitude = degreesToRadians(coordinate.latitude)

        let cosZenith =
            (sin(latitude) * sin(declination))
            + (cos(latitude) * cos(declination) * cos(hourAngle))

        guard cosZenith >= -1, cosZenith <= 1 else { return nil }

        let azimuth = atan2(
            sin(hourAngle),
            (cos(hourAngle) * sin(latitude)) - (tan(declination) * cos(latitude))
        )

        return normalizedDegrees(radiansToDegrees(azimuth) + 180)
    }

    static func cardinalDirection(for degrees: Double) -> String {
        let directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW", "N"]
        let index = Int((normalizedDegrees(degrees) + 22.5) / 45)
        return directions[index]
    }

    private static func normalizedDegrees(_ value: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: 360)
        return remainder >= 0 ? remainder : remainder + 360
    }

    private static func degreesToRadians(_ degrees: Double) -> Double {
        degrees * .pi / 180
    }

    private static func radiansToDegrees(_ radians: Double) -> Double {
        radians * 180 / .pi
    }
}
