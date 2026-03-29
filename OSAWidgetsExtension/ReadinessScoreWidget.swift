import SwiftUI
import WidgetKit

struct ReadinessScoreWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "ReadinessScoreWidget",
            provider: SharedSnapshotTimelineProvider()
        ) { entry in
            ReadinessScoreWidgetView(entry: entry)
        }
        .configurationDisplayName("Readiness Score")
        .description("Shows your current supply readiness and the biggest local gap.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

private struct ReadinessScoreWidgetView: View {
    let entry: SharedSnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryInline:
                inlineView
            case .accessoryRectangular:
                rectangularView
            default:
                smallView
            }
        }
        .widgetCardBackground()
    }

    private var inlineView: some View {
        if let readiness = entry.snapshot.readiness {
            return Text("\(readiness.title): \(readiness.readinessPercent)%")
        }
        return Text("Readiness unavailable")
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let readiness = entry.snapshot.readiness {
                Text("Readiness")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(readiness.readinessPercent)%")
                    .font(.title3.weight(.bold))
                Text(readiness.missingCriticalCount == 0
                    ? "Critical supplies covered"
                    : "\(readiness.missingCriticalCount) critical gaps")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Readiness")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("No inventory yet")
                    .font(.headline)
                Text("Add local inventory to calculate readiness.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Readiness")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let readiness = entry.snapshot.readiness {
                Text("\(readiness.readinessPercent)%")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text(readiness.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label("\(readiness.missingCriticalCount)", systemImage: "exclamationmark.triangle.fill")
                    Label("\(readiness.nearExpiryCount)", systemImage: "calendar")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            } else {
                Spacer()
                Text("No inventory yet")
                    .font(.headline)
                Text("Track supplies to see your score here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
