/// Les silences du plan. Ce sont de vrais silences audio planifiés dans le flux de lecture,
/// jamais des minuteurs, pour que la boucle continue en arrière-plan et écran éteint.
public enum PauseKind: Sendable, Hashable {
    /// Le silence d'origine entre deux morceaux contigus d'un même fichier.
    case join
    /// Une respiration entre deux morceaux de fichiers différents (d'un verset à l'autre).
    case breath
    /// « À toi » : le temps laissé pour répéter, entre deux répétitions.
    case turn
}

public struct PlanItem: Sendable, Hashable {
    public enum Kind: Sendable, Hashable {
        case piece(Int)
        case pause(PauseKind)
    }

    public var kind: Kind
    /// Répétition à laquelle appartient l'élément, à partir de 0.
    public var repetition: Int
    /// Position dans la ligne de temps du plan, en trames source.
    public var startFrame: Int
    public var frameCount: Int

    public var endFrame: Int { startFrame + frameCount }
}

public struct PlaybackPosition: Sendable, Hashable {
    public enum Phase: Sendable, Hashable {
        case piece(index: Int, progress: Double)
        case silence(PauseKind)
        /// `progress` va de 0 à 1 pendant le silence ; le compte à rebours affiche `1 - progress`.
        case turn(remainingSeconds: Double, progress: Double)
        case finished
    }

    /// À partir de 0.
    public var repetition: Int
    public var phase: Phase
    /// Temps réel écoulé dans le passage en cours, plafonné à sa durée pendant « À toi ».
    public var passElapsedSeconds: Double
}

/// Le plan de lecture d'une sélection : l'ordre exact des morceaux et des silences, en trames.
///
/// Les durées sont en trames source, au rythme du lecteur avant le changement de vitesse.
/// Le changement de vitesse étire aussi les silences : pour qu'un silence dure `s` secondes
/// réelles, il compte donc `s × fréquence × vitesse` trames.
public struct PlaybackPlan: Sendable, Hashable {
    public static let breathSeconds = 0.3
    /// Marge ajoutée au silence Écho, comme dans le prototype.
    public static let echoMarginSeconds = 0.3

    public let selection: PieceSelection
    public let repetitions: Repetitions
    public let rate: Double
    public let sampleRate: Double
    /// Un passage de la sélection, positions relatives au début du passage.
    public let pass: [PlanItem]
    public let passFrames: Int
    public let turnFrames: Int

    /// `nil` si le contenu est vide ou si les morceaux n'ont pas tous la même fréquence.
    public init?(content: Content, selection: PieceSelection, settings: PlaybackSettings) {
        let selection = selection.clamped(pieceCount: content.pieceCount)
        guard !content.pieces.isEmpty else { return nil }
        let pieces = content.pieces[selection.indices]
        guard let sampleRate = pieces.first?.audio.sampleRate, sampleRate > 0,
              pieces.allSatisfy({ $0.audio.sampleRate == sampleRate }) else { return nil }
        let rate = settings.rate > 0 ? settings.rate : 1

        func frames(_ seconds: Double) -> Int {
            max(0, Int((seconds * sampleRate * rate).rounded()))
        }

        var items: [PlanItem] = []
        var cursor = 0
        var previous: Piece?
        for piece in pieces {
            if let previous {
                let pause: PauseKind
                let pauseFrames: Int
                if previous.audio.file == piece.audio.file && previous.audio.endFrame <= piece.audio.startFrame {
                    pause = .join
                    pauseFrames = piece.audio.startFrame - previous.audio.endFrame
                } else {
                    pause = .breath
                    pauseFrames = frames(Self.breathSeconds)
                }
                if pauseFrames > 0 {
                    items.append(PlanItem(kind: .pause(pause), repetition: 0, startFrame: cursor, frameCount: pauseFrames))
                    cursor += pauseFrames
                }
            }
            items.append(PlanItem(kind: .piece(piece.index), repetition: 0, startFrame: cursor, frameCount: piece.audio.frameCount))
            cursor += piece.audio.frameCount
            previous = piece
        }
        guard cursor > 0 else { return nil }

        self.selection = selection
        self.repetitions = settings.repetitions
        self.rate = rate
        self.sampleRate = sampleRate
        self.pass = items
        self.passFrames = cursor
        self.turnFrames = settings.echo ? cursor + frames(Self.echoMarginSeconds) : frames(settings.gapSeconds)
    }

    public var periodFrames: Int { passFrames + turnFrames }

    /// `nil` pour une boucle infinie. Pas de silence après la dernière répétition.
    public var totalFrames: Int? {
        guard let n = repetitions.count else { return nil }
        return n * passFrames + (n - 1) * turnFrames
    }

    /// Convertit des trames source en secondes réelles, à la vitesse choisie.
    public func seconds(_ frames: Int) -> Double {
        Double(frames) / sampleRate / rate
    }

    public var passSeconds: Double { seconds(passFrames) }
    public var turnSeconds: Double { seconds(turnFrames) }

    public func hasTurn(after repetition: Int) -> Bool {
        guard turnFrames > 0 else { return false }
        guard let n = repetitions.count else { return true }
        return repetition < n - 1
    }

    /// Les éléments à programmer pour une répétition, positions absolues dans le plan.
    public func items(forRepetition repetition: Int) -> [PlanItem] {
        guard repetition >= 0 else { return [] }
        if let n = repetitions.count, repetition >= n { return [] }
        let offset = repetition * periodFrames
        var result = pass.map { item in
            var item = item
            item.repetition = repetition
            item.startFrame += offset
            return item
        }
        if hasTurn(after: repetition) {
            result.append(PlanItem(kind: .pause(.turn), repetition: repetition, startFrame: offset + passFrames, frameCount: turnFrames))
        }
        return result
    }

    /// Où en est la lecture, à partir du nombre de trames déjà jouées par le lecteur.
    public func position(atFrame frame: Int) -> PlaybackPosition {
        guard let located = locate(frame) else {
            return PlaybackPosition(repetition: max(0, (repetitions.count ?? 1) - 1), phase: .finished, passElapsedSeconds: passSeconds)
        }
        let within = located.frameInPeriod
        if within >= passFrames {
            let elapsed = within - passFrames
            return PlaybackPosition(
                repetition: located.repetition,
                phase: .turn(remainingSeconds: seconds(turnFrames - elapsed), progress: Double(elapsed) / Double(turnFrames)),
                passElapsedSeconds: passSeconds
            )
        }
        let item = pass.first(where: { within < $0.endFrame }) ?? pass[pass.count - 1]
        let phase: PlaybackPosition.Phase
        switch item.kind {
        case .piece(let index):
            phase = .piece(index: index, progress: Double(within - item.startFrame) / Double(max(1, item.frameCount)))
        case .pause(let kind):
            phase = .silence(kind)
        }
        return PlaybackPosition(repetition: located.repetition, phase: phase, passElapsedSeconds: seconds(within))
    }

    /// Avancement d'un morceau dans le passage en cours, de 0 à 1 : 1 pour les morceaux déjà lus
    /// et pendant « À toi », 0 pour ceux qui viennent ensuite.
    public func progress(ofPiece index: Int, atFrame frame: Int) -> Double {
        guard let item = pass.first(where: { $0.kind == .piece(index) }) else { return 0 }
        guard let located = locate(frame) else { return 1 }
        let done = located.frameInPeriod - item.startFrame
        guard item.frameCount > 0 else { return done >= 0 ? 1 : 0 }
        return min(1, max(0, Double(done) / Double(item.frameCount)))
    }

    /// Durée réelle d'un morceau, pour la largeur de son segment dans la frise.
    public func duration(ofPiece index: Int) -> Double {
        guard let item = pass.first(where: { $0.kind == .piece(index) }) else { return 0 }
        return seconds(item.frameCount)
    }

    /// Une écoute compte dans l'historique quand la sélection a été lue en entier une fois.
    public func hasCompletedFirstPass(atFrame frame: Int) -> Bool {
        frame >= passFrames
    }

    private func locate(_ frame: Int) -> (repetition: Int, frameInPeriod: Int)? {
        let frame = max(0, frame)
        if let total = totalFrames, frame >= total { return nil }
        let repetition = frame / periodFrames
        return (repetition, frame - repetition * periodFrames)
    }
}
