import Foundation
import Testing
@testable import ShadowingCore

struct FormatTests {
    @Test func decimalUsesAFrenchComma() {
        #expect(Format.decimal(0.6) == "0,6")
        #expect(Format.decimal(1) == "1")
        #expect(Format.decimal(2.5) == "2,5")
        #expect(Format.decimal(0.04) == "0")
        #expect(Format.decimal(-1) == "0")
    }

    @Test func clock() {
        #expect(Format.clock(9.8) == "0:09")
        #expect(Format.clock(65) == "1:05")
        #expect(Format.clock(9, of: 16) == "0:09 / 0:16")
    }

    @Test func selectionLabels() {
        #expect(Format.selection(PieceSelection(3)) == "Morceau 3")
        #expect(Format.selection(PieceSelection(start: 2, end: 4)) == "Morceaux 2 → 4")
    }

    @Test func selectionSummaryForTheRecentStrip() {
        var surah = Fixtures.content
        surah.kind = .surah
        #expect(Format.selectionSummary(.whole(pieceCount: 4), in: surah) == "Sourate entière")
        #expect(Format.selectionSummary(.whole(pieceCount: 4), in: Fixtures.content) == "Verset entier")
        #expect(Format.selectionSummary(PieceSelection(start: 2, end: 3), in: surah) == "Morceaux 2 → 3")
    }

    @Test func playerLabels() {
        #expect(Format.repetition(1, of: .times(3)) == "Répétition 2 sur 3")
        #expect(Format.repetition(6, of: .infinite) == "Répétition 7")
        #expect(Format.turn(remainingSeconds: 0.6) == "À toi · 0,6 s")
        #expect(Format.repetitionMarker(.times(3)) == "×3")
        #expect(Format.repetitionMarker(.infinite) == "∞")
    }

    @Test func settingsLabels() {
        #expect(Format.gap(1) == "1 s")
        #expect(Format.gap(0.5) == "0,5 s")
        #expect(Format.rate(0.75) == "0,75×")
        #expect(Format.rate(0.9) == "0,9×")
        #expect(Format.rate(1) == "1×")
        #expect(Format.verseCount(1) == "1 verset")
        #expect(Format.verseCount(11) == "11 versets")
    }

    @Test func verseEndMarkerMatchesTheMockup() {
        #expect(Format.verseEndMarker(255) == "\u{FD3F}٢٥٥\u{FD3E}")
        #expect(Format.arabicIndicDigits(1) == "١")
    }

    @Test func relativeDates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 18))!
        #expect(Format.relative(now.addingTimeInterval(-30), now: now, calendar: calendar) == "à l’instant")
        #expect(Format.relative(now.addingTimeInterval(-12 * 60), now: now, calendar: calendar) == "il y a 12 min")
        #expect(Format.relative(now.addingTimeInterval(-6 * 3600), now: now, calendar: calendar) == "il y a 6 h")
        #expect(Format.relative(now.addingTimeInterval(-26 * 3600), now: now, calendar: calendar) == "hier")
        #expect(Format.relative(now.addingTimeInterval(-3 * 86_400), now: now, calendar: calendar) == "il y a 3 j")
    }
}
