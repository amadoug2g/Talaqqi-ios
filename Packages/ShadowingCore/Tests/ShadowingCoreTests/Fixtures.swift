@testable import ShadowingCore

/// Contenu de test, sans texte : 1 000 trames par seconde pour des calculs lisibles.
enum Fixtures {
    static let sampleRate = 1000.0

    static func clip(_ file: String, _ start: Int, _ end: Int) -> AudioClip {
        AudioClip(file: file, startFrame: start, endFrame: end, sampleRate: sampleRate)
    }

    /// Morceau 0 dans son propre fichier (comme la Basmala), puis trois morceaux d'un même verset :
    /// 1 et 2 séparés par 500 trames de silence d'origine, 2 et 3 contigus.
    ///
    /// Passage complet à vitesse 1 : 5000 + 300 (respiration) + 4000 + 500 + 3500 + 2000 = 15 300 trames.
    static let content = Content(
        id: "test",
        kind: .verse,
        title: "Test",
        subtitle: "",
        arabicName: "",
        surah: 2,
        verseCount: 1,
        verses: [Verse(number: 255, firstPiece: 1, lastPiece: 3)],
        pieces: [
            Piece(index: 0, audio: clip("a.m4a", 0, 5000)),
            Piece(index: 1, verse: 255, audio: clip("b.m4a", 0, 4000)),
            Piece(index: 2, verse: 255, audio: clip("b.m4a", 4500, 8000)),
            Piece(index: 3, verse: 255, audio: clip("b.m4a", 8000, 10000)),
        ]
    )

    static func settings(
        repetitions: Repetitions = .times(3),
        gap: Double = 1,
        echo: Bool = false,
        rate: Double = 1
    ) -> PlaybackSettings {
        var settings = PlaybackSettings()
        settings.repetitions = repetitions
        settings.gapSeconds = gap
        settings.echo = echo
        settings.rate = rate
        return settings
    }

    static func plan(
        _ selection: PieceSelection = .whole(pieceCount: 4),
        _ settings: PlaybackSettings = settings()
    ) -> PlaybackPlan {
        PlaybackPlan(content: content, selection: selection, settings: settings)!
    }
}
