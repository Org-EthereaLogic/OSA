import SwiftUI

// MARK: - Surface Tokens

extension ShapeStyle where Self == Color {
    static var osaPrimary: Color { Color("AccentColor") }
    static var osaBackground: Color { Color(.systemGroupedBackground) }
    static var osaSecondaryBackground: Color { Color(.secondarySystemGroupedBackground) }
    static var osaSurface: Color { Color(.systemBackground) }
}

// MARK: - Semantic Meaning Tokens

extension ShapeStyle where Self == Color {
    /// Emergency urgency — quick cards, critical alerts, immediate-action cues.
    static var osaEmergency: Color { Color(.systemOrange) }

    /// Trust and verification — reviewed badges, citation confidence, approved cues.
    static var osaTrust: Color { Color("AccentColor") }

    /// Calm guidance — informational emphasis, local-first reassurance.
    static var osaCalm: Color { Color(.systemTeal) }

    /// Warning — expiry, low stock, attention-needed states.
    static var osaWarning: Color { Color(.systemYellow) }

    /// Local/offline indicator — offline-safe, device-stored, grounded.
    static var osaLocal: Color { Color(.systemGreen) }

    /// Refusal/boundary — scope limits, blocked topics, unsupported queries.
    static var osaBoundary: Color { Color(.systemGray) }
}
