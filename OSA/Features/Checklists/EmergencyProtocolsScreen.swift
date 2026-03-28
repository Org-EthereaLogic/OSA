import SwiftUI

struct EmergencyProtocolsScreen: View {
    @Environment(\.checklistRepository) private var repository
    @State private var templates: [ChecklistTemplateSummary] = []
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("Emergency protocols could not be loaded.")
                )
            } else if templates.isEmpty {
                ContentUnavailableView(
                    "No Protocols Yet",
                    systemImage: "cross.case",
                    description: Text("Reviewed emergency protocols will appear here after seed import.")
                )
            } else {
                List(templates) { template in
                    NavigationLink {
                        ChecklistTemplateDetailView(slug: template.slug)
                    } label: {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(template.title)
                                .font(.cardTitle)
                            Text(template.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.vertical, Spacing.xs)
                        .accessibilityElement(children: .combine)
                    }
                    .listRowBackground(Color.osaSurface)
                    .hapticTap(.prominentNavigation)
                    .accessibilityHint("Opens the emergency protocol details.")
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(.osaBackground)
            }
        }
        .navigationTitle("Emergency Protocols")
        .task { loadTemplates() }
    }

    private func loadTemplates() {
        do {
            templates = try repository?.listTemplates().filter { $0.presentationStyle == .emergencyProtocol } ?? []
        } catch {
            loadFailed = true
        }
    }
}
