import SwiftUI

struct ConnectivityBadge: View {
    let state: ConnectivityState

    var body: some View {
        Label(state.rawValue, systemImage: state.icon)
            .font(.caption2)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(.ultraThinMaterial, in: Capsule())
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        ConnectivityBadge(state: .offline)
        ConnectivityBadge(state: .onlineUsable)
        ConnectivityBadge(state: .onlineConstrained)
        ConnectivityBadge(state: .syncInProgress)
    }
}
