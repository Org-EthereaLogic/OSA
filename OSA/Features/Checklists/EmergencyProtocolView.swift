import SwiftUI
import UIKit

struct EmergencyProtocolView: View {
    let template: ChecklistTemplate

    @AppStorage(AccessibilitySettings.largePrintReadingModeKey)
    private var largePrintReadingMode = AccessibilitySettings.largePrintReadingModeDefault
    @AppStorage(AccessibilitySettings.criticalHapticsKey)
    private var criticalHaptics = AccessibilitySettings.criticalHapticsDefault

    @State private var currentIndex = 0
    @State private var metronomeRunning = false
    @State private var beatCount = 0

    private let metronomeTimer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            protocolHeader
            stepCard
            controls
        }
        .background(.osaBackground)
        .navigationTitle(template.title)
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(metronomeTimer) { _ in
            guard metronomeRunning, template.timerProfile == .cprMetronome else { return }
            beatCount += 1
            if criticalHaptics {
                let generator = UIImpactFeedbackGenerator(style: .rigid)
                generator.impactOccurred(intensity: 0.9)
            }
        }
    }

    private var protocolHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("EMERGENCY PROTOCOL")
                .font(.brandEyebrow)
                .foregroundStyle(Color.white.opacity(0.72))
                .tracking(1.1)

            Text(template.description)
                .font(.brandSubheadline)
                .foregroundStyle(Color.white.opacity(0.84))

            HStack(spacing: Spacing.sm) {
                Label("Step \(currentIndex + 1) of \(template.items.count)", systemImage: "list.number")
                    .font(.metadataCaption)
                    .foregroundStyle(.osaPaperGlow)

                if template.timerProfile == .cprMetronome {
                    Label(metronomeRunning ? "CPR pace active" : "CPR pace available", systemImage: "waveform.path")
                        .font(.metadataCaption)
                        .foregroundStyle(.osaPaperGlow)
                }
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.osaCanopy, Color.osaPine, Color.osaNight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: CornerRadius.xl)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaPrimary.opacity(0.24), lineWidth: 1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.md)
    }

    private var stepCard: some View {
        let item = template.items[currentIndex]

        return VStack(alignment: .leading, spacing: Spacing.lg) {
            Text(item.text)
                .font(largePrintReadingMode ? .system(size: 34, weight: .bold, design: .rounded) : .stressTitle)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.9)

            if let detail = item.detail, !detail.isEmpty {
                Text(detail)
                    .font(largePrintReadingMode ? .system(size: 24, weight: .medium, design: .rounded) : .cardBody)
                    .foregroundStyle(.secondary)
            }

            if item.riskLevel == "high" {
                Label("High priority", systemImage: "exclamationmark.triangle.fill")
                    .font(.metadataCaption)
                    .foregroundStyle(.osaEmergency)
            }

            if template.timerProfile == .cprMetronome {
                CPRMetronomeCard(
                    isRunning: metronomeRunning,
                    beatCount: beatCount,
                    onToggle: { metronomeRunning.toggle() }
                )
            }
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.lg)
    }

    private var controls: some View {
        HStack(spacing: Spacing.md) {
            Button {
                currentIndex = max(currentIndex - 1, 0)
            } label: {
                Label("Back", systemImage: "arrow.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(currentIndex == 0)

            Button {
                currentIndex = min(currentIndex + 1, template.items.count - 1)
            } label: {
                Label(currentIndex == template.items.count - 1 ? "Review Again" : "Next", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.osaPrimary)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }
}

private struct CPRMetronomeCard: View {
    let isRunning: Bool
    let beatCount: Int
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("CPR Compression Pace")
                .font(.sectionHeader)
            Text("Runs at roughly 100 compressions per minute using haptics.")
                .font(.metadataCaption)
                .foregroundStyle(.secondary)

            HStack {
                Text("Beats: \(beatCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: onToggle) {
                    Label(isRunning ? "Pause Pace" : "Start Pace", systemImage: isRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(.osaEmergency)
            }
        }
        .padding(Spacing.lg)
        .background(Color.osaEmergency.opacity(0.08), in: RoundedRectangle(cornerRadius: CornerRadius.lg))
    }
}
