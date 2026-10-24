import Testing
@testable import ShadowingCore

struct SelectionTests {
    @Test func initNormalizesOrderAndNegativeIndices() {
        #expect(PieceSelection(start: 4, end: 2) == PieceSelection(start: 2, end: 4))
        #expect(PieceSelection(start: -3, end: 1) == PieceSelection(start: 0, end: 1))
    }

    @Test func tappingAnotherPieceExtendsASingleSelection() {
        #expect(PieceSelection(2).tapping(4) == PieceSelection(start: 2, end: 4))
    }

    @Test func tappingAnEarlierPieceExtendsBackwards() {
        #expect(PieceSelection(4).tapping(1) == PieceSelection(start: 1, end: 4))
    }

    @Test func tappingWhenSeveralAreSelectedStartsOverOnThatPiece() {
        #expect(PieceSelection(start: 2, end: 4).tapping(3) == PieceSelection(3))
        #expect(PieceSelection(start: 2, end: 4).tapping(7) == PieceSelection(7))
    }

    @Test func tappingTheSelectedPieceKeepsIt() {
        #expect(PieceSelection(3).tapping(3) == PieceSelection(3))
    }

    @Test func plusAddsTheNextPieceUntilTheEnd() {
        let selection = PieceSelection(start: 2, end: 3)
        #expect(selection.addingNext(pieceCount: 9) == PieceSelection(start: 2, end: 4))
        let last = PieceSelection(start: 2, end: 8)
        #expect(!last.canAddNext(pieceCount: 9))
        #expect(last.addingNext(pieceCount: 9) == last)
    }

    @Test func minusRemovesTheLastPieceButKeepsOne() {
        #expect(PieceSelection(start: 2, end: 4).removingLast() == PieceSelection(start: 2, end: 3))
        #expect(!PieceSelection(2).canRemoveLast)
        #expect(PieceSelection(2).removingLast() == PieceSelection(2))
    }

    @Test func wholeSelectsEveryPiece() {
        let whole = PieceSelection.whole(pieceCount: 9)
        #expect(whole == PieceSelection(start: 0, end: 8))
        #expect(whole.isWhole(pieceCount: 9))
        #expect(!PieceSelection(start: 1, end: 8).isWhole(pieceCount: 9))
    }

    @Test func clampedBringsASavedSelectionBackInBounds() {
        #expect(PieceSelection(start: 5, end: 12).clamped(pieceCount: 9) == PieceSelection(start: 5, end: 8))
        #expect(PieceSelection(start: 10, end: 12).clamped(pieceCount: 4) == PieceSelection(3))
    }

    @Test func countAndContains() {
        let selection = PieceSelection(start: 2, end: 4)
        #expect(selection.count == 3)
        #expect(selection.contains(3))
        #expect(!selection.contains(5))
    }
}
