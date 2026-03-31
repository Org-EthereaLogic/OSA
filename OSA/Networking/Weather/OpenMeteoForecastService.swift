import Foundation
import CoreLocation

final class OpenMeteoForecastService: WeatherForecastService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchTenDayForecast(for location: CLLocationCoordinate2D) async throws -> [DailyForecast] {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.latitude)),
            URLQueryItem(name: "longitude", value: String(location.longitude)),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max,uv_index_max,wind_speed_10m_max"),
            URLQueryItem(name: "temperature_unit", value: "celsius"),
            URLQueryItem(name: "wind_speed_unit", value: "kmh"),
            URLQueryItem(name: "forecast_days", value: "10"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        guard let url = components.url else {
            throw OpenMeteoError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw OpenMeteoError.requestFailed
        }

        let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
        let now = Date()
        let calendar = Calendar.current

        return decoded.daily.time.enumerated().compactMap { index, dateString in
            guard let date = Self.parseDate(dateString, calendar: calendar) else { return nil }
            let code = decoded.daily.weather_code[safe: index] ?? 0
            let mapped = WMOWeatherCode.map(code)

            return DailyForecast(
                id: UUID(),
                date: date,
                highTemperature: decoded.daily.temperature_2m_max[safe: index] ?? 0,
                lowTemperature: decoded.daily.temperature_2m_min[safe: index] ?? 0,
                conditionCode: mapped.conditionCode,
                conditionDescription: mapped.description,
                precipitationChance: (decoded.daily.precipitation_probability_max[safe: index] ?? 0) / 100.0,
                uvIndexValue: Int(decoded.daily.uv_index_max[safe: index] ?? 0),
                windSpeedKmh: decoded.daily.wind_speed_10m_max[safe: index] ?? 0,
                symbolName: mapped.symbolName,
                fetchedAt: now
            )
        }
    }

    func attribution() async -> (markURL: URL, legalURL: URL)? {
        guard let mark = URL(string: "https://open-meteo.com/favicon.ico"),
              let legal = URL(string: "https://open-meteo.com/en/terms") else {
            return nil
        }
        return (markURL: mark, legalURL: legal)
    }

    private static func parseDate(_ string: String, calendar: Calendar) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = calendar
        return formatter.date(from: string)
    }
}

// MARK: - Error

enum OpenMeteoError: LocalizedError {
    case invalidURL
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: "Failed to build Open-Meteo request URL."
        case .requestFailed: "Open-Meteo request failed."
        }
    }
}

// MARK: - Response DTO

private struct OpenMeteoResponse: Decodable {
    let daily: DailyData

    struct DailyData: Decodable {
        let time: [String]
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let weather_code: [Int]
        let precipitation_probability_max: [Double]
        let uv_index_max: [Double]
        let wind_speed_10m_max: [Double]
    }
}

// MARK: - Safe Array Access

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - WMO Weather Code Mapping

private enum WMOWeatherCode {
    struct Mapped {
        let conditionCode: String
        let description: String
        let symbolName: String
    }

    static func map(_ code: Int) -> Mapped {
        switch code {
        case 0:
            Mapped(conditionCode: "clear", description: "Clear sky", symbolName: "sun.max.fill")
        case 1:
            Mapped(conditionCode: "mostly_clear", description: "Mostly clear", symbolName: "sun.min.fill")
        case 2:
            Mapped(conditionCode: "partly_cloudy", description: "Partly cloudy", symbolName: "cloud.sun.fill")
        case 3:
            Mapped(conditionCode: "overcast", description: "Overcast", symbolName: "cloud.fill")
        case 45, 48:
            Mapped(conditionCode: "fog", description: "Fog", symbolName: "cloud.fog.fill")
        case 51, 53, 55:
            Mapped(conditionCode: "drizzle", description: "Drizzle", symbolName: "cloud.drizzle.fill")
        case 56, 57:
            Mapped(conditionCode: "freezing_drizzle", description: "Freezing drizzle", symbolName: "cloud.sleet.fill")
        case 61, 63:
            Mapped(conditionCode: "rain", description: "Rain", symbolName: "cloud.rain.fill")
        case 65:
            Mapped(conditionCode: "heavy_rain", description: "Heavy rain", symbolName: "cloud.heavyrain.fill")
        case 66, 67:
            Mapped(conditionCode: "freezing_rain", description: "Freezing rain", symbolName: "cloud.sleet.fill")
        case 71, 73:
            Mapped(conditionCode: "snow", description: "Snow", symbolName: "cloud.snow.fill")
        case 75:
            Mapped(conditionCode: "heavy_snow", description: "Heavy snow", symbolName: "snow")
        case 77:
            Mapped(conditionCode: "snow_grains", description: "Snow grains", symbolName: "cloud.snow.fill")
        case 80, 81, 82:
            Mapped(conditionCode: "rain_showers", description: "Rain showers", symbolName: "cloud.rain.fill")
        case 85, 86:
            Mapped(conditionCode: "snow_showers", description: "Snow showers", symbolName: "cloud.snow.fill")
        case 95:
            Mapped(conditionCode: "thunderstorm", description: "Thunderstorm", symbolName: "cloud.bolt.fill")
        case 96, 99:
            Mapped(conditionCode: "thunderstorm_hail", description: "Thunderstorm with hail", symbolName: "cloud.bolt.rain.fill")
        default:
            Mapped(conditionCode: "unknown", description: "Unknown", symbolName: "questionmark.circle")
        }
    }
}
