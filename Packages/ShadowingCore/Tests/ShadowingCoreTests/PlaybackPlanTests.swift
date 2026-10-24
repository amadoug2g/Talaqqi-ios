import Testing
@testable import ShadowingCore

struct PlaybackPlanTests {
    // MARK: Construction du passage

    @Test func passOrdersPiecesAndSilences() {
        let plan = Fixtures.plan()
        #expect(plan.pass.map(\.kind) == [
            .piece(0), .pause(.breath), .piece(1), .pause(.join), .piece(2), .piece(3),
        ])
        #expect(plan.pass.map(\.frameCount) == [5000, 300, 4000, 500, 3500, 2000])
        #expect(plan.pass.map(\.startFrame) == [0, 5000, 5300, 9300, 9800, 13300])
        #expect(plan.passFrames == 15_300)
    }

    @Test func contiguousPiecesOfTheSameFileHaveNoSilence() {
        let plan = Fixtures.plan(PieceSelection(start: 2, end: 3))
        #expect(plan.pass.map(\.kind) == [.piece(2), .piece(3)])
        #expect(plan.passFrames == 5500)
    }

    @Test func singlePieceHasNoSilence() {
        let plan = Fixtures.plan(PieceSelection(1))
        #expect(plan.pass.map(\.kind) == [.piece(1)])
    }

    @Test func breathAndTurnLastTheSameRealTimeAtAnyRate() {
        let plan = Fixtures.plan(.whole(pieceCount: 4), Fixtures.settings(gap: 1, rate: 0.75))
        // 0,3 s et 1 s réelles : la vitesse étire les silences, on compte donc moins de trames.
        #expect(plan.pass[1].frameCount == 225)
        #expect(plan.turnFrames == 750)
        #expect(plan.turnSeconds == 1)
        // Le silence d'origine entre deux morceaux reste en trames source : il ralentit avec la voix.
        #expect(plan.pass[3].frameCount == 500)
    }

    @Test func turnUsesTheGapSetting() {
        #expect(Fixtures.plan(.whole(pieceCount: 4), Fixtures.settings(gap: 2.5)).turnFrames == 2500)
        #expect(Fixtures.plan(.whole(pieceCount: 4), Fixtures.settings(gap: 0)).turnFrames == 0)
    }

    @Test func echoTurnIsAsLongAsThePassPlusAMargin() {
        let plan = Fixtures.plan(.whole(pieceCount: 4), Fixtures.settings(gap: 4, echo: true))
        #expect(plan.turnFrames == 15_300 + 300)
    }

    @Test func emptyOrMixedSampleRatesGiveNoPlan() {
        var mixed = Fixtures.content
        mixed.pieces[1].audio.sampleRate = 44_100
        #expect(PlaybackPlan(content: mixed, selection: PieceSelection(start: 0, end: 1), settings: Fixtures.settings()) == nil)

        var empty = Fixtures.content
        empty.pieces = []
        #expect(PlaybackPlan(content: empty, selection: PieceSelection(0), settings: Fixtures.settings()) == nil)
    }

    @Test func outOfBoundsSelectionIsClamped() {
        let plan = Fixtures.plan(PieceSelection(start: 2, end: 20))
        #expect(plan.selection == PieceSelection(start: 2, end: 3))
    }

    // MARK: Répétitions

    @Test func noTurnAfterTheLastRepetition() {
        let plan = Fixtures.plan()
        #expect(plan.totalFrames == 3 * 15_300 + 2 * 1000)
        #expect(plan.items(forRepetition: 0).last?.kind == .pause(.turn))
        #expect(plan.items(forRepetition: 2).last?.kind == .piece(3))
        #expect(plan.items(forRepetition: 3).isEmpty)
    }

    @Test func singleRepetitionHasNoTurn() {
        let plan = Fixtures.plan(.whole(pieceCount: 4), Fixtures.settings(repetitions: .times(1)))
        #expect(plan.totalFrames == 15_300)
        #expect(!plan.items(forRepetition: 0).contains(where: { $0.kind == .pause(.turn) }))
    }

    @Test func infiniteRepetitionsAlwaysHaveATurn() {
        let plan = Fixtures.plan(.whole(pieceCount: 4), Fixtures.settings(repetitions: .infinite))
        #expect(plan.totalFrames == nil)
        let items = plan.items(forRepetition: 10)
        #expect(items.last?.kind == .pause(.turn))
        #expect(items.first?.startFrame == 10 * 16_300)
        #expect(items.allSatisfy({ $0.repetition == 10 }))
    }

    @Test func repetitionItemsFollowEachOtherWithoutGaps() {
        let plan = Fixtures.plan()
        var cursor = 0
        for repetition in 0..<3 {
            for item in plan.items(forRepetition: repetition) {
                #expect(item.startFrame == cursor)
                cursor = item.endFrame
            }
        }
        #expect(cursor == plan.totalFrames)
    }

    // MARK: Position

    @Test func positionInsideAPiece() {
        let plan = Fixtures.plan()
        #expect(plan.position(atFrame: 0) == PlaybackPosition(repetition: 0, phase: .piece(index: 0, progress: 0), passElapsedSeconds: 0))
        #expect(plan.position(atFrame: 7300) == PlaybackPosition(repetition: 0, phase: .piece(index: 1, progress: 0.5), passElapsedSeconds: 7.3))
    }

    @Test func positionInsideSilencesBetweenPieces() {
        let plan = Fixtures.plan()
        #expect(plan.position(atFrame: 5100).phase == .silence(.breath))
        #expect(plan.position(atFrame: 9500).phase == .silence(.join))
    }

    @Test func positionDuringTheTurnCountsDown() {
        let plan = Fixtures.plan()
        #expect(plan.position(atFrame: 15_300) == PlaybackPosition(
            repetition: 0, phase: .turn(remainingSeconds: 1, progress: 0), passElapsedSeconds: 15.3))
        #expect(plan.position(atFrame: 15_800).phase == .turn(remainingSeconds: 0.5, progress: 0.5))
    }

    @Test func positionInTheSecondRepetition() {
        let plan = Fixtures.plan()
        let position = plan.position(atFrame: 16_300)
        #expect(position.repetition == 1)
        #expect(position.phase == .piece(index: 0, progress: 0))
    }

    @Test func positionAfterTheLastRepetitionIsFinished() {
        let plan = Fixtures.plan()
        let position = plan.position(atFrame: plan.totalFrames!)
        #expect(position.phase == .finished)
        #expect(position.repetition == 2)
    }

    @Test func pieceProgressForTheTimelineAndRows() {
        let plan = Fixtures.plan()
        #expect(plan.progress(ofPiece: 0, atFrame: 7300) == 1)
        #expect(plan.progress(ofPiece: 1, atFrame: 7300) == 0.5)
        #expect(plan.progress(ofPiece: 2, atFrame: 7300) == 0)
        // Pendant « À toi », toute la frise est pleine.
        #expect(plan.progress(ofPiece: 3, atFrame: 15_800) == 1)
        // Au début de la répétition suivante, elle repart de zéro.
        #expect(plan.progress(ofPiece: 0, atFrame: 16_300) == 0)
        // Morceau hors sélection.
        #expect(Fixtures.plan(PieceSelection(1)).progress(ofPiece: 2, atFrame: 0) == 0)
    }

    @Test func pieceDurationsAreInRealSeconds() {
        #expect(Fixtures.plan().duration(ofPiece: 2) == 3.5)
        #expect(Fixtures.plan(.whole(pieceCount: 4), Fixtures.settings(rate: 0.5)).duration(ofPiece: 2) == 7)
    }

    @Test func firstPassCompletion() {
        let plan = Fixtures.plan()
        #expect(!plan.hasCompletedFirstPass(atFrame: 15_299))
        #expect(plan.hasCompletedFirstPass(atFrame: 15_300))
    }
}
