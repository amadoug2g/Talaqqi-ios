/// La sélection est toujours une plage continue de morceaux, lue enchaînée puis répétée.
public struct PieceSelection: Codable, Sendable, Hashable {
    public private(set) var start: Int
    public private(set) var end: Int

    public init(start: Int, end: Int) {
        self.start = max(0, min(start, end))
        self.end = max(0, max(start, end))
    }

    public init(_ index: Int) {
        self.init(start: index, end: index)
    }

    public static func whole(pieceCount: Int) -> PieceSelection {
        PieceSelection(start: 0, end: pieceCount - 1)
    }

    public var count: Int { end - start + 1 }
    public var isSingle: Bool { start == end }
    public var indices: ClosedRange<Int> { start...end }

    public func contains(_ index: Int) -> Bool {
        indices.contains(index)
    }

    public func isWhole(pieceCount: Int) -> Bool {
        start == 0 && end == pieceCount - 1
    }

    /// Toucher un morceau : s'il n'y en avait qu'un de sélectionné, la sélection s'étend
    /// jusqu'au morceau touché ; sinon elle repart sur ce seul morceau.
    public func tapping(_ index: Int) -> PieceSelection {
        if isSingle && index != start {
            return PieceSelection(start: start, end: index)
        }
        return PieceSelection(index)
    }

    public func canAddNext(pieceCount: Int) -> Bool {
        end < pieceCount - 1
    }

    /// Bouton « + » : ajoute le morceau suivant en fin de sélection.
    public func addingNext(pieceCount: Int) -> PieceSelection {
        guard canAddNext(pieceCount: pieceCount) else { return self }
        return PieceSelection(start: start, end: end + 1)
    }

    public var canRemoveLast: Bool { end > start }

    /// Bouton « − » : retire le dernier morceau de la sélection.
    public func removingLast() -> PieceSelection {
        guard canRemoveLast else { return self }
        return PieceSelection(start: start, end: end - 1)
    }

    /// Ramène une sélection enregistrée dans les bornes du contenu.
    public func clamped(pieceCount: Int) -> PieceSelection {
        let last = max(0, pieceCount - 1)
        return PieceSelection(start: min(start, last), end: min(end, last))
    }
}
