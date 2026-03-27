import SwiftUI

extension Font {
    private static func brand(_ name: String, size: CGFloat, relativeTo textStyle: TextStyle) -> Font {
        .custom(name, size: size, relativeTo: textStyle)
    }

    /// Branded display face for hero titles and signature app headers.
    static let brandDisplay: Font = .brand("AvenirNext-DemiBold", size: 34, relativeTo: .largeTitle)

    /// Large bold title for stress-state quick reading (Quick Card detail, emergency headers).
    static let stressTitle: Font = .brand("AvenirNext-DemiBold", size: 30, relativeTo: .title)

    /// Card and section titles in browse lists.
    static let cardTitle: Font = .brand("AvenirNext-DemiBold", size: 21, relativeTo: .title3)

    /// Standard body text for content reading.
    static let cardBody: Font = .brand("AvenirNext-Regular", size: 17, relativeTo: .body)

    /// Section headers in Home dashboard and list screens.
    static let sectionHeader: Font = .brand("AvenirNext-DemiBold", size: 17, relativeTo: .headline)

    /// Category badges, type labels, and scope indicators.
    static let categoryLabel: Font = .brand("AvenirNext-DemiBold", size: 12, relativeTo: .caption)

    /// Provenance metadata, review dates, and trust captions.
    static let metadataCaption: Font = .brand("AvenirNext-Medium", size: 12, relativeTo: .caption2)

    /// Large-type layout for maximum readability under stress.
    static let largeType: Font = .brand("AvenirNext-DemiBold", size: 28, relativeTo: .title2)

    /// Small uppercase-style eyebrow text for brand framing and metadata.
    static let brandEyebrow: Font = .brand("AvenirNext-Medium", size: 12, relativeTo: .caption)

    /// Mid-sized supporting line for headers and grouped cards.
    static let brandSubheadline: Font = .brand("AvenirNext-Medium", size: 15, relativeTo: .subheadline)
}
