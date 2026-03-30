import SwiftUI

struct MapAnnotationPin: View {
    let item: MapAnnotationItem

    var body: some View {
        Image(systemName: item.category.icon)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(Spacing.xs)
            .background(item.category.pinColor, in: Circle())
            .overlay { Circle().stroke(.white, lineWidth: 2) }
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(item.title)
            .accessibilityValue(item.subtitle ?? item.category.rawValue.capitalized)
    }
}

struct UserWaypointPin: View {
    let waypoint: UserWaypoint

    var body: some View {
        Image(systemName: waypoint.symbolName ?? waypoint.category.symbolName)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(Spacing.xs)
            .background(waypoint.category.pinColor, in: Circle())
            .overlay { Circle().stroke(.white, lineWidth: 2) }
            .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(waypoint.title)
            .accessibilityValue(waypoint.note ?? waypoint.category.title)
    }
}

extension MapAnnotationCategory {
    var pinColor: Color {
        switch self {
        case .shelter: .osaCalm
        case .evacuationRoute: .osaTrust
        case .hazardZone: .osaEmergency
        case .hospital: .osaCritical
        case .fireStation: .osaWarning
        case .waterSource: .osaCalm
        }
    }
}

extension UserWaypointCategory {
    var pinColor: Color {
        switch self {
        case .general:
            .osaPrimary
        case .shelter:
            .osaCalm
        case .water:
            .osaTrust
        case .medical:
            .osaCritical
        case .regroup:
            .osaWarning
        }
    }
}
