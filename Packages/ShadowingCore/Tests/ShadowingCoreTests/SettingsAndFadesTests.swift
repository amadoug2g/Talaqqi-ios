import Testing
@testable import ShadowingCore

struct PlaybackSettingsTests {
    @Test func defaults() {
        let settings = PlaybackSettings()
        #expect(settings.repetitions == .times(3))
        #expect(settings.gapSeconds == 1)
        #expect(!settings.echo)
        #expect(settings.rate == 1)
    }

    @Test func gapStepsByHalfSecondsWithinBounds() {
        var settings = PlaybackSettings()
        settings.increaseGap()
        #expect(settings.gapSeconds == 1.5)
        settings.gapSeconds = 5
        #expect(!settings.canIncreaseGap)
        settings.increaseGap()
        #expect(settings.gapSeconds == 5)
        settings.gapSeconds = 0.5
        settings.decreaseGap()
        #expect(settings.gapSeconds == 0)
        #expect(!settings.canDecreaseGap)
        settings.decreaseGap()
        #expect(settings.gapSeconds == 0)
    }

    @Test func repetitionChoicesAndCount() {
        #expect(Repetitions.choices == [.times(1), .times(2), .times(3), .times(5), .infinite])
        #expect(Repetitions.times(5).count == 5)
        #expect(Repetitions.infinite.count == nil)
    }
}

struct FadesTests {
    @Test func fadesInAndOutWithoutTouchingTheMiddle() {
        // 1 000 trames par seconde : 10 trames de fondu d'entrée, 30 de fondu de sortie.
        var samples = [Float](repeating: 1, count: 100)
        samples.withUnsafeMutableBufferPointer { Fades.apply(to: $0, sampleRate: 1000) }
        #expect(samples[0] == 0)
        #expect(samples[5] == 0.5)
        #expect(samples[10] == 1)
        #expect(samples[50] == 1)
        #expect(samples[69] == 1)
        #expect(samples[70] == 29.0 / 30.0)
        #expect(samples[99] == 0)
    }

    @Test func shortClipsDoNotCrash() {
        var samples = [Float](repeating: 1, count: 3)
        samples.withUnsafeMutableBufferPointer { Fades.apply(to: $0, sampleRate: 1000) }
        #expect(samples[0] == 0)
        #expect(samples[2] == 0)

        var empty = [Float]()
        empty.withUnsafeMutableBufferPointer { Fades.apply(to: $0, sampleRate: 1000) }
        #expect(empty.isEmpty)
    }
}
