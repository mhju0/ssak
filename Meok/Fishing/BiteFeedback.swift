import AVFoundation
import CoreHaptics
import GameKernel

/// Renders a species' bite envelope as haptics and audio. The scene renders
/// the same envelope as bobber motion — one source, three mirrors (spec §2
/// accessibility). Haptics need a physical device; the Simulator plays the
/// audio and visual mirrors only.
@MainActor
final class BiteFeedback {
    private var haptics: CHHapticEngine?
    private let audio = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        if CHHapticEngine.capabilitiesForHardware().supportsHaptics {
            haptics = try? CHHapticEngine()
            try? haptics?.start()
        }
        guard let format else { return }
        audio.attach(player)
        audio.connect(player, to: audio.mainMixerNode, format: format)
        try? audio.start()
        if audio.isRunning { player.play() }
    }

    func playSignature(_ taps: [BiteTap]) {
        playHaptics(taps)
        for tap in taps {
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(tap.offset * 1e9))
                self?.tick(intensity: tap.intensity, sharpness: tap.sharpness, duration: tap.duration)
            }
        }
    }

    /// The sharp "singing line" cue during a fight.
    func sing() {
        playHaptics([BiteTap(offset: 0, intensity: 1, sharpness: 1, duration: 0.15)])
        tick(intensity: 1, sharpness: 1, duration: 0.2)
    }

    /// The landing splash.
    func splash() {
        playHaptics([BiteTap(offset: 0, intensity: 0.8, sharpness: 0.15, duration: 0.3)])
        tick(intensity: 0.8, sharpness: 0.1, duration: 0.3)
    }

    private func playHaptics(_ taps: [BiteTap]) {
        guard let haptics else { return }
        let events = taps.map { tap in
            CHHapticEvent(
                eventType: tap.duration > 0.15 ? .hapticContinuous : .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(tap.intensity)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(tap.sharpness)),
                ],
                relativeTime: tap.offset,
                duration: tap.duration)
        }
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let patternPlayer = try? haptics.makePlayer(with: pattern) else { return }
        try? patternPlayer.start(atTime: 0)
    }

    /// A short decaying sine "plop" — procedural, no audio assets (pillar 3
    /// extends to sound: if it can't be synthesized, it waits for M3's
    /// curated stems).
    private func tick(intensity: Double, sharpness: Double, duration: Double) {
        guard audio.isRunning, let format else { return }
        let sampleRate = format.sampleRate
        let frames = AVAudioFrameCount(sampleRate * max(0.05, min(duration, 0.35)))
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let channel = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = frames

        let frequency = 220 + 660 * sharpness
        let amplitude = Float(0.08 + 0.22 * intensity)
        for frame in 0..<Int(frames) {
            let t = Double(frame) / sampleRate
            channel[frame] = Float(sin(2 * .pi * frequency * t) * exp(-t * 16)) * amplitude
        }
        player.scheduleBuffer(buffer)
    }
}
