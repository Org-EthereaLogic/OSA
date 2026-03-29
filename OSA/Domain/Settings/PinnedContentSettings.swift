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

enum RecentLibraryHistorySettings {
    static let recentSectionIDsKey = "settings.library.recentSections"
    static let maxRecentSections = 6

    static func ids(from rawValue: String) -> [UUID] {
        SettingsValueCoding.decodeUUIDs(from: rawValue)
    }

    static func encode(ids: [UUID]) -> String {
        SettingsValueCoding.encode(ids)
    }

    static func recorded(_ id: UUID, rawValue: String, limit: Int = maxRecentSections) -> String {
        var values = ids(from: rawValue)
        values.removeAll { $0 == id }
        values.insert(id, at: 0)
        return encode(ids: Array(values.prefix(limit)))
    }

    static func prune(rawValue: String, keeping resolvableIDs: some Sequence<UUID>) -> String {
        let resolvableSet = Set(resolvableIDs)
        let filtered = ids(from: rawValue).filter { resolvableSet.contains($0) }
        return encode(ids: filtered)
    }
}
