import AVFoundation

/// Everything the app can say out loud.
enum Sound: CaseIterable {
    case tap, chomp, chirp, sad, bubble, sweep, medicine, lights, scold, refuse
    case coin, win, lose, crack, hatch, evolve, star, hit, miss, farewell, achievement, cuddle
    case padC, padE, padG, padHigh
}

/// A tiny synthesiser. Every sound is generated into a PCM buffer on first
/// use, so the app ships no audio files at all.
///
/// Talking to the system audio service can stall, so none of it happens on
/// the main thread or at launch: the UI and the game never wait for sound.
@MainActor
final class AudioEngine {

    var isSoundEnabled = true
    var isMusicEnabled = true
    private let core = AudioCore()

    func start() {
        let music = isMusicEnabled
        core.run { $0.start(music: music) }
    }

    func stop() {
        core.run { $0.stop() }
    }

    func setMusic(enabled: Bool) {
        isMusicEnabled = enabled
        core.run { $0.setMusic(enabled) }
    }

    func play(_ sound: Sound) {
        guard isSoundEnabled else { return }
        core.run { $0.play(sound) }
    }
}

/// The audio graph itself. Every member is touched only on `queue`.
private final class AudioCore: @unchecked Sendable {

    private let queue = DispatchQueue(label: "dev.ividi.itamagotchi.audio", qos: .userInitiated)
    private var engine: AVAudioEngine?
    private var voices: [AVAudioPlayerNode] = []
    private var nextVoice = 0
    private let musicPlayer = AVAudioPlayerNode()
    private var musicBuffer: AVAudioPCMBuffer?
    private var buffers: [Sound: AVAudioPCMBuffer] = [:]
    /// One format for the connections and the buffers; a mismatch crashes.
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isRunning = false
    private var musicOn = true
    private var lastPlayed: [Sound: CFTimeInterval] = [:]

    func run(_ work: @escaping @Sendable (AudioCore) -> Void) {
        queue.async { work(self) }
    }

    /// Builds the graph and the sounds the first time they are needed.
    private func prepare() -> AVAudioEngine {
        if let engine { return engine }
        let engine = AVAudioEngine()
        for _ in 0..<8 {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            voices.append(node)
        }
        engine.attach(musicPlayer)
        engine.connect(musicPlayer, to: engine.mainMixerNode, format: format)
        musicPlayer.volume = 0.13
        for sound in Sound.allCases { buffers[sound] = render(Recipe.for(sound)) }
        musicBuffer = renderMusic()

        // Headphones, AirPlay or a phone call stop the engine behind our back;
        // start it again or the app goes quiet until the next launch.
        let center = NotificationCenter.default
        center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil) { [weak self] _ in
            self?.run { $0.restart() }
        }
        center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt)
                .flatMap(AVAudioSession.InterruptionType.init(rawValue:))
            guard type == .ended else { return }
            self?.run { $0.restart() }
        }
        self.engine = engine
        return engine
    }

    private func restart() {
        guard isRunning, let engine, !engine.isRunning else { return }
        isRunning = false
        start(music: musicOn)
    }

    func start(music: Bool) {
        musicOn = music
        guard !isRunning else { return }
        let engine = prepare()
        // Ambient, so the pet never silences the player's own music.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        do {
            try engine.start()
            isRunning = true
            voices.forEach { $0.play() }
            if musicOn { startMusic() }
        } catch {
            isRunning = false
        }
    }

    func stop() {
        guard isRunning, let engine else { return }
        musicPlayer.stop()
        voices.forEach { $0.stop() }
        engine.pause()
        isRunning = false
    }

    func setMusic(_ enabled: Bool) {
        musicOn = enabled
        guard isRunning else { return }
        if enabled { startMusic() } else { musicPlayer.stop() }
    }

    private func startMusic() {
        guard let musicBuffer, !musicPlayer.isPlaying else { return }
        musicPlayer.scheduleBuffer(musicBuffer, at: nil, options: [.loops])
        musicPlayer.play()
    }

    func play(_ sound: Sound) {
        guard isRunning, let buffer = buffers[sound] else { return }
        let now = CACurrentMediaTime()
        if let last = lastPlayed[sound], now - last < 0.05 { return }
        lastPlayed[sound] = now
        let node = voices[nextVoice]
        nextVoice = (nextVoice + 1) % voices.count
        node.volume = Recipe.for(sound).gain
        node.scheduleBuffer(buffer, at: nil, options: [.interrupts])
        if !node.isPlaying { node.play() }
    }

    // MARK: - Synthesis

    private func render(_ recipe: Recipe) -> AVAudioPCMBuffer? {
        let total = recipe.notes.count > 1
            ? recipe.noteLength * Double(recipe.notes.count) + recipe.tail
            : recipe.noteLength
        let frames = AVAudioFrameCount(total * format.sampleRate)
        guard frames > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = frames
        let rate = format.sampleRate
        var phase = 0.0

        for frame in 0..<Int(frames) {
            let t = Double(frame) / rate
            let index = min(recipe.notes.count - 1, Int(t / recipe.noteLength))
            let local = t - Double(index) * recipe.noteLength
            let progress = min(1, local / recipe.noteLength)
            let start = recipe.notes[index]
            let freq = start + (start * recipe.bend - start) * progress
            phase += 2 * .pi * freq / rate
            var value = recipe.wave.sample(phase)
            if recipe.noise > 0 { value += Double.random(in: -1...1) * recipe.noise }
            value *= exp(-recipe.decay * local)
            // Short attack, otherwise every note starts with a click.
            value *= min(1, local / 0.004)
            let fadeOut = max(0, min(1, (total - t) / 0.02))
            samples[frame] = Float(value * fadeOut * 0.6)
        }
        return buffer
    }

    /// A gentle music-box loop in C major pentatonic.
    private func renderMusic() -> AVAudioPCMBuffer? {
        let melody: [Double] = [523.25, 659.25, 783.99, 659.25, 587.33, 523.25, 587.33, 392.00,
                                523.25, 659.25, 880.00, 783.99, 659.25, 587.33, 523.25, 0]
        let bass: [Double] = [130.81, 130.81, 196.00, 196.00, 220.00, 220.00, 174.61, 196.00]
        let beat = 0.42
        let duration = beat * Double(melody.count)
        let frames = AVAudioFrameCount(duration * format.sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames),
              let samples = buffer.floatChannelData?[0]
        else { return nil }
        buffer.frameLength = frames
        let rate = format.sampleRate

        for frame in 0..<Int(frames) {
            let t = Double(frame) / rate
            let step = min(melody.count - 1, Int(t / beat))
            let local = t - Double(step) * beat
            var value = 0.0
            let note = melody[step]
            if note > 0 {
                let env = exp(-3.2 * local) * min(1, local / 0.005)
                value += (sin(2 * .pi * note * t) * 0.6 + sin(2 * .pi * note * 2 * t) * 0.15) * env
            }
            let bassStep = min(bass.count - 1, Int(t / (beat * 2)))
            let bassLocal = t - Double(bassStep) * beat * 2
            value += sin(2 * .pi * bass[bassStep] * t) * 0.3 * exp(-1.5 * bassLocal) * min(1, bassLocal / 0.01)
            let loopFade = min(1, (duration - t) / 0.05, t / 0.05)
            samples[frame] = Float(value * 0.45 * loopFade)
        }
        return buffer
    }

    // MARK: - Recipes

    struct Recipe {
        enum Wave {
            case sine, square, triangle
            func sample(_ phase: Double) -> Double {
                switch self {
                case .sine: return sin(phase)
                case .square: return sin(phase) >= 0 ? 0.55 : -0.55
                case .triangle:
                    let cycle = phase.truncatingRemainder(dividingBy: 2 * .pi) / (2 * .pi)
                    return 4 * abs(cycle - 0.5) - 1
                }
            }
        }

        var wave: Wave = .sine
        var notes: [Double]
        /// Each note glides to `note * bend` over its length.
        var bend: Double = 1
        var noteLength: Double
        var decay: Double
        var noise: Double = 0
        var gain: Float = 0.7
        var tail: Double = 0.15

        static func `for`(_ sound: Sound) -> Recipe {
            switch sound {
            case .tap: return Recipe(notes: [880], bend: 1.3, noteLength: 0.06, decay: 30, gain: 0.3)
            case .chomp: return Recipe(wave: .square, notes: [220], bend: 0.6, noteLength: 0.09, decay: 25, noise: 0.25, gain: 0.45)
            case .chirp: return Recipe(wave: .triangle, notes: [880, 1175], bend: 1.25, noteLength: 0.08, decay: 12, gain: 0.55)
            case .sad: return Recipe(wave: .triangle, notes: [523, 440], bend: 0.9, noteLength: 0.22, decay: 5, gain: 0.5)
            case .bubble: return Recipe(notes: [600, 900, 750, 1100], bend: 1.6, noteLength: 0.07, decay: 22, gain: 0.45)
            case .sweep: return Recipe(notes: [300], bend: 3, noteLength: 0.28, decay: 6, noise: 0.35, gain: 0.35)
            case .medicine: return Recipe(notes: [392, 523, 659], bend: 1.05, noteLength: 0.09, decay: 10, gain: 0.5)
            case .lights: return Recipe(wave: .square, notes: [1400], bend: 0.8, noteLength: 0.03, decay: 60, noise: 0.2, gain: 0.3)
            case .scold: return Recipe(wave: .square, notes: [180, 150], bend: 0.95, noteLength: 0.12, decay: 8, gain: 0.45)
            case .refuse: return Recipe(wave: .triangle, notes: [330, 262], bend: 1, noteLength: 0.1, decay: 12, gain: 0.45)
            case .coin: return Recipe(wave: .square, notes: [988, 1319], bend: 1, noteLength: 0.07, decay: 14, gain: 0.35)
            case .win: return Recipe(wave: .triangle, notes: [523, 659, 784, 1047], bend: 1, noteLength: 0.1, decay: 6, gain: 0.6, tail: 0.3)
            case .lose: return Recipe(wave: .triangle, notes: [392, 330, 262], bend: 0.97, noteLength: 0.14, decay: 6, gain: 0.5)
            case .crack: return Recipe(wave: .square, notes: [1600], bend: 0.4, noteLength: 0.05, decay: 50, noise: 0.6, gain: 0.45)
            case .hatch: return Recipe(wave: .triangle, notes: [523, 784, 1047, 1568], bend: 1.02, noteLength: 0.09, decay: 5, gain: 0.65, tail: 0.4)
            case .evolve: return Recipe(notes: [262, 330, 392, 523, 659, 784, 1047], bend: 1.02, noteLength: 0.11, decay: 3, gain: 0.65, tail: 0.6)
            case .star: return Recipe(notes: [1319, 1760], bend: 1.1, noteLength: 0.06, decay: 16, gain: 0.4)
            case .hit: return Recipe(wave: .triangle, notes: [1047], bend: 1, noteLength: 0.08, decay: 18, gain: 0.5)
            case .miss: return Recipe(wave: .square, notes: [150], bend: 0.8, noteLength: 0.1, decay: 16, noise: 0.2, gain: 0.35)
            case .farewell: return Recipe(notes: [784, 659, 523, 392], bend: 1, noteLength: 0.35, decay: 2.5, gain: 0.5, tail: 1)
            case .achievement: return Recipe(wave: .triangle, notes: [659, 784, 988, 1319], bend: 1, noteLength: 0.08, decay: 7, gain: 0.55, tail: 0.3)
            case .cuddle: return Recipe(notes: [660, 990], bend: 1.15, noteLength: 0.09, decay: 10, gain: 0.45)
            case .padC: return Recipe(wave: .triangle, notes: [523.25], noteLength: 0.32, decay: 5, gain: 0.55)
            case .padE: return Recipe(wave: .triangle, notes: [659.25], noteLength: 0.32, decay: 5, gain: 0.55)
            case .padG: return Recipe(wave: .triangle, notes: [783.99], noteLength: 0.32, decay: 5, gain: 0.55)
            case .padHigh: return Recipe(wave: .triangle, notes: [1046.5], noteLength: 0.32, decay: 5, gain: 0.5)
            }
        }
    }
}
