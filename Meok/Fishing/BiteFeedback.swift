import AVFoundation
import GameKernel

/// Voices a species' bite envelope as procedural audio. The scene renders the
/// same envelope as bobber motion — one source, two mirrors (spec §2
/// accessibility). No haptics and no audio assets: every sound is synthesized
/// on the fly (pillar 3), and the bobber's tremble carries the bite by sight.
@MainActor
final class BiteFeedback {
    private let audio = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)

    init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
        guard let format else { return }
        audio.attach(player)
        audio.connect(player, to: audio.mainMixerNode, format: format)
        try? audio.start()
        if audio.isRunning { player.play() }
    }

    func playSignature(_ taps: [BiteTap]) {
        for tap in taps {
            Task { [weak self] in
                try? await Task.sleep(nanoseconds: UInt64(tap.offset * 1e9))
                self?.tick(intensity: tap.intensity, sharpness: tap.sharpness, duration: tap.duration)
            }
        }
    }

    /// The sharp "singing line" cue during a fight.
    func sing() {
        tick(intensity: 1, sharpness: 1, duration: 0.2)
    }

    /// The landing splash.
    func splash() {
        tick(intensity: 0.8, sharpness: 0.1, duration: 0.3)
    }

    /// A short decaying sine "plop" — procedural, no audio assets. Silent
    /// when the player turns Sound off in settings (absent key defaults on).
    private func tick(intensity: Double, sharpness: Double, duration: Double) {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "meok-audio") != nil, !defaults.bool(forKey: "meok-audio") { return }
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
