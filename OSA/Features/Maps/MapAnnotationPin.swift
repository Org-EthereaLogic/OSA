import SwiftUI

struct MapAnnotationPin: View {
    let category: MapAnnotationCategory

    var body: some View {
        Image(systemName: category.icon)
            .font(.caption)
            .foregroundStyle(.white)
            .padding(Spacing.xs)
            .background(category.pinColor, in: Circle())
            .overlay { Circle().stroke(.white, lineWidth: 2) }
            .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
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
