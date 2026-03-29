import Foundation

enum SpotlightMode: String, CaseIterable, Identifiable {
    case quickCards
    case feed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quickCards: "Quick Cards"
        case .feed: "Feed"
        }
    }

    var icon: String {
        switch self {
        case .quickCards: "bolt.fill"
        case .feed: "antenna.radiowaves.left.and.right"
        }
    }
}

enum HomeFeedItem: Identifiable {
    case article(DiscoveredArticle)
    case weatherAlert(WeatherAlert)

    var id: String {
        switch self {
        case .article(let article):
            "article-\(article.articleURL.absoluteString)"
        case .weatherAlert(let alert):
            "alert-\(alert.id.uuidString)"
        }
    }

    var sortDate: Date {
        switch self {
        case .article(let article):
            article.publishedDate ?? .distantPast
        case .weatherAlert(let alert):
            alert.effectiveDate ?? alert.fetchedAt
        }
    }

    var isHighPriority: Bool {
        switch self {
        case .article:
            false
        case .weatherAlert(let alert):
            alert.severity == .extreme || alert.severity == .severe
        }
    }
}

struct HomeInventoryReminder: Identifiable {
    let itemID: UUID
    let title: String
    var detail: String
    var priority: Int

    var id: UUID { itemID }
}

enum HomePinnedItem: Identifiable {
    case quickCard(QuickCard)
    case handbookSection(HandbookSection)

    var id: String {
        switch self {
        case .quickCard(let card):
            "card-\(card.id.uuidString)"
        case .handbookSection(let section):
            "section-\(section.id.uuidString)"
        }
    }
}

enum HomeSuggestionDestination {
    case quickCard(QuickCard)
    case handbookSection(HandbookSection)
    case note(NoteRecord)

    var key: String {
        switch self {
        case .quickCard(let card):
            "quick-card-\(card.id.uuidString)"
        case .handbookSection(let section):
            "handbook-section-\(section.id.uuidString)"
        case .note(let note):
            "note-\(note.id.uuidString)"
        }
    }
}

struct HomeSuggestion: Identifiable {
    let title: String
    let subtitle: String
    let reason: String
    let destination: HomeSuggestionDestination

    var id: String { destination.key }
}

struct HomeSuggestionCandidate {
    let suggestion: HomeSuggestion
    let score: Int
}
