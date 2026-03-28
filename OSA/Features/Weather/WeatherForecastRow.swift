import SwiftUI

struct WeatherForecastRow: View {
    let forecast: DailyForecast

    var body: some View {
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
        .padding(.vertical, Spacing.xs)
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
}
