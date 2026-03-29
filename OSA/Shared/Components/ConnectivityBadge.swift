import SwiftUI

struct ConnectivityBadge: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let state: ConnectivityState

    var body: some View {
        HStack(spacing: Spacing.xs) {
            statusIndicator

            Image(systemName: state.icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(appearance.dot)
                .accessibilityHidden(true)

            Text(state.rawValue)
                .contentTransition(.opacity)
        }
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Connectivity status")
        .accessibilityValue(accessibilityDescription)
        .animation(badgeAnimation, value: state)
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

    @ViewBuilder
    private var statusIndicator: some View {
        if state == .syncInProgress {
            ProgressView()
                .controlSize(.mini)
                .tint(appearance.dot)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)
        } else {
            Circle()
                .fill(appearance.dot)
                .frame(width: 8, height: 8)
                .scaleEffect(state == .onlineUsable ? 1 : 0.95)
                .accessibilityHidden(true)
        }
    }

    private var badgeAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.2)
    }
}

struct ConnectivityStatusNotice: Equatable, Identifiable {
    let state: ConnectivityState
    let title: String
    let message: String
    let autoDismisses: Bool

    var id: String {
        "\(state.rawValue)|\(title)|\(message)|\(autoDismisses)"
    }
}

struct ConnectivityStatusCallout: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

    let notice: ConnectivityStatusNotice

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: notice.state.icon)
                .font(.headline)
                .foregroundStyle(appearance.tint)
                .frame(width: 28, height: 28)
                .background(appearance.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: CornerRadius.sm))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(notice.title)
                    .font(.sectionHeader)
                    .foregroundStyle(.primary)

                Text(notice.message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Spacing.sm)

            if notice.state == .syncInProgress {
                ProgressView()
                    .controlSize(.small)
                    .tint(appearance.tint)
                    .accessibilityHidden(true)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(appearance.background, in: RoundedRectangle(cornerRadius: CornerRadius.md))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .stroke(appearance.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("connectivity-status-callout")
        .transition(calloutTransition)
        .animation(calloutAnimation, value: notice.id)
    }

    private var appearance: ConnectivityCalloutAppearance {
        switch notice.state {
        case .offline:
            ConnectivityCalloutAppearance(
                tint: .osaBoundary,
                background: .lanternDynamic(light: 0xF6EAD3, dark: 0x1D3028),
                border: .osaStroke
            )
        case .onlineConstrained:
            ConnectivityCalloutAppearance(
                tint: .osaWarning,
                background: .lanternDynamic(light: 0xF8ECD4, dark: 0x342916),
                border: .osaStroke
            )
        case .onlineUsable:
            ConnectivityCalloutAppearance(
                tint: .osaLocal,
                background: .lanternDynamic(light: 0xE9F3EC, dark: 0x163128),
                border: .osaHairline
            )
        case .syncInProgress:
            ConnectivityCalloutAppearance(
                tint: .osaTrust,
                background: .lanternDynamic(light: 0xF8F0DE, dark: 0x1D342D),
                border: .osaStroke
            )
        }
    }

    private var calloutTransition: AnyTransition {
        accessibilityReduceMotion
            ? .opacity
            : .move(edge: .top).combined(with: .opacity)
    }

    private var calloutAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.22)
    }
}

private struct ConnectivityBadgeAppearance {
    let dot: Color
    let label: Color
    let background: Color
    let border: Color
}

private struct ConnectivityCalloutAppearance {
    let tint: Color
    let background: Color
    let border: Color
}

#Preview {
    VStack(spacing: Spacing.md) {
        ConnectivityBadge(state: .offline)
        ConnectivityBadge(state: .onlineUsable)
        ConnectivityBadge(state: .onlineConstrained)
        ConnectivityBadge(state: .syncInProgress)
        ConnectivityStatusCallout(
            notice: ConnectivityStatusNotice(
                state: .offline,
                title: "Offline mode active",
                message: "Local content stays available while online enrichment pauses.",
                autoDismisses: false
            )
        )
    }
    .padding()
    .background(.osaBackground)
}
