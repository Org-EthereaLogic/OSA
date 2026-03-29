import SwiftUI

struct ChecklistsScreen: View {
    @Environment(\.checklistRepository) private var repository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var templates: [ChecklistTemplateSummary] = []
    @State private var templateDetails: [UUID: ChecklistTemplate] = [:]
    @State private var activeRuns: [ChecklistRun] = []
    @State private var loadFailed = false
    @State private var searchText = ""
    @State private var showingCreateAdhoc = false
    @State private var runPendingDeletion: ChecklistRun?

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Checklists could not be loaded. Try restarting the app.")
                )
            } else if templates.isEmpty && activeRuns.isEmpty {
                zeroStateView
            } else if filteredTemplates.isEmpty && filteredRuns.isEmpty {
                noResultsView
            } else {
                list
            }
        }
        .navigationTitle("Checklists")
        .searchable(text: $searchText, prompt: "Search checklists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateAdhoc = true
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Add checklist")
                .accessibilityHint("Creates a new ad hoc checklist.")
            }
        }
        .confirmationDialog("Delete Active Run", isPresented: runDeletionBinding) {
            Button("Delete Run", role: .destructive) {
                deletePendingRun()
            }
        } message: {
            Text("This removes the active checklist run from the list.")
        }
        .sheet(isPresented: $showingCreateAdhoc) {
            NavigationStack {
                CreateChecklistView { run in
                    try repository?.createRun(run)
                    loadContent()
                }
            }
        }
        .task { loadContent() }
    }

    private var list: some View {
        List {
            if !filteredRuns.isEmpty {
                Section {
                    ForEach(filteredRuns) { run in
                        NavigationLink {
                            ChecklistRunView(runID: run.id)
                        } label: {
                            ActiveRunRow(run: run)
                        }
                        .listRowBackground(Color.osaSurface)
                        .hapticTap(.prominentNavigation)
                        .accessibilityHint("Opens the active checklist run.")
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                runPendingDeletion = run
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Label("Active", systemImage: "play.circle.fill")
                }
            }

            if !filteredTemplates.isEmpty {
                let protocolTemplates = filteredTemplates.filter { $0.presentationStyle == .emergencyProtocol }
                let standardTemplates = filteredTemplates.filter { $0.presentationStyle == .standard }

                if !protocolTemplates.isEmpty {
                    Section {
                        ForEach(protocolTemplates) { template in
                            NavigationLink {
                                ChecklistTemplateDetailView(slug: template.slug)
                            } label: {
                                TemplateRow(template: template)
                            }
                            .listRowBackground(Color.osaSurface)
                            .hapticTap(.prominentNavigation)
                            .accessibilityHint("Opens the emergency protocol details.")
                        }
                    } header: {
                        Label("Emergency Protocols", systemImage: "cross.case.fill")
                    }
                }

                let grouped = Dictionary(grouping: standardTemplates) { $0.category }
                let sortedCategories = grouped.keys.sorted()

                ForEach(sortedCategories, id: \.self) { category in
                    Section {
                        ForEach(grouped[category] ?? []) { template in
                            NavigationLink {
                                ChecklistTemplateDetailView(slug: template.slug)
                            } label: {
                                TemplateRow(template: template)
                            }
                            .listRowBackground(Color.osaSurface)
                            .hapticTap(.prominentNavigation)
                            .accessibilityHint("Opens the checklist template.")
                            .swipeActions(edge: .leading, allowsFullSwipe: false) {
                                Button {
                                    startRun(from: template)
                                } label: {
                                    Label("Start", systemImage: "play.fill")
                                }
                                .tint(.osaPrimary)
                            }
                        }
                    } header: {
                        Text(category.capitalized.replacingOccurrences(of: "-", with: " "))
                    }
                }
            }

            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                NavigationLink {
                    ChecklistRunHistoryView()
                } label: {
                    Label("Run History", systemImage: "clock.arrow.circlepath")
                        .foregroundStyle(.secondary)
                }
                .listRowBackground(Color.osaSurface)
                .accessibilityHint("Opens completed and abandoned checklist runs.")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
    }

    private var filteredTemplates: [ChecklistTemplateSummary] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return templates }

        return templates.filter { template in
            [template.title, template.description, template.category]
                .contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
                || template.tags.contains(where: { $0.localizedCaseInsensitiveContains(trimmed) })
                || templateDetails[template.id]?.items.contains(where: { item in
                    item.text.localizedCaseInsensitiveContains(trimmed)
                        || (item.detail?.localizedCaseInsensitiveContains(trimmed) ?? false)
                }) == true
        }
    }

    private var filteredRuns: [ChecklistRun] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return activeRuns }

        return activeRuns.filter { run in
            run.title.localizedCaseInsensitiveContains(trimmed)
                || (run.contextNote?.localizedCaseInsensitiveContains(trimmed) ?? false)
        }
    }

    private var zeroStateView: some View {
        ContentUnavailableView {
            Label("No Checklists Yet", systemImage: "checklist")
        } description: {
            Text("Start from seeded templates when available, or create an ad hoc checklist for drills, trips, and supply reviews.")
        } actions: {
            Button("Create Ad Hoc Checklist") {
                showingCreateAdhoc = true
            }
        }
    }

    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Matching Checklists", systemImage: "magnifyingglass")
        } description: {
            Text("No active runs or templates match \"\(searchText)\". Try words like water, outage, family, or kit.")
        } actions: {
            Button("Clear Search") {
                searchText = ""
            }
        }
    }

    private func loadContent() {
        do {
            let loadedTemplates = try repository?.listTemplates() ?? []
            templates = loadedTemplates

            if let repository {
                templateDetails = try Dictionary(
                    uniqueKeysWithValues: loadedTemplates.compactMap { template in
                        guard let detail = try repository.template(id: template.id) else {
                            return nil
                        }
                        return (template.id, detail)
                    }
                )
            } else {
                templateDetails = [:]
            }

            activeRuns = try repository?.activeRuns() ?? []
            loadFailed = false
        } catch {
            loadFailed = true
        }
    }

    private func startRun(from template: ChecklistTemplateSummary) {
        do {
            _ = try repository?.startRun(from: template.id, title: template.title, contextNote: nil)
            hapticFeedbackService?.play(.prominentNavigation)
            loadContent()
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }

    private func deletePendingRun() {
        guard let runPendingDeletion else { return }

        do {
            try repository?.deleteRun(id: runPendingDeletion.id)
            hapticFeedbackService?.play(.warning)
            self.runPendingDeletion = nil
            loadContent()
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }

    private var runDeletionBinding: Binding<Bool> {
        Binding(
            get: { runPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    runPendingDeletion = nil
                }
            }
        )
    }
}

// MARK: - Active Run Row

private struct ActiveRunRow: View {
    let run: ChecklistRun

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(run.title)
                .font(.cardTitle)

            HStack(spacing: Spacing.sm) {
                ProgressView(value: run.completionFraction)
                    .tint(.osaCalm)
                    .frame(maxWidth: 120)
                    .accessibilityLabel("Checklist progress")
                    .accessibilityValue("\(Int(run.completionFraction * 100)) percent complete")

                Text("\(Int(run.completionFraction * 100))%")
                    .font(.categoryLabel)
                    .foregroundStyle(.secondary)
            }

            Text("Started \(run.startedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.metadataCaption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(run.title)
        .accessibilityValue("\(run.items.filter(\.isComplete).count) of \(run.items.count) complete. \(Int(run.completionFraction * 100)) percent.")
    }
}

// MARK: - Template Row

private struct TemplateRow: View {
    let template: ChecklistTemplateSummary

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(template.title)
                .font(.cardTitle)

            Text(template.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            HStack(spacing: Spacing.sm) {
                Label("\(template.itemCount) items", systemImage: "list.bullet")
                    .font(.metadataCaption)
                    .foregroundStyle(.tertiary)

                Label("\(template.estimatedMinutes) min", systemImage: "clock")
                    .font(.metadataCaption)
                    .foregroundStyle(.tertiary)

                if template.presentationStyle == .emergencyProtocol {
                    Label("Protocol", systemImage: "cross.case.fill")
                        .font(.metadataCaption)
                        .foregroundStyle(.osaEmergency)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ChecklistsScreen()
    }
}
