import SwiftUI

struct WeatherForecastRow: View {
    let forecast: DailyForecast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilityLayout
            } else {
                compactLayout
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(dayName) forecast")
        .accessibilityValue(accessibilityValue)
    }

    private var compactLayout: some View {
        HStack(spacing: Spacing.md) {
            Text(dayName)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 44, alignment: .leading)

            Image(systemName: forecast.symbolName)
                .font(.title3)
                .symbolRenderingMode(.multicolor)
                .frame(width: 30)

            Spacer()

            if forecast.precipitationChance > 0 {
                HStack(spacing: Spacing.xxs) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundStyle(.osaCalm)
                    Text("\(Int(forecast.precipitationChance * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 50)
            } else {
                Spacer()
                    .frame(width: 50)
            }

            Text(formatTemperature(forecast.lowTemperature))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .trailing)

            temperatureBar

            Text(formatTemperature(forecast.highTemperature))
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 40, alignment: .trailing)
        }
    }

    private var accessibilityLayout: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: forecast.symbolName)
                    .font(.title3)
                    .symbolRenderingMode(.multicolor)
                Text(dayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            HStack(spacing: Spacing.md) {
                Text("Low \(formatTemperature(forecast.lowTemperature))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("High \(formatTemperature(forecast.highTemperature))")
                    .font(.subheadline)
                    .fontWeight(.medium)
                if forecast.precipitationChance > 0 {
                    HStack(spacing: Spacing.xxs) {
                        Image(systemName: "drop.fill")
                            .font(.caption2)
                            .foregroundStyle(.osaCalm)
                        Text("\(Int(forecast.precipitationChance * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        if Calendar.current.isDateInToday(forecast.date) {
            return "Today"
        }
        return formatter.string(from: forecast.date)
    }

    private var temperatureBar: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(
                LinearGradient(
                    colors: [.osaCalm, .osaPrimary],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: 40, height: 4)
    }

    private func formatTemperature(_ celsius: Double) -> String {
        let measurement = Measurement(value: celsius, unit: UnitTemperature.celsius)
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        return formatter.string(from: measurement)
    }

    private var accessibilityValue: String {
        let precipitation = Int(forecast.precipitationChance * 100)
        return "Low \(formatTemperature(forecast.lowTemperature)). High \(formatTemperature(forecast.highTemperature)). Precipitation chance \(precipitation) percent."
    }
}
