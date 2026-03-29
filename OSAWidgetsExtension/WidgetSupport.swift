import SwiftUI
import WidgetKit

struct SharedSnapshotEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct SharedSnapshotTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> SharedSnapshotEntry {
        SharedSnapshotEntry(
            date: Date(),
            snapshot: .placeholder
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SharedSnapshotEntry) -> Void) {
        completion(makeEntry(isPreview: context.isPreview))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SharedSnapshotEntry>) -> Void) {
        let entry = makeEntry(isPreview: context.isPreview)
        completion(
            Timeline(
                entries: [entry],
                policy: .after(nextRefreshDate(after: entry.date))
            )
        )
    }

    private func makeEntry(isPreview: Bool) -> SharedSnapshotEntry {
        let snapshot: WidgetSnapshot
        if isPreview {
            snapshot = .placeholder
        } else {
            snapshot = WidgetSnapshotStore()?.load() ?? .empty
        }

        return SharedSnapshotEntry(
            date: Date(),
            snapshot: snapshot
        )
    }

    private func nextRefreshDate(after date: Date) -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: date) ?? date.addingTimeInterval(86_400)
        return calendar.startOfDay(for: tomorrow).addingTimeInterval(300)
    }
}

extension View {
    func widgetCardBackground() -> some View {
        containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.93, blue: 0.88),
                    Color(red: 0.88, green: 0.92, blue: 0.87)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
