import SwiftUI

// MARK: - Brand Tokens

extension ShapeStyle where Self == Color {
    /// Lantern brand gold — primary accent, navigation tint, interactive elements.
    static var osaPrimary: Color { Color("AccentColor") }

    /// Lantern ember — deep warm orange for emergency urgency and quick-card energy.
    static var osaEmber: Color { Color("LanternEmber") }

    /// Lantern slate — dark warm charcoal for emphasis text and structural contrast.
    static var osaSlate: Color { Color("LanternSlate") }
}

// MARK: - Surface Tokens

extension ShapeStyle where Self == Color {
    /// Grouped background with warm tint.
    static var osaBackground: Color { Color(.systemGroupedBackground) }

    /// Warm card surface for secondary content areas.
    static var osaSecondaryBackground: Color { Color("LanternWarmSurface") }

    /// Input and modal surface.
    static var osaSurface: Color { Color(.systemBackground) }
}

// MARK: - Semantic Meaning Tokens

extension ShapeStyle where Self == Color {
    /// Emergency urgency — quick cards, critical alerts, immediate-action cues.
    static var osaEmergency: Color { Color("LanternEmber") }

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
