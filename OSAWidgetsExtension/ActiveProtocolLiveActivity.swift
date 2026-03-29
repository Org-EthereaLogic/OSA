import ActivityKit
import SwiftUI
import WidgetKit

struct ActiveProtocolLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ActiveProtocolActivityAttributes.self) { context in
            VStack(alignment: .leading, spacing: 12) {
                Text(context.attributes.protocolTitle)
                    .font(.headline)
                    .lineLimit(2)

                ProgressView(value: Double(context.state.completionPercent), total: 100)

                HStack {
                    Text("\(context.state.completedStepCount) of \(context.state.totalStepCount) complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(context.state.completionPercent)%")
                        .font(.caption.weight(.semibold))
                }

                if let nextStep = context.state.nextStepLabel {
                    Text("Next: \(nextStep)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding()
            .activityBackgroundTint(Color(.systemBackground))
            .activitySystemActionForegroundColor(.primary)
            .widgetURL(SystemSurfaceDeepLink.checklistRun(context.attributes.runID).url)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protocol")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(context.attributes.protocolTitle)
                            .font(.headline)
                            .lineLimit(2)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(context.state.completionPercent)%")
                        .font(.title3.weight(.bold))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        ProgressView(value: Double(context.state.completionPercent), total: 100)
                        if let nextStep = context.state.nextStepLabel {
                            Text("Next: \(nextStep)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        } else {
                            Text("\(context.state.completedStepCount) of \(context.state.totalStepCount) steps complete")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(.red)
            } compactTrailing: {
                Text("\(context.state.completionPercent)%")
                    .font(.caption2.weight(.bold))
            } minimal: {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(.red)
            }
            .widgetURL(SystemSurfaceDeepLink.checklistRun(context.attributes.runID).url)
        }
    }
}
