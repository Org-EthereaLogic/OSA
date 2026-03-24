import SwiftUI

struct ChecklistRunHistoryView: View {
    @Environment(\.checklistRepository) private var repository
    @State private var runs: [ChecklistRun] = []
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Run history could not be loaded.")
                )
            } else if runs.isEmpty {
                ContentUnavailableView(
                    "No History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Completed and abandoned checklists will appear here.")
                )
            } else {
                List(runs) { run in
                    NavigationLink {
                        ChecklistRunView(runID: run.id)
                    } label: {
                        HistoryRow(run: run)
                    }
                }
            }
        }
        .navigationTitle("Run History")
        .task { loadRuns() }
    }

    private func loadRuns() {
        do {
            let all = try repository?.listRuns(status: nil) ?? []
            runs = all.filter { $0.status != .inProgress }
        } catch {
            loadFailed = true
        }
    }
}

private struct HistoryRow: View {
    let run: ChecklistRun

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(run.title)
                    .font(.headline)

                Spacer()

                Text(run.status == .completed ? "Completed" : "Abandoned")
                    .font(.caption2)
                    .foregroundStyle(run.status == .completed ? .green : .secondary)
            }

            HStack(spacing: Spacing.sm) {
                Text("\(run.items.filter(\.isComplete).count)/\(run.items.count) items")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let completed = run.completedAt {
                    Text(completed.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        ChecklistRunHistoryView()
    }
}
