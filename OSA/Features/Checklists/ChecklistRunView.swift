import SwiftUI

struct ChecklistRunView: View {
    let runID: UUID

    @Environment(\.checklistRepository) private var repository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var run: ChecklistRun?
    @State private var loadFailed = false
    @State private var showAbandonConfirmation = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This checklist could not be loaded.")
                )
            } else if let run {
                content(run)
            } else {
                ProgressView("Loading\u{2026}")
            }
        }
        .navigationTitle(run?.title ?? "Checklist")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let run, run.status == .inProgress {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            completeRun()
                        } label: {
                            Label("Mark Complete", systemImage: "checkmark.circle.fill")
                        }

                        Button(role: .destructive) {
                            showAbandonConfirmation = true
                        } label: {
                            Label("Abandon", systemImage: "xmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Checklist actions")
                    .accessibilityHint("Shows actions for this checklist run.")
                }
            }
        }
        .confirmationDialog("Abandon Checklist", isPresented: $showAbandonConfirmation) {
            Button("Abandon", role: .destructive) { abandonRun() }
        } message: {
            Text("This checklist run will be marked as abandoned.")
        }
        .task { loadRun() }
    }

    @ViewBuilder
    private func content(_ run: ChecklistRun) -> some View {
        List {
            Section {
                ProgressView(value: run.completionFraction)
                    .tint(run.completionFraction >= 1.0 ? .osaLocal : .osaPrimary)
                    .accessibilityLabel("Checklist progress")
                    .accessibilityValue("\(Int(run.completionFraction * 100)) percent complete")

                HStack {
                    Text("\(run.items.filter(\.isComplete).count) of \(run.items.count) complete")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    StatusBadge(status: run.status)
                }
            }

            if let note = run.contextNote, !note.isEmpty {
                Section("Context") {
                    Text(note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Items") {
                ForEach(run.items) { item in
                    RunItemRow(item: item) {
                        toggleItem(item, in: run)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
    }

    private func loadRun() {
        do {
            run = try repository?.run(id: runID)
            if run == nil { loadFailed = true }
        } catch {
            loadFailed = true
        }
    }

    private func toggleItem(_ item: ChecklistRunItem, in run: ChecklistRun) {
        let now = Date()
        let updatedItems = run.items.map { existing -> ChecklistRunItem in
            guard existing.id == item.id else { return existing }
            return ChecklistRunItem(
                id: existing.id,
                runID: existing.runID,
                templateItemID: existing.templateItemID,
                text: existing.text,
                isComplete: !existing.isComplete,
                completedAt: !existing.isComplete ? now : nil,
                sortOrder: existing.sortOrder
            )
        }

        let updatedRun = ChecklistRun(
            id: run.id,
            templateID: run.templateID,
            title: run.title,
            startedAt: run.startedAt,
            completedAt: run.completedAt,
            status: run.status,
            contextNote: run.contextNote,
            items: updatedItems
        )

        do {
            try repository?.updateRun(updatedRun)
            self.run = updatedRun
            hapticFeedbackService?.play(.checklistItemToggle)
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }

    private func completeRun() {
        guard var current = run else { return }
        current.status = .completed
        current.completedAt = Date()

        let completedRun = ChecklistRun(
            id: current.id,
            templateID: current.templateID,
            title: current.title,
            startedAt: current.startedAt,
            completedAt: current.completedAt,
            status: .completed,
            contextNote: current.contextNote,
            items: current.items
        )

        do {
            try repository?.updateRun(completedRun)
            self.run = completedRun
            hapticFeedbackService?.play(.success)
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }

    private func abandonRun() {
        guard let current = run else { return }

        let abandonedRun = ChecklistRun(
            id: current.id,
            templateID: current.templateID,
            title: current.title,
            startedAt: current.startedAt,
            completedAt: Date(),
            status: .abandoned,
            contextNote: current.contextNote,
            items: current.items
        )

        do {
            try repository?.updateRun(abandonedRun)
            hapticFeedbackService?.play(.warning)
            dismiss()
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }
}

// MARK: - Run Item Row

private struct RunItemRow: View {
    let item: ChecklistRunItem
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isComplete ? .osaLocal : .secondary)
                    .font(.title3)
                    .accessibilityHidden(true)

                VStack(alignment: .leading) {
                    Text(item.text)
                        .font(.body)
                        .strikethrough(item.isComplete)
                        .foregroundStyle(item.isComplete ? .secondary : .primary)

                    if let completed = item.completedAt {
                        Text("Completed \(completed.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.text)
        .accessibilityValue(item.isComplete ? "Complete" : "Incomplete")
        .accessibilityHint(item.isComplete ? "Double-tap to mark incomplete." : "Double-tap to mark complete.")
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: ChecklistRunStatus

    var body: some View {
        Text(label)
            .font(.caption2)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xxs)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var label: String {
        switch status {
        case .inProgress: "In Progress"
        case .completed: "Completed"
        case .abandoned: "Abandoned"
        }
    }

    private var color: Color {
        switch status {
        case .inProgress: .osaPrimary
        case .completed: .osaLocal
        case .abandoned: .secondary
        }
    }
}

#Preview {
    NavigationStack {
        ChecklistRunView(runID: UUID())
    }
}
