import SwiftUI

struct ChecklistTemplateDetailView: View {
    let slug: String

    @Environment(\.checklistRepository) private var repository
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var template: ChecklistTemplate?
    @State private var loadFailed = false
    @State private var showStartConfirmation = false
    @State private var showProtocol = false
    @State private var sharePayload: ActivitySharePayload?
    @State private var showExportError = false

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
        .toolbar {
            if template != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        exportTemplatePDF()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Export checklist template as PDF")
                    .accessibilityHint("Exports this checklist template as a print-friendly PDF.")
                }
            }
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(payload: payload)
        }
        .alert("Export Failed", isPresented: $showExportError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This checklist template could not be exported as a PDF.")
        }
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
                        hapticFeedbackService?.play(.emergencyPrimaryAction)
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
                .accessibilityHint(
                    template.presentationStyle == .emergencyProtocol
                        ? "Opens the protocol in large-step mode."
                        : "Starts a new checklist run."
                )
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
                hapticFeedbackService?.play(.prominentNavigation)
                // Navigation to run view will happen via the active runs list
                loadTemplate()
            }
        } catch {
            hapticFeedbackService?.play(.error)
            loadFailed = true
        }
    }

    private func exportTemplatePDF() {
        guard let template else { return }

        do {
            let fileURL = try ChecklistPDFExporter.exportTemplate(template)
            sharePayload = ActivitySharePayload(
                items: [fileURL],
                subject: template.title
            )
        } catch {
            hapticFeedbackService?.play(.error)
            showExportError = true
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
                    .accessibilityHidden(true)

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
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ChecklistTemplateDetailView(slug: "sample")
    }
}
