import SwiftUI
import WidgetKit

struct RotatingTipWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: "RotatingTipWidget",
            provider: SharedSnapshotTimelineProvider()
        ) { entry in
            RotatingTipWidgetView(entry: entry)
        }
        .configurationDisplayName("Preparedness Tip")
        .description("Rotates through approved local quick-card tips and opens the matching card.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

private struct RotatingTipWidgetView: View {
    let entry: SharedSnapshotEntry
    @Environment(\.widgetFamily) private var family

    private var tip: WidgetSnapshot.TipSummary? {
        entry.snapshot.rotatingTip(for: entry.date)
    }

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumView
            case .accessoryRectangular:
                rectangularView
            default:
                smallView
            }
        }
        .widgetCardBackground()
        .widgetURL(tip.map { SystemSurfaceDeepLink.quickCard($0.quickCardID).url })
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Quick Tip")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let tip {
                Text(tip.title)
                    .font(.headline)
                    .lineLimit(1)
                Text(tip.excerpt)
                    .font(.caption2)
                    .lineLimit(2)
            } else {
                Text("No quick cards yet")
                    .font(.headline)
                Text("Approved local quick-card tips will appear here.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Tip")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let tip {
                Text(tip.title)
                    .font(.title3.weight(.semibold))
                    .lineLimit(3)
                Spacer()
                Text(tip.excerpt)
                    .font(.caption)
                    .lineLimit(4)
                    .foregroundStyle(.secondary)
            } else {
                Spacer()
                Text("No quick cards yet")
                    .font(.headline)
                Text("Quick-card tips stay local and show up here after seed import.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Preparedness Tip")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let tip {
                    Text(tip.title)
                        .font(.title3.weight(.bold))
                        .lineLimit(2)
                    Text(tip.excerpt)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(4)
                } else {
                    Text("No quick cards yet")
                        .font(.headline)
                    Text("Local quick-card tips will appear here after seed content is ready.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
