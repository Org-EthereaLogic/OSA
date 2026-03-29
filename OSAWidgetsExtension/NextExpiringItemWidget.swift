import SwiftUI
import WidgetKit

struct NextExpiringItemWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "NextExpiringItemWidget",
            provider: SharedSnapshotTimelineProvider()
        ) { entry in
            NextExpiringItemWidgetView(entry: entry)
        }
        .configurationDisplayName("Next Expiring Item")
        .description("Keeps the nearest local expiry visible on the Home Screen or Lock Screen.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

private struct NextExpiringItemWidgetView: View {
    let entry: SharedSnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                rectangularView
            default:
                smallView
            }
        }
        .widgetCardBackground()
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Next Expiry")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let item = entry.snapshot.nextExpiringItem {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(item.dateSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(item.categoryTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Nothing expiring soon")
                    .font(.headline)
                Text("Tracked local expiry items will appear here.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Next Expiry")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let item = entry.snapshot.nextExpiringItem {
                Text(item.name)
                    .font(.title3.weight(.semibold))
                    .lineLimit(3)
                Spacer()
                Text(item.dateSummary)
                    .font(.headline)
                Text(item.categoryTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Spacer()
                Text("Nothing expiring soon")
                    .font(.headline)
                Text("Expiry tracking stays local and appears here when needed.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
