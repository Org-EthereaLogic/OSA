import SwiftUI
import XCTest
@testable import OSA

final class HapticFeedbackServiceTests: XCTestCase {

    @MainActor
    func testDisabledSettingSkipsPlayAndPrepare() {
        let defaults = makeUserDefaults()
        defaults.set(false, forKey: AccessibilitySettings.criticalHapticsKey)

        let engine = RecordingHapticEngine()
        let service = LiveHapticFeedbackService(userDefaults: defaults, engine: engine)

        service.play(.emergencyEntry)
        service.prepare(.cprMetronomeBeat)

        XCTAssertTrue(engine.played.isEmpty)
        XCTAssertTrue(engine.prepared.isEmpty)
    }

    @MainActor
    func testPlayUsesMappedDescriptorWhenEnabled() {
        let defaults = makeUserDefaults()
        defaults.set(true, forKey: AccessibilitySettings.criticalHapticsKey)

        let engine = RecordingHapticEngine()
        let service = LiveHapticFeedbackService(userDefaults: defaults, engine: engine)

        service.play(.prominentNavigation)

        XCTAssertEqual(engine.played, [.impact(style: .rigid, intensity: 0.85)])
    }

    @MainActor
    func testEventMappingUsesExpectedDescriptors() {
        let service = LiveHapticFeedbackService(
            userDefaults: makeUserDefaults(),
            engine: RecordingHapticEngine()
        )

        let expectations: [(AppHapticEvent, HapticDescriptor)] = [
            (.emergencyEntry, .impact(style: .heavy, intensity: 1.0)),
            (.emergencyPrimaryAction, .impact(style: .heavy, intensity: 1.0)),
            (.prominentNavigation, .impact(style: .rigid, intensity: 0.85)),
            (.protocolStepForward, .impact(style: .rigid, intensity: 0.85)),
            (.protocolStepBackward, .selection),
            (.checklistItemToggle, .selection),
            (.pinToggle, .selection),
            (.askSubmit, .selection),
            (.success, .notification(.success)),
            (.warning, .notification(.warning)),
            (.error, .notification(.error)),
            (.cprMetronomeBeat, .impact(style: .rigid, intensity: 0.9))
        ]

        for (event, expectedDescriptor) in expectations {
            XCTAssertEqual(service.descriptor(for: event), expectedDescriptor)
        }
    }

    @MainActor
    func testCPRMetronomeBeatUsesCachedRigidImpactGenerator() {
        let factory = RecordingHapticGeneratorFactory()
        let engine = UIKitHapticEngine(generatorFactory: factory)
        let descriptor = HapticDescriptor.impact(style: .rigid, intensity: 0.9)

        engine.prepare(descriptor)
        engine.play(descriptor)
        engine.play(descriptor)

        XCTAssertEqual(factory.impactRequests, [.rigid])
        XCTAssertEqual(factory.rigidGenerator.intensities, [0.9, 0.9])
        XCTAssertEqual(factory.rigidGenerator.prepareCount, 3)
        XCTAssertEqual(factory.heavyGenerator.intensities.count, 0)
        XCTAssertEqual(factory.selectionGenerator.selectionCount, 0)
        XCTAssertEqual(factory.notificationGenerator.notifications.count, 0)
    }

    func testEnvironmentDefaultsHapticServiceToNil() {
        let environment = EnvironmentValues()
        XCTAssertNil(environment.hapticFeedbackService)
    }

    @MainActor
    private func makeUserDefaults() -> UserDefaults {
        let suiteName = "HapticFeedbackServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

@MainActor
private final class RecordingHapticEngine: HapticEngine {
    private(set) var played: [HapticDescriptor] = []
    private(set) var prepared: [HapticDescriptor] = []

    func play(_ descriptor: HapticDescriptor) {
        played.append(descriptor)
    }

    func prepare(_ descriptor: HapticDescriptor) {
        prepared.append(descriptor)
    }
}

@MainActor
private final class RecordingHapticGeneratorFactory: HapticGeneratorFactory {
    let heavyGenerator = RecordingImpactGenerator()
    let rigidGenerator = RecordingImpactGenerator()
    let selectionGenerator = RecordingSelectionGenerator()
    let notificationGenerator = RecordingNotificationGenerator()

    private(set) var impactRequests: [HapticImpactStyle] = []

    func makeImpactGenerator(style: HapticImpactStyle) -> any ImpactFeedbackGenerating {
        impactRequests.append(style)
        switch style {
        case .heavy:
            return heavyGenerator
        case .rigid:
            return rigidGenerator
        }
    }

    func makeSelectionGenerator() -> any SelectionFeedbackGenerating {
        return selectionGenerator
    }

    func makeNotificationGenerator() -> any NotificationFeedbackGenerating {
        return notificationGenerator
    }
}

@MainActor
private final class RecordingImpactGenerator: ImpactFeedbackGenerating {
    private(set) var prepareCount = 0
    private(set) var intensities: [CGFloat] = []

    func prepare() {
        prepareCount += 1
    }

    func impactOccurred(intensity: CGFloat) {
        intensities.append(intensity)
    }
}

@MainActor
private final class RecordingSelectionGenerator: SelectionFeedbackGenerating {
    private(set) var prepareCount = 0
    private(set) var selectionCount = 0

    func prepare() {
        prepareCount += 1
    }

    func selectionChanged() {
        selectionCount += 1
    }
}

@MainActor
private final class RecordingNotificationGenerator: NotificationFeedbackGenerating {
    private(set) var prepareCount = 0
    private(set) var notifications: [HapticNotificationStyle] = []

    func prepare() {
        prepareCount += 1
    }

    func notificationOccurred(_ style: HapticNotificationStyle) {
        notifications.append(style)
    }
}
