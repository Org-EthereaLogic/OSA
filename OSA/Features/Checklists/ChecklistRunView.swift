import SwiftUI

struct ChecklistRunView: View {
    let runID: UUID

    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.checklistRepository) private var repository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var run: ChecklistRun?
    @State private var loadFailed = false
    @State private var showAbandonConfirmation = false
    @State private var recentlyUpdatedItemID: UUID?
    @State private var recentItemResetTask: Task<Void, Never>?
    @State private var sharePayload: ActivitySharePayload?
    @State private var showExportError = false

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
            if run != nil {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        exportRunPDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Export checklist run as PDF")
                    .accessibilityHint("Exports this checklist run as a print-friendly PDF.")

                    if let run, run.status == .inProgress {
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
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(payload: payload)
        }
        .confirmationDialog("Abandon Checklist", isPresented: $showAbandonConfirmation) {
            Button("Abandon", role: .destructive) { abandonRun() }
        } message: {
            Text("This checklist run will be marked as abandoned.")
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This checklist run could not be exported as a PDF.")
        }
        .task { loadRun() }
        .onDisappear {
            recentItemResetTask?.cancel()
        }
    }

    @ViewBuilder
    private func content(_ run: ChecklistRun) -> some View {
        let completedCount = run.items.filter(\.isComplete).count
        let completionPercent = Int(run.completionFraction * 100)

        List {
            Section {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ProgressView(value: run.completionFraction)
                        .tint(run.completionFraction >= 1.0 ? .osaLocal : .osaPrimary)
                        .accessibilityLabel("Checklist progress")
                        .accessibilityValue("\(completionPercent) percent complete")

                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("\(completedCount) of \(run.items.count) complete")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())

                            if run.status == .inProgress, run.completionFraction >= 1.0 {
                                Label("All items checked. Mark complete when you're ready.", systemImage: "flag.checkered.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.osaLocal)
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: Spacing.xxs) {
                            StatusBadge(status: run.status)
                            Text("\(completionPercent)%")
                                .font(.metadataCaption)
                                .foregroundStyle(run.completionFraction >= 1.0 ? .osaLocal : .secondary)
                                .contentTransition(.numericText())
                        }
                    }
                }
                .animation(checklistAnimation, value: run.items.map(\.isComplete))
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
                    RunItemRow(item: item, isRecentlyUpdated: recentlyUpdatedItemID == item.id) {
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
            highlightRecentlyUpdatedItem(item.id)

            let wasFullyComplete = run.items.allSatisfy(\.isComplete)
            let isNowFullyComplete = updatedItems.allSatisfy(\.isComplete)

            if isNowFullyComplete && !wasFullyComplete {
                hapticFeedbackService?.play(.success)
            } else if wasFullyComplete && !isNowFullyComplete {
                hapticFeedbackService?.play(.warning)
            } else {
                hapticFeedbackService?.play(.checklistItemToggle)
            }
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

    private func highlightRecentlyUpdatedItem(_ itemID: UUID) {
        recentItemResetTask?.cancel()
        recentlyUpdatedItemID = itemID

        recentItemResetTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            recentlyUpdatedItemID = nil
        }
    }

    private var checklistAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.18)
    }

    private func exportRunPDF() {
        guard let run else { return }

        do {
            let fileURL = try ChecklistPDFExporter.exportRun(run)
            sharePayload = ActivitySharePayload(
                items: [fileURL],
                subject: run.title
            )
        } catch {
            hapticFeedbackService?.play(.error)
            showExportError = true
        }
    }
}

// MARK: - Run Item Row

private struct RunItemRow: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let item: ChecklistRunItem
    let isRecentlyUpdated: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(alignment: .top, spacing: Spacing.md) {
                Image(systemName: item.isComplete ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isComplete ? .osaLocal : .secondary)
                    .font(.title3)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
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

                Spacer(minLength: 0)

                if item.isComplete {
                    Text("Done")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.osaLocal)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(Color.osaLocal.opacity(0.12), in: Capsule())
                        .accessibilityHidden(true)
                }
            }
            .padding(.vertical, Spacing.sm)
            .padding(.horizontal, Spacing.sm)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.md)
                    .stroke(rowBorder, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(scaleEffect)
        .animation(rowAnimation, value: animationKey)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.text)
        .accessibilityValue(item.isComplete ? "Complete" : "Incomplete")
        .accessibilityHint(item.isComplete ? "Double-tap to mark incomplete." : "Double-tap to mark complete.")
    }

    private var rowBackground: Color {
        if item.isComplete {
            return Color.osaLocal.opacity(0.08)
        }

        return isRecentlyUpdated ? Color.osaPrimary.opacity(0.08) : Color.clear
    }

    private var rowBorder: Color {
        if item.isComplete {
            return .osaLocal.opacity(0.2)
        }

        return isRecentlyUpdated ? .osaPrimary.opacity(0.25) : .osaHairline
    }

    private var scaleEffect: CGFloat {
        guard isRecentlyUpdated, !accessibilityReduceMotion else { return 1 }
        return 1.01
    }

    private var animationKey: String {
        "\(item.id.uuidString)-\(item.isComplete)-\(isRecentlyUpdated)"
    }

    private var rowAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.18)
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
