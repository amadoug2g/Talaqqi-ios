import Foundation

/// Libellés de l'interface, au format des maquettes (virgule décimale, « → », « · »).
public enum Format {
    /// « 0,6 », « 1 », « 2,5 » : une décimale au plus, virgule française.
    public static func decimal(_ value: Double) -> String {
        let tenths = Int((max(0, value) * 10).rounded())
        if tenths % 10 == 0 { return "\(tenths / 10)" }
        return "\(tenths / 10),\(tenths % 10)"
    }

    /// « 0:09 », « 1:05 ».
    public static func clock(_ seconds: Double) -> String {
        let total = Int(max(0, seconds).rounded(.down))
        let remainder = total % 60
        return "\(total / 60):\(remainder < 10 ? "0" : "")\(remainder)"
    }

    /// « 0:09 / 0:16 ».
    public static func clock(_ elapsed: Double, of total: Double) -> String {
        "\(clock(elapsed)) / \(clock(total))"
    }

    /// « Morceau 3 », « Morceaux 2 → 4 ».
    public static func selection(_ selection: PieceSelection) -> String {
        if selection.isSingle { return "Morceau \(selection.start)" }
        return "Morceaux \(selection.start) → \(selection.end)"
    }

    /// Libellé du bandeau « Récemment » : « Sourate entière » quand tout est sélectionné.
    public static func selectionSummary(_ selection: PieceSelection, in content: Content) -> String {
        guard selection.isWhole(pieceCount: content.pieceCount), !selection.isSingle else {
            return Format.selection(selection)
        }
        switch content.kind {
        case .surah: return "Sourate entière"
        case .verse: return "Verset entier"
        }
    }

    /// « Répétition 2 sur 3 », ou « Répétition 2 » en boucle infinie. `index` part de 0.
    public static func repetition(_ index: Int, of repetitions: Repetitions) -> String {
        guard let count = repetitions.count else { return "Répétition \(index + 1)" }
        return "Répétition \(index + 1) sur \(count)"
    }

    /// « À toi · 0,6 s ».
    public static func turn(remainingSeconds: Double) -> String {
        "À toi · \(decimal(remainingSeconds)) s"
    }

    /// Repère de reprise : « ×3 » ou « ∞ ».
    public static func repetitionMarker(_ repetitions: Repetitions) -> String {
        guard let count = repetitions.count else { return "∞" }
        return "×\(count)"
    }

    /// « 1 s », « 0,5 s ».
    public static func gap(_ seconds: Double) -> String {
        "\(decimal(seconds)) s"
    }

    /// « 0,75× », « 1× ».
    public static func rate(_ rate: Double) -> String {
        let hundredths = Int((max(0, rate) * 100).rounded())
        var text = "\(hundredths / 100)"
        let fraction = hundredths % 100
        if fraction != 0 {
            text += fraction % 10 == 0 ? ",\(fraction / 10)" : ",\(fraction < 10 ? "0" : "")\(fraction)"
        }
        return text + "×"
    }

    /// « 1 verset », « 11 versets ».
    public static func verseCount(_ count: Int) -> String {
        count > 1 ? "\(count) versets" : "\(count) verset"
    }

    /// Marqueur de fin de verset du mushaf : « ﴿٢٥٥﴾ ».
    public static func verseEndMarker(_ number: Int) -> String {
        "\u{FD3F}\(arabicIndicDigits(number))\u{FD3E}"
    }

    /// « ٢٥٥ » pour 255.
    public static func arabicIndicDigits(_ number: Int) -> String {
        String(String(number).unicodeScalars.map { scalar -> Character in
            guard let digit = Int(String(scalar)) else { return Character(scalar) }
            return Character(Unicode.Scalar(0x0660 + UInt32(digit))!)
        })
    }

    /// Ancienneté d'une écoute : « à l’instant », « il y a 12 min », « il y a 6 h », « hier », « il y a 3 j ».
    public static func relative(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        let seconds = now.timeIntervalSince(date)
        if seconds < 60 { return "à l’instant" }
        if seconds < 3600 { return "il y a \(Int(seconds / 60)) min" }
        if seconds < 86_400 { return "il y a \(Int(seconds / 3600)) h" }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        if days <= 1 { return "hier" }
        return "il y a \(days) j"
    }
}
