import Foundation
import Observation

/// Represents the currently visible reading content in the app.
///
/// Only handbook sections and quick cards are published in this phase.
/// Notes, inventory, checklists, and imported knowledge remain excluded
/// for privacy and scope reasons.
enum OnscreenContent: Equatable, Sendable {
    case quickCard(id: UUID, title: String, category: String)
    case handbookSection(id: UUID, heading: String, chapterTitle: String)
}

/// App-owned manager that tracks the currently visible reading content
/// for Siri follow-up context.
///
/// Publishing and clearing are driven by the reading views themselves.
/// This manager does not observe navigation state — it receives explicit
/// updates when content loads and explicit clears when views disappear.
@MainActor
@Observable
final class OnscreenContentManager {
    private(set) var currentContent: OnscreenContent?

    func publishQuickCard(id: UUID, title: String, category: String) {
        currentContent = .quickCard(id: id, title: title, category: category)
    }

    func publishHandbookSection(id: UUID, heading: String, chapterTitle: String) {
        currentContent = .handbookSection(id: id, heading: heading, chapterTitle: chapterTitle)
    }

    func clear() {
        currentContent = nil
    }
}
