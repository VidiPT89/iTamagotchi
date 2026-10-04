import CoreHaptics
import UIKit

/// Core Haptics patterns with a simple impact fallback on devices without it.
@MainActor
final class Haptics {

    enum Pattern { case tap, soft, success, warning, heartbeat, crack, evolve }

    var isEnabled = true
    private var engine: CHHapticEngine?
    private let supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let notifier = UINotificationFeedbackGenerator()

    func start() {
        guard supportsHaptics, engine == nil else { return }
        engine = try? CHHapticEngine()
        // iOS stops the engine whenever the app loses the foreground.
        engine?.resetHandler = { [weak self] in
            Task { @MainActor [weak self] in try? self?.engine?.start() }
        }
        try? engine?.start()
    }

    func stop() {
        engine?.stop()
        engine = nil
    }

    func play(_ pattern: Pattern) {
        guard isEnabled else { return }
        switch pattern {
        case .tap: light.impactOccurred(intensity: 0.7)
        case .soft: soft.impactOccurred()
        case .success: notifier.notificationOccurred(.success)
        case .warning: notifier.notificationOccurred(.warning)
        case .heartbeat:
            custom([(0, 0.8, 0.3), (0.16, 0.5, 0.2)])
        case .crack:
            custom([(0, 1, 0.9), (0.06, 0.6, 0.8)])
        case .evolve:
            custom((0..<8).map { (Double($0) * 0.09, Float(0.3 + Double($0) * 0.09), Float(0.4)) }, rumble: 0.9)
        }
    }

    /// Transient taps at given times, optionally over a soft rumble.
    private func custom(_ taps: [(TimeInterval, Float, Float)], rumble: TimeInterval = 0) {
        guard supportsHaptics, let engine else {
            soft.impactOccurred()
            return
        }
        var events = taps.map { time, intensity, sharpness in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness),
            ], relativeTime: time)
        }
        if rumble > 0 {
            events.append(CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.45),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2),
            ], relativeTime: 0, duration: rumble))
        }
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern)
        else { return }
        try? player.start(atTime: CHHapticTimeImmediate)
    }
}
