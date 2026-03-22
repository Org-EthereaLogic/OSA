import Foundation

enum AppTab: String, Hashable, CaseIterable {
    case home
    case library
    case ask
    case inventory
    case checklists
    case quickCards
    case notes
    case settings
    case more

    var title: String {
        switch self {
        case .home: "Home"
        case .library: "Library"
        case .ask: "Ask"
        case .inventory: "Inventory"
        case .checklists: "Checklists"
        case .quickCards: "Quick Cards"
        case .notes: "Notes"
        case .settings: "Settings"
        case .more: "More"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .library: "books.vertical.fill"
        case .ask: "bubble.left.and.text.bubble.right.fill"
        case .inventory: "archivebox.fill"
        case .checklists: "checklist"
        case .quickCards: "bolt.fill"
        case .notes: "note.text"
        case .settings: "gearshape.fill"
        case .more: "ellipsis"
        }
    }
}
