import SwiftUI

struct ChecklistTemplateRouteView: View {
    let templateID: UUID

    @Environment(\.checklistRepository) private var repository
    @State private var slug: String?
    @State private var loadFailed = false

    var body: some View {
        Group {
            if let slug {
                ChecklistTemplateDetailView(slug: slug)
            } else if loadFailed {
                ContentUnavailableView(
                    "Unable to Load",
                    systemImage: "exclamationmark.triangle",
                    description: Text("This checklist could not be loaded.")
                )
            } else {
                ProgressView("Loading...")
            }
        }
        .task { loadTemplate() }
    }

    private func loadTemplate() {
        do {
            slug = try repository?.template(id: templateID)?.slug
            loadFailed = slug == nil
        } catch {
            loadFailed = true
        }
    }
}
