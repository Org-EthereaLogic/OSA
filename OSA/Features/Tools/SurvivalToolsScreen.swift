import SwiftUI
import UIKit

struct SurvivalToolsScreen: View {
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var morseText = "SOS"
    @State private var morseSignalPlayer = MorseSignalPlayer()
    @State private var whistleController = WhistleToneController()
    @State private var brightScreenMode: BrightScreenMode?

    @State private var converterKind: SurvivalToolKit.UnitConversionKind = .temperature
    @State private var converterDirection: SurvivalToolKit.UnitConversionDirection = .forward
    @State private var converterInput = ""

    @State private var latitudeText = "47.61"
    @State private var longitudeText = "-122.33"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                heroCard
                signalSection
                timingSection
                referenceSection
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .background(.osaBackground)
        .navigationTitle("Tools")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $brightScreenMode) { mode in
            BrightScreenUtilityView(mode: mode)
        }
        .onChange(of: morseText) { _, _ in
            morseSignalPlayer.stop()
        }
        .onDisappear {
            morseSignalPlayer.stop()
            whistleController.stop()
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(spacing: Spacing.md) {
                BrandMarkView(size: 48)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("LOCAL SURVIVAL TOOLS")
                        .font(.brandEyebrow)
                        .foregroundStyle(Color.white.opacity(0.76))
                        .tracking(1.1)

                    Text("Signal, time, and field-reference utilities that stay on device.")
                        .font(.brandSubheadline)
                        .foregroundStyle(Color.white.opacity(0.94))
                }
            }

            Text("Screen light and mirror modes are display aids only. Radio and declination outputs are bounded references, not guarantees.")
                .font(.metadataCaption)
                .foregroundStyle(Color.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.lg)
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
        .accessibilityElement(children: .combine)
    }

    private var signalSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(
                title: "Signal",
                subtitle: "Offline signaling aids for visual and audible attention."
            )

            ToolCard(
                title: "Morse Signal",
                subtitle: "Encode plain text, review the pattern, then send a local flash and haptic sequence."
            ) {
                TextField("Enter text for Morse", text: $morseText, axis: .vertical)
                    .textInputAutocapitalization(.characters)
                    .disableAutocorrection(true)
                    .padding(Spacing.md)
                    .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.osaHairline, lineWidth: 1)
                    }
                    .accessibilityLabel("Morse text")

                HStack(alignment: .top, spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Encoded Output")
                            .font(.sectionHeader)
                        Text(morseEncoding.rendered.isEmpty ? "Supported letters A-Z and digits 0-9 appear here." : morseEncoding.rendered)
                            .font(.largeType)
                            .foregroundStyle(morseEncoding.rendered.isEmpty ? .secondary : .primary)
                            .monospaced()
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }

                SignalStatusTile(
                    title: morseSignalPlayer.isRunning ? "Sending Morse" : "Signal Preview",
                    subtitle: morseSignalPlayer.isRunning
                        ? "Visual pulse active. Stop when the message is complete."
                        : "Ready to flash the encoded pattern on screen with haptics.",
                    isActive: morseSignalPlayer.isPulseActive
                )

                HStack(spacing: Spacing.md) {
                    ToolActionButton(
                        title: "Use SOS",
                        systemImage: "wave.3.right",
                        tint: .osaEmergency
                    ) {
                        morseText = "SOS"
                        hapticFeedbackService?.play(.prominentNavigation)
                    }

                    ToolActionButton(
                        title: morseSignalPlayer.isRunning ? "Stop Signal" : "Play Signal",
                        systemImage: morseSignalPlayer.isRunning ? "stop.fill" : "play.fill",
                        tint: morseSignalPlayer.isRunning ? .osaBoundary : .osaPrimary,
                        isProminent: true
                    ) {
                        toggleMorseSignal()
                    }
                    .disabled(morseEncoding.isEmpty)
                }
            }

            ToolCard(
                title: "Screen Light",
                subtitle: "Bright-screen light mode only. This does not use the hardware torch or camera."
            ) {
                HStack(spacing: Spacing.md) {
                    ToolActionButton(
                        title: "Open Light",
                        systemImage: "flashlight.on.fill",
                        tint: .osaPrimary,
                        isProminent: true
                    ) {
                        activateBrightScreen(.flashlight)
                    }

                    ToolActionButton(
                        title: "SOS Beacon",
                        systemImage: "light.beacon.max.fill",
                        tint: .osaEmergency
                    ) {
                        activateBrightScreen(.sos)
                    }
                }

                limitationText("Attempts a temporary screen-brightness boost while active and restores your prior brightness on exit when the device allows it.")
            }

            ToolCard(
                title: "Signal Mirror",
                subtitle: "High-contrast screen aid with a simple aiming reticle for manual daytime signaling."
            ) {
                ToolActionButton(
                    title: "Open Mirror Aid",
                    systemImage: "viewfinder",
                    tint: .osaWarning,
                    isProminent: true
                ) {
                    activateBrightScreen(.mirror)
                }

                limitationText("Screen aid only. It does not track the sun, measure glare, or replace a reflective mirror.")
            }

            ToolCard(
                title: "Whistle",
                subtitle: "Generated local tone for short-range attention signaling. Audio behavior can vary by device and silent-mode settings."
            ) {
                HStack(spacing: Spacing.md) {
                    ToolActionButton(
                        title: whistleController.isPlaying ? "Stop Whistle" : "Start Whistle",
                        systemImage: whistleController.isPlaying ? "stop.circle.fill" : "speaker.wave.3.fill",
                        tint: whistleController.isPlaying ? .osaBoundary : .osaEmergency,
                        isProminent: true
                    ) {
                        toggleWhistle()
                    }

                    SignalStatusTile(
                        title: whistleController.isPlaying ? "Whistle Active" : "Whistle Ready",
                        subtitle: whistleController.isPlaying
                            ? "Generated tone is running locally."
                            : "Use the visible state even if the simulator does not render audio.",
                        isActive: whistleController.isPlaying
                    )
                }
            }
        }
    }

    private var timingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(
                title: "Timing",
                subtitle: "Large controls for a stopwatch or a preset field timer."
            )

            TimerToolCardView()
        }
    }

    private var referenceSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SectionHeader(
                title: "Reference",
                subtitle: "Deterministic conversions and bounded offline field notes."
            )

            ToolCard(
                title: "Unit Converter",
                subtitle: "Common field conversions with fixed local math."
            ) {
                Picker("Conversion", selection: $converterKind) {
                    ForEach(SurvivalToolKit.UnitConversionKind.allCases) { kind in
                        Text(kind.title).tag(kind)
                    }
                }
                .pickerStyle(.menu)

                Picker("Direction", selection: $converterDirection) {
                    Text("\(converterKind.primaryUnit) -> \(converterKind.secondaryUnit)")
                        .tag(SurvivalToolKit.UnitConversionDirection.forward)
                    Text("\(converterKind.secondaryUnit) -> \(converterKind.primaryUnit)")
                        .tag(SurvivalToolKit.UnitConversionDirection.reverse)
                }
                .pickerStyle(.segmented)

                TextField("Enter value", text: $converterInput)
                    .keyboardType(.decimalPad)
                    .padding(Spacing.md)
                    .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.osaHairline, lineWidth: 1)
                    }

                Text(converterResultText)
                    .font(.brandSubheadline)
                    .foregroundStyle(parsedConverterInput == nil ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ToolCard(
                title: "Radio Reference",
                subtitle: "Static reference notes only. This screen does not tune, scan, or transmit."
            ) {
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(SurvivalToolKit.radioReferenceEntries) { entry in
                        RadioReferenceRow(entry: entry)
                    }
                }

                limitationText(SurvivalToolKit.radioDisclaimer)
            }

            ToolCard(
                title: "Declination",
                subtitle: "Manual approximate estimate for supported Pacific Northwest coordinates."
            ) {
                HStack(spacing: Spacing.md) {
                    TextField("Latitude", text: $latitudeText)
                        .keyboardType(.numbersAndPunctuation)
                        .padding(Spacing.md)
                        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.osaHairline, lineWidth: 1)
                        }

                    TextField("Longitude", text: $longitudeText)
                        .keyboardType(.numbersAndPunctuation)
                        .padding(Spacing.md)
                        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                        .overlay {
                            RoundedRectangle(cornerRadius: CornerRadius.md)
                                .stroke(Color.osaHairline, lineWidth: 1)
                        }
                }

                Text(declinationResultText)
                    .font(.brandSubheadline)
                    .foregroundStyle(parsedDeclinationCoordinate == nil ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)

                limitationText("\(SurvivalToolKit.declinationCoverageDescription) \(SurvivalToolKit.declinationPrecisionNote)")
            }
        }
    }

    private var morseEncoding: SurvivalToolKit.MorseEncoding {
        SurvivalToolKit.encodeMorse(morseText)
    }

    private var parsedConverterInput: Double? {
        Double(converterInput.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var converterSourceUnit: String {
        converterDirection == .forward ? converterKind.primaryUnit : converterKind.secondaryUnit
    }

    private var converterDestinationUnit: String {
        converterDirection == .forward ? converterKind.secondaryUnit : converterKind.primaryUnit
    }

    private var converterResultText: String {
        guard let value = parsedConverterInput else {
            return "Enter a numeric value to convert."
        }

        let converted = SurvivalToolKit.convert(
            value: value,
            kind: converterKind,
            direction: converterDirection
        )

        return "\(formattedNumber(value)) \(converterSourceUnit) = \(formattedNumber(converted)) \(converterDestinationUnit)"
    }

    private var parsedDeclinationCoordinate: (latitude: Double, longitude: Double)? {
        guard let latitude = Double(latitudeText.trimmingCharacters(in: .whitespacesAndNewlines)),
              let longitude = Double(longitudeText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }

        return (latitude: latitude, longitude: longitude)
    }

    private var declinationResultText: String {
        guard let coordinate = parsedDeclinationCoordinate else {
            return "Enter decimal latitude and longitude."
        }

        guard let estimate = SurvivalToolKit.estimateDeclination(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ) else {
            return "Unsupported area. Use supported Pacific Northwest coordinates instead of guessing outside coverage."
        }

        return "\(estimate.formattedValue). \(estimate.guidance)"
    }

    private func toggleMorseSignal() {
        if morseSignalPlayer.isRunning {
            morseSignalPlayer.stop()
            hapticFeedbackService?.play(.warning)
            return
        }

        morseSignalPlayer.play(tokens: morseEncoding.tokens, haptics: hapticFeedbackService)
    }

    private func activateBrightScreen(_ mode: BrightScreenMode) {
        morseSignalPlayer.stop()
        whistleController.stop()
        brightScreenMode = mode
        hapticFeedbackService?.play(.emergencyPrimaryAction)
    }

    private func toggleWhistle() {
        if whistleController.isPlaying {
            whistleController.stop()
            hapticFeedbackService?.play(.warning)
        } else {
            whistleController.start()
            hapticFeedbackService?.play(.emergencyPrimaryAction)
        }
    }

    private func limitationText(_ text: String) -> some View {
        Text(text)
            .font(.metadataCaption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func formattedNumber(_ value: Double) -> String {
        Self.numberFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
    }

    private static let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.locale = .autoupdatingCurrent
        return formatter
    }()
}

private extension SurvivalToolsScreen {
    enum TimingMode: String, CaseIterable, Identifiable {
        case stopwatch
        case countdown

        var id: String { rawValue }

        var title: String {
            switch self {
            case .stopwatch: "Stopwatch"
            case .countdown: "Timer"
            }
        }
    }

    enum BrightScreenMode: String, Identifiable {
        case flashlight
        case sos
        case mirror

        var id: String { rawValue }

        var title: String {
            switch self {
            case .flashlight: "Screen Light"
            case .sos: "SOS Beacon"
            case .mirror: "Signal Mirror"
            }
        }

        var note: String {
            switch self {
            case .flashlight:
                "Screen light only. This does not control the device torch."
            case .sos:
                "Screen-based SOS sequence only. Keep the display aimed toward the responder."
            case .mirror:
                "Manual screen aid only. Use a real signal mirror when you have one."
            }
        }
    }
}

private struct TimerToolCardView: View {
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    @State private var timingMode: SurvivalToolsScreen.TimingMode = .stopwatch
    @State private var countdownDuration: TimeInterval = 300
    @State private var elapsedBeforePause: TimeInterval = 0
    @State private var activeStartDate: Date?
    @State private var countdownDidComplete = false
    @State private var countdownCompletionTask: Task<Void, Never>?

    var body: some View {
        ToolCard(
            title: "Timer / Stopwatch",
            subtitle: "Foreground only. No notifications, lock-screen alerts, or background execution are claimed."
        ) {
            Picker("Timing mode", selection: $timingMode) {
                ForEach(SurvivalToolsScreen.TimingMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            TimingReadoutView(
                timingMode: timingMode,
                countdownDuration: countdownDuration,
                elapsedBeforePause: elapsedBeforePause,
                activeStartDate: activeStartDate
            )

            if timingMode == .countdown {
                HStack(spacing: Spacing.sm) {
                    ForEach(Self.timerPresets, id: \.self) { preset in
                        PresetButton(
                            title: presetTitle(for: preset),
                            isSelected: countdownDuration == preset
                        ) {
                            selectPreset(preset)
                        }
                    }
                }
            }

            HStack(spacing: Spacing.md) {
                ToolActionButton(
                    title: isTimingRunning ? "Pause" : timingMode == .countdown ? "Start Timer" : "Start Stopwatch",
                    systemImage: isTimingRunning ? "pause.fill" : "play.fill",
                    tint: .osaPrimary,
                    isProminent: true
                ) {
                    toggleTiming()
                }

                ToolActionButton(
                    title: "Reset",
                    systemImage: "arrow.counterclockwise",
                    tint: .osaBoundary
                ) {
                    resetTiming()
                }
            }
        }
        .onChange(of: timingMode) { _, _ in
            resetTiming(playHaptic: false)
        }
        .onDisappear {
            cancelCountdownCompletion()
        }
    }

    private var isTimingRunning: Bool {
        activeStartDate != nil
    }

    private var currentElapsedTime: TimeInterval {
        elapsedTime(at: Date())
    }

    private var currentTimingDisplay: TimeInterval {
        timingDisplay(at: Date())
    }

    private func elapsedTime(at date: Date) -> TimeInterval {
        elapsedBeforePause + (activeStartDate.map { date.timeIntervalSince($0) } ?? 0)
    }

    private func timingDisplay(at date: Date) -> TimeInterval {
        switch timingMode {
        case .stopwatch:
            elapsedTime(at: date)
        case .countdown:
            max(countdownDuration - elapsedTime(at: date), 0)
        }
    }

    private func toggleTiming() {
        if isTimingRunning {
            elapsedBeforePause = currentElapsedTime
            activeStartDate = nil
            cancelCountdownCompletion()
            hapticFeedbackService?.play(.warning)
            return
        }

        if timingMode == .countdown, currentTimingDisplay <= 0 {
            elapsedBeforePause = 0
            countdownDidComplete = false
        }

        activeStartDate = Date()
        scheduleCountdownCompletionIfNeeded()
        hapticFeedbackService?.play(.prominentNavigation)
    }

    private func resetTiming(playHaptic: Bool = true) {
        activeStartDate = nil
        elapsedBeforePause = 0
        countdownDidComplete = false
        cancelCountdownCompletion()

        if playHaptic {
            hapticFeedbackService?.play(.warning)
        }
    }

    private func selectPreset(_ preset: TimeInterval) {
        countdownDuration = preset
        resetTiming(playHaptic: false)
        hapticFeedbackService?.play(.prominentNavigation)
    }

    private func scheduleCountdownCompletionIfNeeded() {
        cancelCountdownCompletion()

        guard timingMode == .countdown, activeStartDate != nil else { return }

        let remainingDuration = max(countdownDuration - elapsedBeforePause, 0)
        guard remainingDuration > 0 else {
            completeCountdownIfNeeded()
            return
        }

        let remainingNanoseconds = UInt64((remainingDuration * 1_000_000_000).rounded())
        countdownCompletionTask = Task {
            do {
                try await Task.sleep(nanoseconds: remainingNanoseconds)
            } catch {
                return
            }

            await MainActor.run {
                completeCountdownIfNeeded()
            }
        }
    }

    private func completeCountdownIfNeeded() {
        defer {
            countdownCompletionTask = nil
        }

        guard timingMode == .countdown, let activeStartDate else { return }
        guard elapsedBeforePause + Date().timeIntervalSince(activeStartDate) >= countdownDuration else { return }

        self.activeStartDate = nil
        elapsedBeforePause = countdownDuration

        guard !countdownDidComplete else { return }

        countdownDidComplete = true
        hapticFeedbackService?.play(.success)
    }

    private func cancelCountdownCompletion() {
        countdownCompletionTask?.cancel()
        countdownCompletionTask = nil
    }

    private func presetTitle(for duration: TimeInterval) -> String {
        "\(Int(duration / 60))m"
    }

    private static let timerPresets: [TimeInterval] = [60, 300, 900, 1_800]
}

private struct TimingReadoutView: View {
    let timingMode: SurvivalToolsScreen.TimingMode
    let countdownDuration: TimeInterval
    let elapsedBeforePause: TimeInterval
    let activeStartDate: Date?

    var body: some View {
        Group {
            if let activeStartDate {
                TimelineView(.periodic(from: activeStartDate, by: 0.2)) { context in
                    durationLabel(for: context.date)
                }
            } else {
                durationLabel(for: Date())
            }
        }
    }

    private func durationLabel(for date: Date) -> some View {
        let duration = timingDisplay(at: date)

        return Text(Self.formattedDuration(duration))
            .font(.system(size: 46, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, Spacing.sm)
            .accessibilityLabel("Timing display")
            .accessibilityValue(Self.formattedDuration(duration))
    }

    private func timingDisplay(at date: Date) -> TimeInterval {
        switch timingMode {
        case .stopwatch:
            elapsedTime(at: date)
        case .countdown:
            max(countdownDuration - elapsedTime(at: date), 0)
        }
    }

    private func elapsedTime(at date: Date) -> TimeInterval {
        elapsedBeforePause + (activeStartDate.map { date.timeIntervalSince($0) } ?? 0)
    }

    private static func formattedDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = max(Int(duration.rounded(.down)), 0)
        let hours = totalSeconds / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }

        return String(format: "%02d:%02d", minutes, seconds)
    }
}

private struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.sectionHeader)
                .accessibilityAddTraits(.isHeader)
            Text(subtitle)
                .font(.brandSubheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct ToolCard<Content: View>: View {
    let title: String
    let subtitle: String
    let content: Content

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(title)
                .font(.cardTitle)

            Text(subtitle)
                .font(.cardBody)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            content
        }
        .padding(Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.osaSurface, in: RoundedRectangle(cornerRadius: CornerRadius.xl))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.xl)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
    }
}

private struct ToolActionButton: View {
    let title: String
    let systemImage: String
    let tint: Color
    var isProminent = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: systemImage)
                    .font(.headline)
                Text(title)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .foregroundStyle(isProminent ? Color.white : tint)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 58, alignment: .leading)
            .background(
                isProminent ? tint : tint.opacity(0.12),
                in: RoundedRectangle(cornerRadius: CornerRadius.lg)
            )
            .overlay {
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(tint.opacity(0.28), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

private struct SignalStatusTile: View {
    let title: String
    let subtitle: String
    let isActive: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(title)
                .font(.sectionHeader)
                .foregroundStyle(isActive ? .white : .primary)

            Text(subtitle)
                .font(.brandSubheadline)
                .foregroundStyle(isActive ? Color.white.opacity(0.88) : .secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isActive ? Color.osaPrimary : Color.osaCanopy.opacity(0.12),
            in: RoundedRectangle(cornerRadius: CornerRadius.lg)
        )
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke((isActive ? Color.white : Color.osaHairline).opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PresetButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(isSelected ? Color.white : Color.osaPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.sm)
                .background(
                    isSelected ? Color.osaPrimary : Color.osaPrimary.opacity(0.1),
                    in: RoundedRectangle(cornerRadius: CornerRadius.md)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct RadioReferenceRow: View {
    let entry: SurvivalToolKit.RadioReferenceEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(entry.title)
                .font(.sectionHeader)

            Text(entry.frequency)
                .font(.brandEyebrow)
                .foregroundStyle(.osaPrimary)

            Text(entry.usage)
                .font(.brandSubheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            Text(entry.caution)
                .font(.metadataCaption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.md)
        .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(Color.osaHairline, lineWidth: 1)
        }
    }
}

private struct BrightScreenUtilityView: View {
    let mode: SurvivalToolsScreen.BrightScreenMode

    @Environment(\.dismiss) private var dismiss
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService
    @State private var morseSignalPlayer = MorseSignalPlayer()
    @State private var previousBrightness: CGFloat?

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            if mode == .mirror {
                mirrorReticle
            }

            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack {
                    Spacer()
                    Button("Exit") {
                        dismiss()
                    }
                    .font(.headline)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(.black.opacity(0.18), in: Capsule())
                    .foregroundStyle(mode == .sos && !morseSignalPlayer.isPulseActive ? Color.white : Color.black)
                }

                Spacer()

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(mode.title)
                        .font(.stressTitle)
                    Text(mode.note)
                        .font(.brandSubheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(mode == .sos && !morseSignalPlayer.isPulseActive ? Color.white : Color.black)
                .padding(Spacing.lg)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius.xl))
            }
            .padding(Spacing.lg)
        }
        .preferredColorScheme(.light)
        .onAppear {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1

            if mode == .sos {
                morseSignalPlayer.play(
                    tokens: SurvivalToolKit.encodeMorse("SOS").tokens,
                    repeats: true,
                    haptics: hapticFeedbackService
                )
            }
        }
        .onDisappear {
            morseSignalPlayer.stop()
            if let previousBrightness {
                UIScreen.main.brightness = previousBrightness
            }
        }
    }

    @ViewBuilder
    private var backgroundLayer: some View {
        switch mode {
        case .flashlight, .mirror:
            Color.white
        case .sos:
            if morseSignalPlayer.isPulseActive {
                Color.white
            } else {
                Color.osaNight
            }
        }
    }

    private var mirrorReticle: some View {
        ZStack {
            Circle()
                .stroke(Color.black.opacity(0.68), lineWidth: 3)
                .frame(width: 220, height: 220)
            Circle()
                .stroke(Color.black.opacity(0.4), lineWidth: 1)
                .frame(width: 110, height: 110)
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 2, height: 260)
            Rectangle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 260, height: 2)
            Circle()
                .fill(Color.osaEmergency)
                .frame(width: 16, height: 16)
        }
        .accessibilityHidden(true)
    }
}
