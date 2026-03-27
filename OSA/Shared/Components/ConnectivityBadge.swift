import SwiftUI

struct ConnectivityBadge: View {
    let state: ConnectivityState

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Circle()
                .fill(appearance.dot)
                .frame(width: 8, height: 8)

            Label(state.rawValue, systemImage: state.icon)
        }
        .labelStyle(.titleAndIcon)
            .font(.metadataCaption)
            .fontWeight(.medium)
            .foregroundStyle(appearance.label)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(appearance.background, in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(appearance.border, lineWidth: 1)
            }
            .accessibilityLabel(accessibilityDescription)
    }

    private var appearance: ConnectivityBadgeAppearance {
        switch state {
        case .offline:
            ConnectivityBadgeAppearance(
                dot: .osaBoundary,
                label: .primary,
                background: .lanternDynamic(light: 0xF2E5CA, dark: 0x20352D),
                border: .osaStroke
            )
        case .onlineConstrained:
            ConnectivityBadgeAppearance(
                dot: .osaWarning,
                label: .primary,
                background: .lanternDynamic(light: 0xF9E9C6, dark: 0x382D14),
                border: .osaStroke
            )
        case .onlineUsable:
            ConnectivityBadgeAppearance(
                dot: .osaLocal,
                label: .primary,
                background: .lanternDynamic(light: 0xE6F0E9, dark: 0x18342B),
                border: .osaHairline
            )
        case .syncInProgress:
            ConnectivityBadgeAppearance(
                dot: .osaTrust,
                label: .primary,
                background: .lanternDynamic(light: 0xF7EDDA, dark: 0x223830),
                border: .osaStroke
            )
        }
    }

    private var accessibilityDescription: String {
        switch state {
        case .offline: "Device is offline. All content is available locally."
        case .onlineConstrained: "Limited connectivity. Core content remains available."
        case .onlineUsable: "Online and connected."
        case .syncInProgress: "Refreshing content from approved sources."
        }
    }
}

private struct ConnectivityBadgeAppearance {
    let dot: Color
    let label: Color
    let background: Color
    let border: Color
}

#Preview {
    VStack(spacing: Spacing.md) {
        ConnectivityBadge(state: .offline)
        ConnectivityBadge(state: .onlineUsable)
        ConnectivityBadge(state: .onlineConstrained)
        ConnectivityBadge(state: .syncInProgress)
    }
    .padding()
    .background(.osaBackground)
}
