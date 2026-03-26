import SwiftUI

struct ChecklistsScreen: View {
    @Environment(\.checklistRepository) private var repository
    @State private var templates: [ChecklistTemplateSummary] = []
    @State private var activeRuns: [ChecklistRun] = []
    @State private var loadFailed = false
    @State private var showingCreateAdhoc = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Checklists could not be loaded. Try restarting the app.")
                )
            } else if templates.isEmpty && activeRuns.isEmpty {
                ContentUnavailableView(
                    "No Checklists Yet",
                    systemImage: "checklist",
                    description: Text("Checklist templates will appear here once seed content is imported.")
                )
            } else {
                list
            }
        }
        .navigationTitle("Checklists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingCreateAdhoc = true
                } label: {
                    Image(systemName: "plus")
                }
            }
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
            if !activeRuns.isEmpty {
                Section {
                    ForEach(activeRuns) { run in
                        NavigationLink {
                            ChecklistRunView(runID: run.id)
                        } label: {
                            ActiveRunRow(run: run)
                        }
                    }
                } header: {
                    Label("Active", systemImage: "play.circle.fill")
                }
            }

            if !templates.isEmpty {
                let grouped = Dictionary(grouping: templates) { $0.category }
                let sortedCategories = grouped.keys.sorted()

                ForEach(sortedCategories, id: \.self) { category in
                    Section {
                        ForEach(grouped[category] ?? []) { template in
                            NavigationLink {
                                ChecklistTemplateDetailView(slug: template.slug)
                            } label: {
                                TemplateRow(template: template)
                            }
                        }
                    } header: {
                        Text(category.capitalized.replacingOccurrences(of: "-", with: " "))
                    }
                }
            }

            NavigationLink {
                ChecklistRunHistoryView()
            } label: {
                Label("Run History", systemImage: "clock.arrow.circlepath")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func loadContent() {
        do {
            templates = try repository?.listTemplates() ?? []
            activeRuns = try repository?.activeRuns() ?? []
        } catch {
            loadFailed = true
        }
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

                Text("\(Int(run.completionFraction * 100))%")
                    .font(.categoryLabel)
                    .foregroundStyle(.secondary)
            }

            Text("Started \(run.startedAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.metadataCaption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, Spacing.xs)
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
            }
        }
        .padding(.vertical, Spacing.xs)
    }
}

#Preview {
    NavigationStack {
        ChecklistsScreen()
    }
}
