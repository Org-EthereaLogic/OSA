import SwiftUI

struct WeatherAlertRow: View {
    let alert: WeatherAlert
    @Environment(\.openURL) private var openURL

    var body: some View {
        Button { openURL(alert.alertURL) } label: {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: severityIcon)
                    .font(.body)
                    .foregroundStyle(severityColor)
                    .frame(width: 30, height: 30)
                    .background(severityColor.opacity(0.12),
                               in: RoundedRectangle(cornerRadius: CornerRadius.sm))

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(alert.title)
                        .font(.cardTitle)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    if !alert.areaDescription.isEmpty {
                        Text(alert.areaDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    if let expires = alert.expiresDate {
                        Text("Expires \(expires, style: .relative)")
                            .font(.metadataCaption)
                            .foregroundStyle(.tertiary)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.md)
            .background(
                severityColor.opacity(0.06),
                in: RoundedRectangle(cornerRadius: CornerRadius.md)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(severityColor.opacity(0.2), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var severityIcon: String {
        switch alert.severity {
        case .extreme: "exclamationmark.triangle.fill"
        case .severe: "exclamationmark.triangle.fill"
        case .moderate: "exclamationmark.circle.fill"
        case .minor: "info.circle.fill"
        case .unknown: "info.circle"
        }
    }

    private var severityColor: Color {
        switch alert.severity {
        case .extreme, .severe: .osaEmergency
        case .moderate: .osaWarning
        case .minor, .unknown: .osaCalm
        }
    }
}
