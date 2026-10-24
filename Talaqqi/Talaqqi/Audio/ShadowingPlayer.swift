import AVFoundation
import MediaPlayer
import Observation
import ShadowingCore

/// Joue un plan de lecture : morceaux, silences et répétitions sont programmés à l'avance dans
/// le lecteur, à l'échantillon près. Aucun minuteur : la boucle continue écran éteint.
@Observable
final class ShadowingPlayer {
    enum State {
        case stopped, playing, paused
    }

    static let shared = ShadowingPlayer()

    private(set) var state: State = .stopped
    private(set) var plan: PlaybackPlan?
    private(set) var contentID: String?
    private(set) var errorMessage: String?

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let timePitch = AVAudioUnitTimePitch()
    @ObservationIgnored private var connectedFormat: AVAudioFormat?
    @ObservationIgnored private var buffers: PieceBuffers?
    @ObservationIgnored private var scheduledRepetitions = 0
    @ObservationIgnored private var completedRepetitions = 0
    /// Change à chaque arrêt : les rappels d'une lecture précédente sont ignorés.
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var lastFrame = 0
    @ObservationIgnored private var interrupted = false
    @ObservationIgnored private var title = ""
    @ObservationIgnored private var artist = ""
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    private init() {
        engine.attach(player)
        engine.attach(timePitch)
        if let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) {
            connect(format: format)
        }
        observeSystem()
        setUpRemoteCommands()
    }

    // MARK: Commandes

    func play(content: Content, selection: PieceSelection, settings: PlaybackSettings, title: String, artist: String) {
        stop()
        errorMessage = nil
        guard let plan = PlaybackPlan(content: content, selection: selection, settings: settings) else { return }
        do {
            let buffers = try PieceBuffers(content: content)
            connect(format: buffers.format)
            timePitch.rate = Float(plan.rate)
            try AudioSessionSetup.activate()
            if !engine.isRunning {
                try engine.start()
            }
            self.buffers = buffers
            self.plan = plan
            self.contentID = content.id
            self.title = title
            self.artist = artist
            try scheduleAhead()
            player.play()
            state = .playing
            updateNowPlaying()
        } catch {
            stop()
            errorMessage = error.localizedDescription
        }
    }

    func pause() {
        guard state == .playing else { return }
        lastFrame = currentFrame()
        player.pause()
        state = .paused
        updateNowPlaying()
    }

    func resume() {
        guard state == .paused else { return }
        do {
            try AudioSessionSetup.activate()
            if !engine.isRunning {
                try engine.start()
            }
            player.play()
            state = .playing
            updateNowPlaying()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        generation += 1
        player.stop()
        state = .stopped
        plan = nil
        buffers = nil
        scheduledRepetitions = 0
        completedRepetitions = 0
        lastFrame = 0
        interrupted = false
        updateNowPlaying()
    }

    /// Trames déjà jouées depuis le début du plan, au rythme du lecteur (avant le changement de vitesse).
    func currentFrame() -> Int {
        guard state == .playing,
              let nodeTime = player.lastRenderTime,
              let playerTime = player.playerTime(forNodeTime: nodeTime)
        else { return lastFrame }
        lastFrame = max(0, Int(playerTime.sampleTime))
        return lastFrame
    }

    // MARK: Programmation

    private func connect(format: AVAudioFormat) {
        guard connectedFormat != format else { return }
        if engine.isRunning {
            engine.stop()
        }
        engine.disconnectNodeOutput(player)
        engine.disconnectNodeOutput(timePitch)
        engine.connect(player, to: timePitch, format: format)
        engine.connect(timePitch, to: engine.mainMixerNode, format: format)
        connectedFormat = format
    }

    /// Répétitions finies : tout est programmé d'un coup. Boucle infinie : deux tours d'avance.
    private func scheduleAhead() throws {
        guard let plan, let buffers else { return }
        let target = plan.repetitions.count ?? completedRepetitions + 2
        while scheduledRepetitions < target {
            let repetition = scheduledRepetitions
            var queue: [AVAudioPCMBuffer] = []
            for item in plan.items(forRepetition: repetition) {
                switch item.kind {
                case .piece(let index):
                    queue.append(try buffers.piece(index))
                case .pause:
                    if let silence = buffers.silence(frames: item.frameCount) {
                        queue.append(silence)
                    }
                }
            }
            for (offset, buffer) in queue.enumerated() {
                if offset == queue.count - 1 {
                    player.scheduleBuffer(buffer, at: nil, options: [], completionCallbackType: .dataPlayedBack,
                                          completionHandler: Self.repetitionHandler(for: self, generation: generation, repetition: repetition))
                } else {
                    player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
                }
            }
            scheduledRepetitions += 1
        }
    }

    /// Créé hors de l'acteur principal : le lecteur appelle ce rappel sur son propre fil.
    nonisolated private static func repetitionHandler(for owner: ShadowingPlayer, generation: Int, repetition: Int) -> AVAudioPlayerNodeCompletionHandler {
        { [weak owner] _ in
            Task { @MainActor in
                owner?.repetitionPlayed(repetition, generation: generation)
            }
        }
    }

    private func repetitionPlayed(_ repetition: Int, generation: Int) {
        guard generation == self.generation, let plan else { return }
        completedRepetitions = max(completedRepetitions, repetition + 1)
        if let count = plan.repetitions.count, completedRepetitions >= count {
            stop()
            return
        }
        do {
            try scheduleAhead()
        } catch {
            stop()
            errorMessage = error.localizedDescription
        }
    }

    // MARK: Système

    private func observeSystem() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let rawType = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let rawOptions = note.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt ?? 0
            MainActor.assumeIsolated {
                self?.handleInterruption(rawType: rawType, rawOptions: rawOptions)
            }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            let rawReason = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt
            MainActor.assumeIsolated {
                // Écouteurs débranchés : on met en pause plutôt que de jouer sur le haut-parleur.
                if rawReason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue {
                    self?.pause()
                }
            }
        })
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.pause()
            }
        })
    }

    private func handleInterruption(rawType: UInt?, rawOptions: UInt) {
        switch rawType.flatMap(AVAudioSession.InterruptionType.init(rawValue:)) {
        case .began?:
            if state == .playing {
                pause()
                interrupted = true
            }
        case .ended?:
            let options = AVAudioSession.InterruptionOptions(rawValue: rawOptions)
            if interrupted && options.contains(.shouldResume) {
                resume()
            }
            interrupted = false
        default:
            break
        }
    }

    private func setUpRemoteCommands() {
        let commands = MPRemoteCommandCenter.shared()
        commands.playCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.resume() }
            return .success
        }
        commands.pauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.pause() }
            return .success
        }
        commands.togglePlayPauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                if self.state == .playing { self.pause() } else { self.resume() }
            }
            return .success
        }
    }

    private func updateNowPlaying() {
        let center = MPNowPlayingInfoCenter.default()
        guard state != .stopped, let plan else {
            center.nowPlayingInfo = nil
            return
        }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: title,
            MPMediaItemPropertyArtist: artist,
            MPNowPlayingInfoPropertyPlaybackRate: state == .playing ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: plan.seconds(lastFrame),
        ]
        if let total = plan.totalFrames {
            info[MPMediaItemPropertyPlaybackDuration] = plan.seconds(total)
        }
        center.nowPlayingInfo = info
    }
}

/// Catégorie « lecture » : le son sort sur le haut-parleur même en mode silencieux,
/// et continue en arrière-plan (mode audio déclaré dans Talaqqi-Info.plist).
enum AudioSessionSetup {
    static func activate() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .spokenAudio)
        try session.setActive(true)
    }
}
