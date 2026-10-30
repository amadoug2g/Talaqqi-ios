import Foundation
import Observation
import ShadowingCore

/// Les textes affichés. Le mode mémoire masque les morceaux déjà acquis de la sélection.
struct DisplayOptions: Equatable {
    var phonetic = true
    var arabic = true
    var translation = true
    var memory = false
}

/// L'état de l'écran de pratique : la sélection, les réglages et le lien avec le lecteur.
@Observable
final class PracticeSession {
    let content: Content
    private(set) var selection = PieceSelection(0)
    var settings = PlaybackSettings()
    private(set) var display = DisplayOptions()
    /// Morceaux masqués que l'on a choisi de voir, jusqu'au prochain changement de sélection.
    private(set) var revealed: Set<Int> = []
    let player = ShadowingPlayer.shared

    init(content: Content) {
        self.content = content
    }

    var isActive: Bool { player.contentID == content.id && player.state != .stopped }
    var isPlaying: Bool { isActive && player.state == .playing }

    func snapshot() -> PlaybackSnapshot {
        guard isActive, let plan = player.plan else { return PlaybackSnapshot(plan: nil, frame: 0) }
        return PlaybackSnapshot(plan: plan, frame: player.currentFrame())
    }

    /// Le plan de la sélection, même à l'arrêt : il donne la durée et la frise.
    var previewPlan: PlaybackPlan? {
        PlaybackPlan(content: content, selection: selection, settings: settings)
    }

    func isMasked(_ index: Int) -> Bool {
        display.memory && selection.contains(index) && index != selection.end && !revealed.contains(index)
    }

    func reveal(_ index: Int) {
        revealed.insert(index)
    }

    func toggle(_ option: WritableKeyPath<DisplayOptions, Bool>) {
        display[keyPath: option].toggle()
        if option == \DisplayOptions.memory {
            revealed = []
        }
    }

    var wholeLabel: String {
        content.kind == .surah ? "Toute la sourate" : "Tout le verset"
    }

    // MARK: Sélection

    func tap(_ index: Int) { select(selection.tapping(index)) }
    func addNext() { select(selection.addingNext(pieceCount: content.pieceCount)) }
    func removeLast() { select(selection.removingLast()) }
    func selectWhole() { select(.whole(pieceCount: content.pieceCount)) }

    var canAddNext: Bool { selection.canAddNext(pieceCount: content.pieceCount) }
    var canRemoveLast: Bool { selection.canRemoveLast }

    /// Comme dans le prototype : si la lecture était en cours, elle reprend sur la nouvelle sélection.
    private func select(_ new: PieceSelection) {
        guard new != selection else { return }
        let wasPlaying = isPlaying
        selection = new
        revealed = []
        if wasPlaying {
            start()
        } else {
            stop()
        }
    }

    // MARK: Lecture

    func togglePlayback() {
        if isPlaying {
            player.pause()
        } else if isActive {
            player.resume()
        } else {
            start()
        }
    }

    func stop() {
        if isActive {
            player.stop()
        }
    }

    func settingsChanged() {
        if isPlaying {
            start()
        } else {
            stop()
        }
    }

    private func start() {
        player.play(content: content, selection: selection, settings: settings,
                    title: "\(content.title) · \(Format.selection(selection))",
                    artist: (content.reciter ?? ContentLibrary.shared.reciter).name)
    }
}

/// Où en est la lecture à un instant donné, pour l'affichage.
struct PlaybackSnapshot {
    let plan: PlaybackPlan?
    let frame: Int

    var position: PlaybackPosition? { plan?.position(atFrame: frame) }

    var playingPiece: Int? {
        guard case .piece(let index, _)? = position?.phase else { return nil }
        return index
    }

    var turnRemaining: Double? {
        guard case .turn(let remaining, _)? = position?.phase else { return nil }
        return remaining
    }

    var turnProgress: Double {
        guard case .turn(_, let progress)? = position?.phase else { return 0 }
        return progress
    }

    func progress(ofPiece index: Int) -> Double {
        plan?.progress(ofPiece: index, atFrame: frame) ?? 0
    }
}
