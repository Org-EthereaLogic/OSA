import SwiftUI

// MARK: - Spacing

enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48
}

// MARK: - Corner Radius

enum CornerRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Typography

extension Font {
    static let cardTitle: Font = .title2.weight(.semibold)
    static let cardBody: Font = .body
    static let sectionHeader: Font = .headline
    static let caption2: Font = .caption2
    static let largeType: Font = .system(size: 28, weight: .bold)
}

// MARK: - Colors

extension ShapeStyle where Self == Color {
    static var osaPrimary: Color { Color("AccentColor") }
    static var osaBackground: Color { Color(.systemGroupedBackground) }
    static var osaSecondaryBackground: Color { Color(.secondarySystemGroupedBackground) }
    static var osaSurface: Color { Color(.systemBackground) }
}

// MARK: - Connectivity State

enum ConnectivityState: String {
    case offline = "Offline"
    case onlineConstrained = "Limited"
    case onlineUsable = "Online"
    case syncInProgress = "Refreshing"

    var icon: String {
        switch self {
        case .offline: "wifi.slash"
        case .onlineConstrained: "wifi.exclamationmark"
        case .onlineUsable: "wifi"
        case .syncInProgress: "arrow.triangle.2.circlepath"
        }
    }
}
