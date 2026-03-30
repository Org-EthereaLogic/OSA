import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case english = "en"
    case spanish = "es"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var displayName: String {
        switch self {
        case .english:
            "English"
        case .spanish:
            "Espanol"
        }
    }
}

enum AccessibilitySettings {
    static let largePrintReadingModeKey = "settings.accessibility.largePrintReadingMode"
    static let largePrintReadingModeDefault = false
    static let criticalHapticsKey = "settings.accessibility.criticalHaptics"
    static let criticalHapticsDefault = true
    static let appLanguageKey = "settings.accessibility.appLanguage"
    static let appLanguageDefault = AppLanguage.english
    static let highContrastModeKey = "settings.accessibility.highContrastMode"
    static let highContrastModeDefault = false

    static func appLanguage(from rawValue: String) -> AppLanguage {
        AppLanguage(rawValue: rawValue) ?? appLanguageDefault
    }
}
