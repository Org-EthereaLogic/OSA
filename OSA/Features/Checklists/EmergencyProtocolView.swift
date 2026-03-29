import SwiftUI

struct EmergencyProtocolView: View {
    let template: ChecklistTemplate

    @AppStorage(AccessibilitySettings.largePrintReadingModeKey)
    private var largePrintReadingMode = AccessibilitySettings.largePrintReadingModeDefault
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var currentIndex = 0
    @State private var metronomeRunning = false
    @State private var beatCount = 0
    @State private var stepTransitionDirection: StepTransitionDirection = .forward
    @AccessibilityFocusState private var focusedStep: UUID?

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
        .onChange(of: currentIndex) { _, _ in
            focusCurrentStep()
        }
        .onDisappear {
            metronomeRunning = false
        }
    }

    private var protocolHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("EMERGENCY PROTOCOL")
                .font(.brandEyebrow)
                .foregroundStyle(Color.white.opacity(0.95))
                .tracking(1.1)
                .accessibilityAddTraits(.isHeader)

            Text(template.description)
                .font(.brandSubheadline)
                .foregroundStyle(Color.white.opacity(0.95))
                .minimumScaleFactor(0.7)

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

            ProgressView(
                value: Double(currentIndex + 1),
                total: Double(max(template.items.count, 1))
            )
            .tint(.osaPrimary)
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
        .animation(stepAnimation, value: currentIndex)
    }

    private var stepCard: some View {
        let item = template.items[currentIndex]

        return ZStack {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(item.text)
                        .font(largePrintReadingMode ? .system(size: 34, weight: .bold, design: .rounded) : .stressTitle)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)

                    if let detail = item.detail, !detail.isEmpty {
                        Text(detail)
                            .font(largePrintReadingMode ? .system(size: 24, weight: .medium, design: .rounded) : .cardBody)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .minimumScaleFactor(0.7)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(stepAccessibilityLabel(for: item))
                .accessibilityValue(stepSummaryValue(for: item))
                .accessibilityFocused($focusedStep, equals: item.id)

                if item.riskLevel == "high" {
                    Label("High priority", systemImage: "exclamationmark.triangle.fill")
                        .font(.metadataCaption)
                        .foregroundStyle(.osaEmergency)
                        .minimumScaleFactor(0.7)
                }

                if template.timerProfile == .cprMetronome {
                    CPRMetronomeCard(
                        isRunning: metronomeRunning,
                        beatCount: beatCount,
                        onToggle: toggleMetronome
                    )
                }
            }
            .id(item.id)
            .transition(stepTransitionDirection.transition(reducedMotion: accessibilityReduceMotion))
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
        .animation(stepAnimation, value: currentIndex)
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
                Label(
                    currentIndex == template.items.count - 1 ? "Start Over" : "Next",
                    systemImage: currentIndex == template.items.count - 1 ? "arrow.counterclockwise" : "arrow.right"
                )
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.osaPrimary)
            .accessibilityHint(
                currentIndex == template.items.count - 1
                    ? "Returns to the first protocol step."
                    : "Moves to the next protocol step."
            )
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }

    private func stepBackward() {
        guard currentIndex > 0 else { return }
        stepTransitionDirection = .backward
        withAnimation(stepAnimation) {
            currentIndex = max(currentIndex - 1, 0)
        }
        hapticFeedbackService?.play(.protocolStepBackward)
    }

    private func stepForward() {
        guard !template.items.isEmpty else { return }
        if currentIndex == template.items.count - 1 {
            stepTransitionDirection = .backward
            withAnimation(stepAnimation) {
                currentIndex = 0
            }
            hapticFeedbackService?.play(.prominentNavigation)
            return
        }

        stepTransitionDirection = .forward
        withAnimation(stepAnimation) {
            currentIndex = min(currentIndex + 1, template.items.count - 1)
        }
        hapticFeedbackService?.play(.protocolStepForward)
    }

    private func toggleMetronome() {
        withAnimation(stepAnimation) {
            metronomeRunning.toggle()
        }
        beatCount = metronomeRunning ? 0 : beatCount
        hapticFeedbackService?.play(.prominentNavigation)
        if metronomeRunning {
            hapticFeedbackService?.prepare(.cprMetronomeBeat)
        }
    }

    private func focusCurrentStep() {
        guard template.items.indices.contains(currentIndex) else { return }
        let itemID = template.items[currentIndex].id

        let delay = accessibilityReduceMotion ? 0.0 : 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            focusedStep = itemID
        }
    }

    private func stepAccessibilityLabel(for item: ChecklistTemplateItem) -> String {
        "Step \(currentIndex + 1) of \(template.items.count). \(item.text)"
    }

    private func stepSummaryValue(for item: ChecklistTemplateItem) -> String {
        if let detail = item.detail, !detail.isEmpty {
            return item.riskLevel == "high" ? "\(detail) High priority." : detail
        }

        return item.riskLevel == "high" ? "High priority." : ""
    }

    private var stepAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.2)
    }
}

private enum StepTransitionDirection {
    case forward
    case backward

    func transition(reducedMotion: Bool) -> AnyTransition {
        guard !reducedMotion else { return .opacity }

        switch self {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }
}

private struct CPRMetronomeCard: View {
    @Environment(\.accessibilityReduceMotion) private var accessibilityReduceMotion

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
                Text(isRunning ? "Pace active" : "Pace paused")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isRunning ? .osaEmergency : .secondary)
                    .padding(.horizontal, Spacing.xs)
                    .padding(.vertical, Spacing.xxs)
                    .background((isRunning ? Color.osaEmergency : Color.secondary).opacity(0.12), in: Capsule())
                    .accessibilityHidden(true)

                Text("Beats: \(beatCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
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
        .animation(cardAnimation, value: isRunning)
    }

    private var cardAnimation: Animation {
        accessibilityReduceMotion
            ? .easeOut(duration: 0.12)
            : .easeInOut(duration: 0.18)
    }
}
