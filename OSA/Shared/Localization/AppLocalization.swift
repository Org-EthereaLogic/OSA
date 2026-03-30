import Foundation

enum AppLocalization {
    static let tableName = "Localizable"

    static func localized(
        _ key: String,
        language: AppLanguage = currentLanguage(),
        fallback: String? = nil,
        bundle: Bundle = .main
    ) -> String {
        localizedBundle(for: language, in: bundle)
            .localizedString(forKey: key, value: fallback ?? key, table: tableName)
    }

    static func currentLanguage(userDefaults: UserDefaults = .standard) -> AppLanguage {
        AccessibilitySettings.appLanguage(
            from: userDefaults.string(forKey: AccessibilitySettings.appLanguageKey)
                ?? AccessibilitySettings.appLanguageDefault.rawValue
        )
    }

    private static func localizedBundle(for language: AppLanguage, in bundle: Bundle) -> Bundle {
        guard let path = bundle.path(forResource: language.rawValue, ofType: "lproj"),
              let localizedBundle = Bundle(path: path)
        else {
            return bundle
        }

        return localizedBundle
    }
}
