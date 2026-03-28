import SwiftUI

struct ChecklistTemplateDetailView: View {
    let slug: String

    @Environment(\.checklistRepository) private var repository
    @State private var template: ChecklistTemplate?
    @State private var loadFailed = false
    @State private var showStartConfirmation = false
    @State private var showProtocol = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This template could not be loaded.")
                )
            } else if let template {
                content(template)
            } else {
                ProgressView("Loading\u{2026}")
            }
        }
        .navigationTitle(template?.title ?? "Template")
        .navigationBarTitleDisplayMode(.large)
        .task { loadTemplate() }
        .navigationDestination(isPresented: $showProtocol) {
            if let template {
                EmergencyProtocolView(template: template)
            }
        }
    }

    @ViewBuilder
    private func content(_ template: ChecklistTemplate) -> some View {
        List {
            Section {
                Text(template.description)
                    .font(.body)
                    .foregroundStyle(.secondary)

                LabeledContent("Category") {
                    Text(template.category.capitalized.replacingOccurrences(of: "-", with: " "))
                }
                LabeledContent("Estimated Time") {
                    Text("\(template.estimatedMinutes) minutes")
                }
                LabeledContent("Items", value: "\(template.items.count)")
                LabeledContent("Style") {
                    Text(template.presentationStyle == .emergencyProtocol ? "Emergency Protocol" : "Checklist")
                }
            }

            Section("Items") {
                ForEach(template.items) { item in
                    TemplateItemRow(item: item)
                }
            }

            Section {
                Button {
                    if template.presentationStyle == .emergencyProtocol {
                        showProtocol = true
                    } else {
                        startRun(from: template)
                    }
                } label: {
                    Label(
                        template.presentationStyle == .emergencyProtocol ? "Open Protocol" : "Start Checklist",
                        systemImage: template.presentationStyle == .emergencyProtocol ? "cross.case.fill" : "play.fill"
                    )
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets(top: Spacing.sm, leading: Spacing.lg, bottom: Spacing.sm, trailing: Spacing.lg))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(.osaBackground)
    }

    private func loadTemplate() {
        do {
            template = try repository?.template(slug: slug)
            if template == nil { loadFailed = true }
        } catch {
            loadFailed = true
        }
    }

    private func startRun(from template: ChecklistTemplate) {
        do {
            let run = try repository?.startRun(
                from: template.id,
                title: template.title,
                contextNote: nil
            )
            if run != nil {
                // Navigation to run view will happen via the active runs list
                loadTemplate()
            }
        } catch {
            loadFailed = true
        }
    }
}

private struct TemplateItemRow: View {
    let item: ChecklistTemplateItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Image(systemName: "circle")
                    .foregroundStyle(.tertiary)
                    .font(.caption)

                Text(item.text)
                    .font(.body)

                if item.isOptional {
                    Text("Optional")
                        .font(.caption2)
                        .padding(.horizontal, Spacing.xs)
                        .padding(.vertical, Spacing.xxs)
                        .background(.secondary.opacity(0.15), in: Capsule())
                        .foregroundStyle(.secondary)
                }
            }

            if let detail = item.detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, Spacing.xl)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChecklistTemplateDetailView(slug: "sample")
    }
}
