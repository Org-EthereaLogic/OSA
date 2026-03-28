import Foundation

enum HazardScenario: String, CaseIterable, Codable, Equatable, Sendable, Identifiable {
    case earthquake
    case powerOutage = "power-outage"
    case wildfire
    case flood
    case winterStorm = "winter-storm"
    case heatWave = "heat-wave"
    case evacuation
    case familyCommunication = "family-communication"
    case waterContamination = "water-contamination"
    case homeFire = "home-fire"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .earthquake: "Earthquake"
        case .powerOutage: "Power Outage"
        case .wildfire: "Wildfire"
        case .flood: "Flood"
        case .winterStorm: "Winter Storm"
        case .heatWave: "Heat Wave"
        case .evacuation: "Evacuation"
        case .familyCommunication: "Family Communication"
        case .waterContamination: "Water Contamination"
        case .homeFire: "Home Fire"
        }
    }

    var tag: String { "scenario:\(rawValue)" }
}

enum PreparednessRegion: String, CaseIterable, Codable, Equatable, Sendable, Identifiable {
    case pacificNorthwest = "pacific-northwest"
    case coastal
    case mountain
    case urban
    case rural
    case desert

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pacificNorthwest: "Pacific Northwest"
        case .coastal: "Coastal"
        case .mountain: "Mountain"
        case .urban: "Urban"
        case .rural: "Rural"
        case .desert: "Desert"
        }
    }

    var tag: String { "region:\(rawValue)" }
}

enum UserProfileSettings {
    static let onboardingCompletedKey = "settings.profile.onboardingCompleted"
    static let regionKey = "settings.profile.region"
    static let householdSizeKey = "settings.profile.householdSize"
    static let hazardsKey = "settings.profile.primaryHazards"

    static let onboardingCompletedDefault = false
    static let regionDefault = PreparednessRegion.pacificNorthwest
    static let householdSizeDefault = 1

    static func region(from rawValue: String) -> PreparednessRegion {
        PreparednessRegion(rawValue: rawValue) ?? regionDefault
    }

    static func hazards(from rawValue: String) -> [HazardScenario] {
        SettingsValueCoding.decodeStrings(from: rawValue)
            .compactMap(HazardScenario.init(rawValue:))
    }

    static func encode(hazards: [HazardScenario]) -> String {
        SettingsValueCoding.encode(hazards.map(\.rawValue))
    }
}
