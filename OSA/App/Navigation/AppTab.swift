import Foundation

enum AppTab: String, Hashable, CaseIterable {
    case home
    case library
    case ask
    case inventory
    case maps
    case documents
    case tools
    case checklists
    case quickCards
    case weather
    case notes
    case settings
    case more

    var title: String {
        switch self {
        case .home: AppLocalization.localized("Home")
        case .library: AppLocalization.localized("Library")
        case .ask: AppLocalization.localized("Ask")
        case .inventory: AppLocalization.localized("Inventory")
        case .maps: AppLocalization.localized("Map")
        case .documents: AppLocalization.localized("Document Vault")
        case .tools: AppLocalization.localized("Tools")
        case .checklists: AppLocalization.localized("Checklists")
        case .quickCards: AppLocalization.localized("Quick Cards")
        case .weather: AppLocalization.localized("Weather")
        case .notes: AppLocalization.localized("Notes")
        case .settings: AppLocalization.localized("Settings")
        case .more: AppLocalization.localized("More")
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .library: "books.vertical.fill"
        case .ask: "bubble.left.and.text.bubble.right.fill"
        case .inventory: "archivebox.fill"
        case .maps: "map.fill"
        case .documents: "lock.doc.fill"
        case .tools: "flashlight.on.fill"
        case .checklists: "checklist"
        case .quickCards: "bolt.fill"
        case .weather: "cloud.sun.fill"
        case .notes: "note.text"
        case .settings: "gearshape.fill"
        case .more: "ellipsis"
        }
    }
}
