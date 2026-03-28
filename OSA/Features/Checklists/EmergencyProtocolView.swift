import SwiftUI

struct EmergencyProtocolView: View {
    let template: ChecklistTemplate

    @AppStorage(AccessibilitySettings.largePrintReadingModeKey)
    private var largePrintReadingMode = AccessibilitySettings.largePrintReadingModeDefault
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var currentIndex = 0
    @State private var metronomeRunning = false
    @State private var beatCount = 0
    @AccessibilityFocusState private var focusedElement: EmergencyProtocolAccessibilityTarget?

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
            hapticFeedbackService?.play(.cprMetronomeBeat)
        }
        .onAppear {
            focusCurrentStep()
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
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(item.text)
                    .font(largePrintReadingMode ? .system(size: 34, weight: .bold, design: .rounded) : .stressTitle)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityFocused($focusedElement, equals: .stepSummary)

                if let detail = item.detail, !detail.isEmpty {
                    Text(detail)
                        .font(largePrintReadingMode ? .system(size: 24, weight: .medium, design: .rounded) : .cardBody)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Step \(currentIndex + 1) of \(template.items.count)")
            .accessibilityValue(stepSummaryValue(for: item))

            if item.riskLevel == "high" {
                Label("High priority", systemImage: "exclamationmark.triangle.fill")
                    .font(.metadataCaption)
                    .foregroundStyle(.osaEmergency)
            }

            if template.timerProfile == .cprMetronome {
                CPRMetronomeCard(
                    isRunning: metronomeRunning,
                    beatCount: beatCount,
                    onToggle: toggleMetronome
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
                stepBackward()
            } label: {
                Label("Back", systemImage: "arrow.left")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .disabled(currentIndex == 0)
            .accessibilityHint("Moves to the previous protocol step.")

            Button {
                stepForward()
            } label: {
                Label(currentIndex == template.items.count - 1 ? "Review Again" : "Next", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.osaPrimary)
            .accessibilityHint(
                currentIndex == template.items.count - 1
                    ? "Returns to the final step for review."
                    : "Moves to the next protocol step."
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }

    private func stepBackward() {
        guard currentIndex > 0 else { return }
        currentIndex = max(currentIndex - 1, 0)
        hapticFeedbackService?.play(.protocolStepBackward)
        focusCurrentStep()
    }

    private func stepForward() {
        guard !template.items.isEmpty else { return }
        currentIndex = min(currentIndex + 1, template.items.count - 1)
        hapticFeedbackService?.play(.protocolStepForward)
        focusCurrentStep()
    }

    private func toggleMetronome() {
        metronomeRunning.toggle()
        beatCount = metronomeRunning ? 0 : beatCount
        hapticFeedbackService?.play(.prominentNavigation)
        if metronomeRunning {
            hapticFeedbackService?.prepare(.cprMetronomeBeat)
        }
    }

    private func focusCurrentStep() {
        DispatchQueue.main.async {
            focusedElement = .stepSummary
        }
    }

    private func stepSummaryValue(for item: ChecklistTemplateItem) -> String {
        if let detail = item.detail, !detail.isEmpty {
            return item.riskLevel == "high" ? "\(detail) High priority." : detail
        }

        return item.riskLevel == "high" ? "High priority." : ""
    }
}

private enum EmergencyProtocolAccessibilityTarget: Hashable {
    case stepSummary
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
