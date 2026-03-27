import SwiftUI

private extension UIColor {
    convenience init(lanternHex hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255
        let green = CGFloat((hex >> 8) & 0xFF) / 255
        let blue = CGFloat(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

extension Color {
    static func lanternHex(_ hex: UInt32, opacity: Double = 1) -> Color {
        Color(uiColor: UIColor(lanternHex: hex, alpha: opacity))
    }

    static func lanternDynamic(light: UInt32, dark: UInt32) -> Color {
        Color(
            uiColor: UIColor { traitCollection in
                UIColor(
                    lanternHex: traitCollection.userInterfaceStyle == .dark ? dark : light
                )
            }
        )
    }
}

// MARK: - Brand Tokens

extension ShapeStyle where Self == Color {
    /// Lantern brand gold — primary accent, navigation tint, interactive elements.
    static var osaPrimary: Color { Color("AccentColor") }

    /// Lantern forest canopy — primary dark background and calm emphasis.
    static var osaCanopy: Color { .lanternHex(0x214C40) }

    /// Lantern deep pine — secondary dark-green support tone.
    static var osaPine: Color { .lanternHex(0x173329) }

    /// Lantern night — deepest neutral used for hero backgrounds.
    static var osaNight: Color { .lanternHex(0x0E221C) }

    /// Warm paper highlight used inside branded surfaces and marks.
    static var osaPaperGlow: Color { .lanternDynamic(light: 0xFFF9E8, dark: 0xF5ECD5) }

    /// Lantern ember — deep warm orange for emergency urgency and quick-card energy.
    static var osaEmber: Color { Color("LanternEmber") }

    /// Lantern slate — dark warm charcoal for emphasis text and structural contrast.
    static var osaSlate: Color { Color("LanternSlate") }
}

// MARK: - Surface Tokens

extension ShapeStyle where Self == Color {
    /// Branded grouped background with warm-paper light mode and forest-night dark mode.
    static var osaBackground: Color { .lanternDynamic(light: 0xF6EFE2, dark: 0x0E221C) }

    /// Warm card surface for branded content blocks.
    static var osaSecondaryBackground: Color { .lanternDynamic(light: 0xFFF9E8, dark: 0x173329) }

    /// Input, grouped-list, and modal surface.
    static var osaSurface: Color { .lanternDynamic(light: 0xFFFCF7, dark: 0x1A332C) }

    /// Raised surface for hero cards and emphasized sections.
    static var osaElevatedSurface: Color { .lanternDynamic(light: 0xFFFFFF, dark: 0x214C40) }

    /// Shared border color for branded cards and pills.
    static var osaStroke: Color { .lanternDynamic(light: 0xDEC89A, dark: 0x35584B) }

    /// Fine divider tone for subtle card chrome.
    static var osaHairline: Color { .lanternDynamic(light: 0xEADCBF, dark: 0x28443B) }
}

// MARK: - Semantic Meaning Tokens

extension ShapeStyle where Self == Color {
    /// Emergency urgency — quick cards, critical alerts, immediate-action cues.
    static var osaEmergency: Color { Color("LanternEmber") }

    /// Trust and verification — reviewed badges, citation confidence, approved cues.
    static var osaTrust: Color { Color("AccentColor") }

    /// Calm guidance — informational emphasis, local-first reassurance.
    static var osaCalm: Color { .lanternDynamic(light: 0x214C40, dark: 0x8FAE9D) }

    /// Warning — expiry, low stock, attention-needed states.
    static var osaWarning: Color { .lanternDynamic(light: 0xE0B038, dark: 0xF1C85E) }

    /// Local/offline indicator — offline-safe, device-stored, grounded.
    static var osaLocal: Color { .lanternDynamic(light: 0x214C40, dark: 0x97B5A5) }

    /// Refusal/boundary — scope limits, blocked topics, unsupported queries.
    static var osaBoundary: Color { .lanternDynamic(light: 0x6E6A61, dark: 0xBDB5A7) }

    /// Critical state — import failures, expired supplies, or destructive warnings.
    static var osaCritical: Color { .lanternDynamic(light: 0xC2581A, dark: 0xF08B53) }
}
