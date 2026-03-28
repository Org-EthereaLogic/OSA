import Foundation

enum PinnedContentSettings {
    static let pinnedQuickCardIDsKey = "settings.pinned.quickCards"
    static let pinnedSectionIDsKey = "settings.pinned.handbookSections"

    static func ids(from rawValue: String) -> [UUID] {
        SettingsValueCoding.decodeUUIDs(from: rawValue)
    }

    static func encode(ids: [UUID]) -> String {
        SettingsValueCoding.encode(ids)
    }

    static func isPinned(_ id: UUID, rawValue: String) -> Bool {
        ids(from: rawValue).contains(id)
    }

    static func toggled(_ id: UUID, rawValue: String) -> String {
        var values = ids(from: rawValue)
        if let index = values.firstIndex(of: id) {
            values.remove(at: index)
        } else {
            values.append(id)
        }
        return encode(ids: values)
    }
}
