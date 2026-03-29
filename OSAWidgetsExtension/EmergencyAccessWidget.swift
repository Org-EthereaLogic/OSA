import SwiftUI
import WidgetKit

struct EmergencyAccessWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "EmergencyAccessWidget",
            provider: SharedSnapshotTimelineProvider()
        ) { entry in
            EmergencyAccessWidgetView(entry: entry)
        }
        .configurationDisplayName("Emergency Access")
        .description("Opens Emergency Mode directly from the Lock Screen or Home Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

private struct EmergencyAccessWidgetView: View {
    let entry: SharedSnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                circularView
            case .accessoryInline:
                Text("Emergency Mode")
            default:
                rectangularView
            }
        }
        .widgetCardBackground()
        .widgetURL(entry.snapshot.emergencyAction.destinationURL)
    }

    private var circularView: some View {
        ZStack {
            Circle()
                .fill(Color.red.opacity(0.16))
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.red)
        }
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(entry.snapshot.emergencyAction.title)
                .font(.headline)
            Text(entry.snapshot.emergencyAction.subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
