//
//  VectorAudio.swift
//  Vectors
//
//  Created by Marcus Titton on 13/10/26.
//

import AVFoundation

/// Lightweight synthesizer: no asset dependencies or background music.
/// All signals are non-blocking and respect the device's silent mode via .ambient.
final class VectorAudio {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Double = 44_100
    private var available = false

    init() {
        engine.attach(player)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        engine.connect(player, to: engine.mainMixerNode, format: format)
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try engine.start()
            player.play()
            available = true
        } catch {
            available = false
        }
    }

    func play(_ effect: GameEffect) {
        guard available else { return }
        let fundamental: Double
        let duration: Double
        let sweep: Double
        let volume: Double
        let secondNote: Double

        switch effect {
        case .redirect:
            fundamental = 450; duration = 0.076; sweep = 0.18; volume = 0.065; secondNote = 0
        case .match:
            fundamental = 650; duration = 0.19; sweep = 0.24; volume = 0.095; secondNote = 0
        case .combo(let level):
            fundamental = 685 + Double(min(level, 12)) * 34
            duration = 0.25; sweep = 0.10; volume = 0.10; secondNote = 1.50
        case .damage:
            fundamental = 220; duration = 0.24; sweep = -0.42; volume = 0.10; secondNote = 0
        case .record:
            fundamental = 880; duration = 0.43; sweep = 0.09; volume = 0.105; secondNote = 1.50
        case .gameOver:
            fundamental = 330; duration = 0.33; sweep = -0.38; volume = 0.09; secondNote = 0
        }

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }
        let count = AVAudioFrameCount(duration * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count),
              let data = buffer.floatChannelData?[0] else { return }
        buffer.frameLength = count
        for i in 0..<Int(count) {
            let t = Double(i) / sampleRate
            let progress = t / duration
            let attack = min(1.0, t / 0.007)
            let envelope = attack * pow(max(0, 1 - progress), 2.0)
            let freq = fundamental * (1 + sweep * progress)
            let main = sin(2 * .pi * freq * t)
            let overtone = sin(2 * .pi * freq * 2.02 * t) * 0.13
            var chord = 0.0
            if secondNote > 0, t > 0.055 {
                let chordAttack = min(1.0, (t - 0.055) / 0.011)
                chord = sin(2 * .pi * freq * secondNote * (t - 0.055)) * 0.46 * chordAttack
            }
            data[i] = Float((main + overtone + chord) * envelope * volume)
        }
        if !engine.isRunning { try? engine.start() }
        if !player.isPlaying { player.play() }
        player.scheduleBuffer(buffer, completionHandler: nil)
    }
}
