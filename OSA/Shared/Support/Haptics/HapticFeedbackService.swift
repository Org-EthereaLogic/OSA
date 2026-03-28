import SwiftUI
import UIKit

enum AppHapticEvent {
    case emergencyEntry
    case emergencyPrimaryAction
    case prominentNavigation
    case protocolStepForward
    case protocolStepBackward
    case checklistItemToggle
    case pinToggle
    case askSubmit
    case success
    case warning
    case error
    case cprMetronomeBeat
}

protocol HapticFeedbackService: AnyObject {
    @MainActor func play(_ event: AppHapticEvent)
    @MainActor func prepare(_ event: AppHapticEvent)
}

enum HapticDescriptor: Equatable {
    case impact(style: HapticImpactStyle, intensity: CGFloat)
    case selection
    case notification(HapticNotificationStyle)
}

enum HapticImpactStyle: Equatable {
    case heavy
    case rigid
}

enum HapticNotificationStyle: Equatable {
    case success
    case warning
    case error
}

protocol HapticEngine {
    @MainActor func play(_ descriptor: HapticDescriptor)
    @MainActor func prepare(_ descriptor: HapticDescriptor)
}

@MainActor
final class LiveHapticFeedbackService: HapticFeedbackService {
    private let userDefaults: UserDefaults
    private let engine: HapticEngine

    init(
        userDefaults: UserDefaults = .standard,
        engine: HapticEngine = UIKitHapticEngine()
    ) {
        self.userDefaults = userDefaults
        self.engine = engine
    }

    func play(_ event: AppHapticEvent) {
        guard isEnabled else { return }
        engine.play(descriptor(for: event))
    }

    func prepare(_ event: AppHapticEvent) {
        guard isEnabled else { return }
        engine.prepare(descriptor(for: event))
    }

    func descriptor(for event: AppHapticEvent) -> HapticDescriptor {
        switch event {
        case .emergencyEntry, .emergencyPrimaryAction:
            .impact(style: .heavy, intensity: 1.0)
        case .prominentNavigation, .protocolStepForward:
            .impact(style: .rigid, intensity: 0.85)
        case .cprMetronomeBeat:
            .impact(style: .rigid, intensity: 0.9)
        case .protocolStepBackward, .checklistItemToggle, .pinToggle, .askSubmit:
            .selection
        case .success:
            .notification(.success)
        case .warning:
            .notification(.warning)
        case .error:
            .notification(.error)
        }
    }

    private var isEnabled: Bool {
        if let stored = userDefaults.object(forKey: AccessibilitySettings.criticalHapticsKey) as? Bool {
            return stored
        }
        return AccessibilitySettings.criticalHapticsDefault
    }
}

protocol HapticGeneratorFactory {
    @MainActor func makeImpactGenerator(style: HapticImpactStyle) -> any ImpactFeedbackGenerating
    @MainActor func makeSelectionGenerator() -> any SelectionFeedbackGenerating
    @MainActor func makeNotificationGenerator() -> any NotificationFeedbackGenerating
}

protocol ImpactFeedbackGenerating: AnyObject {
    @MainActor func prepare()
    @MainActor func impactOccurred(intensity: CGFloat)
}

protocol SelectionFeedbackGenerating: AnyObject {
    @MainActor func prepare()
    @MainActor func selectionChanged()
}

protocol NotificationFeedbackGenerating: AnyObject {
    @MainActor func prepare()
    @MainActor func notificationOccurred(_ style: HapticNotificationStyle)
}

@MainActor
final class UIKitHapticEngine: HapticEngine {
    private let generatorFactory: HapticGeneratorFactory
    private lazy var heavyImpactGenerator = generatorFactory.makeImpactGenerator(style: .heavy)
    private lazy var rigidImpactGenerator = generatorFactory.makeImpactGenerator(style: .rigid)
    private lazy var selectionGenerator = generatorFactory.makeSelectionGenerator()
    private lazy var notificationGenerator = generatorFactory.makeNotificationGenerator()

    init(generatorFactory: HapticGeneratorFactory = UIKitHapticGeneratorFactory()) {
        self.generatorFactory = generatorFactory
    }

    func play(_ descriptor: HapticDescriptor) {
        switch descriptor {
        case .impact(let style, let intensity):
            let generator = impactGenerator(for: style)
            generator.impactOccurred(intensity: intensity)
            generator.prepare()
        case .selection:
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        case .notification(let style):
            notificationGenerator.notificationOccurred(style)
            notificationGenerator.prepare()
        }
    }

    func prepare(_ descriptor: HapticDescriptor) {
        switch descriptor {
        case .impact(let style, _):
            impactGenerator(for: style).prepare()
        case .selection:
            selectionGenerator.prepare()
        case .notification:
            notificationGenerator.prepare()
        }
    }

    private func impactGenerator(for style: HapticImpactStyle) -> any ImpactFeedbackGenerating {
        switch style {
        case .heavy:
            heavyImpactGenerator
        case .rigid:
            rigidImpactGenerator
        }
    }
}

@MainActor
final class UIKitHapticGeneratorFactory: HapticGeneratorFactory {
    func makeImpactGenerator(style: HapticImpactStyle) -> any ImpactFeedbackGenerating {
        let feedbackStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .heavy:
            feedbackStyle = .heavy
        case .rigid:
            feedbackStyle = .rigid
        }
        return UIKitImpactFeedbackGenerator(generator: UIImpactFeedbackGenerator(style: feedbackStyle))
    }

    func makeSelectionGenerator() -> any SelectionFeedbackGenerating {
        UIKitSelectionFeedbackGenerator(generator: UISelectionFeedbackGenerator())
    }

    func makeNotificationGenerator() -> any NotificationFeedbackGenerating {
        UIKitNotificationFeedbackGenerator(generator: UINotificationFeedbackGenerator())
    }
}

@MainActor
private final class UIKitImpactFeedbackGenerator: ImpactFeedbackGenerating {
    private let generator: UIImpactFeedbackGenerator

    init(generator: UIImpactFeedbackGenerator) {
        self.generator = generator
    }

    func prepare() {
        generator.prepare()
    }

    func impactOccurred(intensity: CGFloat) {
        generator.impactOccurred(intensity: intensity)
    }
}

@MainActor
private final class UIKitSelectionFeedbackGenerator: SelectionFeedbackGenerating {
    private let generator: UISelectionFeedbackGenerator

    init(generator: UISelectionFeedbackGenerator) {
        self.generator = generator
    }

    func prepare() {
        generator.prepare()
    }

    func selectionChanged() {
        generator.selectionChanged()
    }
}

@MainActor
private final class UIKitNotificationFeedbackGenerator: NotificationFeedbackGenerating {
    private let generator: UINotificationFeedbackGenerator

    init(generator: UINotificationFeedbackGenerator) {
        self.generator = generator
    }

    func prepare() {
        generator.prepare()
    }

    func notificationOccurred(_ style: HapticNotificationStyle) {
        let feedbackStyle: UINotificationFeedbackGenerator.FeedbackType
        switch style {
        case .success:
            feedbackStyle = .success
        case .warning:
            feedbackStyle = .warning
        case .error:
            feedbackStyle = .error
        }
        generator.notificationOccurred(feedbackStyle)
    }
}

private struct HapticTapModifier: ViewModifier {
    @Environment(\.hapticFeedbackService) private var hapticFeedbackService

    let event: AppHapticEvent

    func body(content: Content) -> some View {
        content.simultaneousGesture(
            TapGesture().onEnded {
                hapticFeedbackService?.play(event)
            }
        )
    }
}

extension View {
    func hapticTap(_ event: AppHapticEvent) -> some View {
        modifier(HapticTapModifier(event: event))
    }
}
