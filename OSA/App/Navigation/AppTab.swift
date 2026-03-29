import Foundation

enum AppTab: String, Hashable, CaseIterable {
    case home
    case library
    case ask
    case inventory
    case maps
    case tools
    case checklists
    case quickCards
    case weather
    case notes
    case settings
    case more

    var title: String {
        switch self {
        case .home: "Home"
        case .library: "Library"
        case .ask: "Ask"
        case .inventory: "Inventory"
        case .maps: "Map"
        case .tools: "Tools"
        case .checklists: "Checklists"
        case .quickCards: "Quick Cards"
        case .weather: "Weather"
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
        case .maps: "map.fill"
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
