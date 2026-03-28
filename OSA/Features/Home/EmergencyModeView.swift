import MessageUI
import SwiftUI

struct EmergencyModeView: View {
    let safeMessageAvailable: Bool
    let onComposeSafeMessage: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    actionGrid
                    locationActions
                }
                .padding(Spacing.lg)
            }
            .background(.osaBackground)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Exit Emergency Mode") { dismiss() }
                        .accessibilityHint("Closes Emergency Mode and returns to Home.")
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("EMERGENCY MODE")
                .font(.brandEyebrow)
                .foregroundStyle(.white)
                .tracking(1.2)

            Text("Large targets, reviewed protocols, and local shortcuts for high-stress moments.")
                .font(.brandSubheadline)
                .foregroundStyle(.white)

            Text("Call emergency services whenever the situation is immediately life-threatening.")
                .font(.metadataCaption)
                .foregroundStyle(Color.white.opacity(0.92))
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.osaEmber, Color.osaCanopy, Color.osaNight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: CornerRadius.xl)
        )
    }

    private var actionGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.md) {
            NavigationLink {
                EmergencyProtocolsScreen()
            } label: {
                EmergencyActionCard(
                    title: "Protocols",
                    subtitle: "Step-by-step emergency flows",
                    systemImage: "cross.case.fill",
                    tint: .osaEmergency
                )
            }
            .buttonStyle(.plain)
            .hapticTap(.prominentNavigation)
            .accessibilityHint("Opens reviewed step-by-step emergency protocols.")

            NavigationLink {
                QuickCardsScreen()
            } label: {
                EmergencyActionCard(
                    title: "Quick Cards",
                    subtitle: "Large-type critical reminders",
                    systemImage: "bolt.fill",
                    tint: .osaPrimary
                )
            }
            .buttonStyle(.plain)
            .hapticTap(.prominentNavigation)
            .accessibilityHint("Opens large-type emergency quick cards.")

            Button(action: onComposeSafeMessage) {
                EmergencyActionCard(
                    title: "I'm Safe",
                    subtitle: safeMessageAvailable ? "Pre-filled SMS to local contacts" : "Add contacts in Settings first",
                    systemImage: "message.fill",
                    tint: safeMessageAvailable ? .osaTrust : .secondary
                )
            }
            .buttonStyle(.plain)
            .disabled(!safeMessageAvailable || !MFMessageComposeViewController.canSendText())
            .accessibilityHint(
                safeMessageAvailable
                    ? "Opens a pre-filled text message to your saved emergency contacts."
                    : "Unavailable until you add at least one emergency contact in Settings."
            )

            Button {
                hapticFeedbackService?.play(.emergencyPrimaryAction)
                if let url = URL(string: "tel://911") {
                    openURL(url)
                }
            } label: {
                EmergencyActionCard(
                    title: "Call 911",
                    subtitle: "Open the system dialer",
                    systemImage: "phone.fill",
                    tint: .osaCritical
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the system dialer for emergency services.")
        }
    }

    private var locationActions: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Nearby Resources")
                .font(.sectionHeader)
                .accessibilityAddTraits(.isHeader)

            NavigationLink {
                MapScreen(initialCategory: .hospital)
            } label: {
                EmergencyWideActionRow(
                    title: "Hospitals",
                    subtitle: "Open the map filtered to hospitals",
                    systemImage: "cross.fill"
                )
            }
            .buttonStyle(.plain)
            .hapticTap(.prominentNavigation)
            .accessibilityHint("Opens the map filtered to nearby hospitals.")

            NavigationLink {
                MapScreen(initialCategory: .shelter)
            } label: {
                EmergencyWideActionRow(
                    title: "Shelters",
                    subtitle: "Open the map filtered to shelters",
                    systemImage: "house.fill"
                )
            }
            .buttonStyle(.plain)
            .hapticTap(.prominentNavigation)
            .accessibilityHint("Opens the map filtered to nearby shelters.")
        }
    }
}

private struct EmergencyActionCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(title)
                .font(.stressTitle)
                .foregroundStyle(.primary)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, minHeight: 180, alignment: .topLeading)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct EmergencyWideActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.md) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(.osaPrimary)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(Spacing.lg)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}
