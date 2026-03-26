import SwiftUI

extension Font {
    /// Large bold title for stress-state quick reading (Quick Card detail, emergency headers).
    static let stressTitle: Font = .system(.title, design: .rounded, weight: .bold)

    /// Card and section titles in browse lists.
    static let cardTitle: Font = .title3.weight(.semibold)

    /// Standard body text for content reading.
    static let cardBody: Font = .body

    /// Section headers in Home dashboard and list screens.
    static let sectionHeader: Font = .headline

    /// Category badges, type labels, and scope indicators.
    static let categoryLabel: Font = .caption.weight(.semibold)

    /// Provenance metadata, review dates, and trust captions.
    static let metadataCaption: Font = .caption2

    /// Large-type layout for maximum readability under stress.
    static let largeType: Font = .system(size: 28, weight: .bold, design: .rounded)
}
