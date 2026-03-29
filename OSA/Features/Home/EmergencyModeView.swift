import MessageUI
import SwiftUI

struct EmergencyModeView: View {
    let safeMessageAvailable: Bool
    let onComposeSafeMessage: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var isNightVisionEnabled = false
    @State private var isSOSAlarmActive = false

    private let sosTimer = Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    header
                    actionGrid
                    toolsShortcut
                    locationActions
                }
                .padding(Spacing.lg)
            }
            .safeAreaInset(edge: .bottom) {
                emergencyActionBar
            }
            .background(.osaBackground)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Exit Emergency Mode") { dismiss() }
                        .accessibilityHint("Closes Emergency Mode and returns to Home.")
                }
            }
        }
        .background(.osaBackground)
        .overlay {
            Color.red
                .opacity(isNightVisionEnabled ? 0.2 : 0)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .onReceive(sosTimer) { _ in
            guard isSOSAlarmActive else { return }
            hapticFeedbackService?.play(.emergencyPrimaryAction)
        }
        .onDisappear {
            isSOSAlarmActive = false
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("EMERGENCY MODE")
                .font(.brandEyebrow)
                .foregroundStyle(Color.white.opacity(0.95))
                .tracking(1.2)
                .accessibilityAddTraits(.isHeader)

            Text("Large targets, reviewed protocols, and local shortcuts for high-stress moments.")
                .font(.brandSubheadline)
                .foregroundStyle(Color.white.opacity(0.96))

            Text("Call emergency services whenever the situation is immediately life-threatening.")
                .font(.metadataCaption)
                .foregroundStyle(Color.white.opacity(0.96))
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
            .accessibilityLabel("Read Protocols")
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
            .accessibilityLabel("View Quick Cards")
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
            .accessibilityLabel("Send I’m Safe message")
            .accessibilityValue(safeMessageAvailable ? "Available" : "Unavailable")
            .accessibilityHint(
                safeMessageAvailable
                    ? "Opens a pre-filled text message to your saved emergency contacts."
                    : "Unavailable until you add at least one emergency contact in Settings."
            )

            Button(action: toggleNightVision) {
                EmergencyActionCard(
                    title: "Night Vision",
                    subtitle: isNightVisionEnabled ? "Red tint enabled for low-light use" : "Add a red tint for low-light use",
                    systemImage: isNightVisionEnabled ? "moon.stars.fill" : "moon.stars",
                    tint: isNightVisionEnabled ? .osaEmergency : .osaWarning
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isNightVisionEnabled ? "Disable Night Vision" : "Enable Night Vision")
            .accessibilityValue(isNightVisionEnabled ? "On" : "Off")
            .accessibilityHint("Adds a red tint over the screen for low-light reading.")
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
            .accessibilityLabel("Find nearby hospitals")
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
            .accessibilityLabel("Find nearby shelters")
            .accessibilityHint("Opens the map filtered to nearby shelters.")
        }
    }

    private var toolsShortcut: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Local Tools")
                .font(.sectionHeader)
                .accessibilityAddTraits(.isHeader)

            NavigationLink {
                SurvivalToolsScreen()
            } label: {
                EmergencyWideActionRow(
                    title: "Survival Tools",
                    subtitle: "Morse, screen light, whistle, timer, converter, and field references",
                    systemImage: "flashlight.on.fill"
                )
            }
            .buttonStyle(.plain)
            .hapticTap(.prominentNavigation)
            .accessibilityLabel("Open Survival Tools")
            .accessibilityHint("Opens offline survival tools and communication utilities.")
        }
    }

    private var emergencyActionBar: some View {
        HStack(spacing: Spacing.md) {
            Button(action: callEmergencyServices) {
                EmergencyBottomBarButton(
                    title: "Call 911",
                    subtitle: "Emergency services",
                    systemImage: "phone.fill",
                    tint: .osaCritical
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Call 911")
            .accessibilityHint("Opens the system dialer for emergency services.")

            Button(action: toggleSOSAlarm) {
                EmergencyBottomBarButton(
                    title: isSOSAlarmActive ? "Pause SOS" : "Audible SOS",
                    subtitle: isSOSAlarmActive ? "Stop haptic alert loop" : "Start haptic alert loop",
                    systemImage: isSOSAlarmActive ? "pause.fill" : "speaker.wave.3.fill",
                    tint: .osaEmergency
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isSOSAlarmActive ? "Pause Audible SOS" : "Start Audible SOS")
            .accessibilityValue(isSOSAlarmActive ? "Active" : "Inactive")
            .accessibilityHint("Uses repeating haptics until full audio playback is implemented.")
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.sm)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.osaHairline)
                .frame(height: 1)
        }
    }

    private func callEmergencyServices() {
        hapticFeedbackService?.play(.emergencyPrimaryAction)
        if let url = URL(string: "tel://911") {
            openURL(url)
        }
    }

    private func toggleNightVision() {
        isNightVisionEnabled.toggle()
        hapticFeedbackService?.play(.prominentNavigation)
    }

    private func toggleSOSAlarm() {
        isSOSAlarmActive.toggle()
        hapticFeedbackService?.play(isSOSAlarmActive ? .warning : .prominentNavigation)
        if isSOSAlarmActive {
            hapticFeedbackService?.prepare(.emergencyPrimaryAction)
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

private struct EmergencyBottomBarButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(tint, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.8)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(tint.opacity(0.28), lineWidth: 1)
        }
        .contentShape(Rectangle())
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
