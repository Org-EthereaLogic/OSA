import SwiftUI

struct ConnectivityBadge: View {
    let state: ConnectivityState

    var body: some View {
        Label(state.rawValue, systemImage: state.icon)
            .font(.metadataCaption)
            .fontWeight(.medium)
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(backgroundMaterial, in: Capsule())
            .accessibilityLabel(accessibilityDescription)
    }

    private var foregroundColor: Color {
        switch state {
        case .offline: .osaBoundary
        case .onlineConstrained: .osaWarning
        case .onlineUsable: .osaLocal
        case .syncInProgress: .osaCalm
        }
    }

    private var backgroundMaterial: some ShapeStyle {
        .ultraThinMaterial
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
