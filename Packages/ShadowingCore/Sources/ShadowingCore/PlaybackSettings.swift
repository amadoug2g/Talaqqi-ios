public enum Repetitions: Codable, Sendable, Hashable {
    case times(Int)
    case infinite

    /// Choix proposés dans les réglages : 1, 2, 3, 5, ∞.
    public static let choices: [Repetitions] = [.times(1), .times(2), .times(3), .times(5), .infinite]

    /// `nil` pour une boucle infinie.
    public var count: Int? {
        if case .times(let n) = self { return max(1, n) }
        return nil
    }
}

/// Réglages de lecture, mémorisés pour chaque contenu.
public struct PlaybackSettings: Codable, Sendable, Hashable {
    public static let rates: [Double] = [0.75, 0.9, 1]
    public static let gapRange: ClosedRange<Double> = 0...5
    public static let gapStep = 0.5

    public var repetitions: Repetitions = .times(3)
    /// Silence laissé pour répéter, en secondes réelles.
    public var gapSeconds: Double = 1
    /// Écho : un silence aussi long que le passage, à la place de `gapSeconds`.
    public var echo = false
    /// Vitesse de lecture, sans changer la hauteur de la voix.
    public var rate: Double = 1

    public init() {}

    public var canIncreaseGap: Bool { gapSeconds < Self.gapRange.upperBound }
    public var canDecreaseGap: Bool { gapSeconds > Self.gapRange.lowerBound }

    public mutating func increaseGap() {
        gapSeconds = Self.snappedGap(gapSeconds + Self.gapStep)
    }

    public mutating func decreaseGap() {
        gapSeconds = Self.snappedGap(gapSeconds - Self.gapStep)
    }

    static func snappedGap(_ seconds: Double) -> Double {
        let snapped = (seconds / gapStep).rounded() * gapStep
        return min(gapRange.upperBound, max(gapRange.lowerBound, snapped))
    }
}
