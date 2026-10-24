import Foundation

/// Contenu embarqué dans l'application, produit par `tools/build_content.py`.
/// Aucun texte n'est écrit à la main : tout vient des sources listées dans `sources`.
public struct Library: Codable, Sendable, Hashable {
    public var reciter: Reciter
    public var sources: Sources
    public var sections: [LibrarySection]
    public var contents: [Content]

    public func content(id: Content.ID) -> Content? {
        contents.first { $0.id == id }
    }
}

public struct Reciter: Codable, Sendable, Hashable {
    public var id: String
    public var name: String
}

/// Mentions de source, affichées telles quelles.
public struct Sources: Codable, Sendable, Hashable {
    public var audio: String
    public var arabic: String
    public var phonetic: String
    public var translation: String
    public var surahInfo: String
}

/// Une section de l'accueil (« Versets », « Juz ‘Amma »).
public struct LibrarySection: Codable, Sendable, Hashable, Identifiable {
    public var id: String { title }
    public var title: String
    public var items: [Content.ID]
}

/// Ce que l'on pratique : une sourate entière, ou un verset seul comme Ayat al-Kursî.
public struct Content: Codable, Sendable, Hashable, Identifiable {
    public enum Kind: String, Codable, Sendable {
        case surah
        case verse
    }

    /// « 112 » pour une sourate, « 2:255 » pour un verset seul.
    public var id: String
    public var kind: Kind
    public var title: String
    public var subtitle: String
    public var arabicName: String
    public var surah: Int
    public var verseCount: Int
    public var info: SurahInfo?
    public var verses: [Verse]
    /// Liste plate des morceaux ; `pieces[i].index == i`, le morceau 0 est la Basmala.
    public var pieces: [Piece]

    public var pieceCount: Int { pieces.count }

    /// Le verset qui se termine sur ce morceau, pour placer le marqueur de fin de verset.
    public func verseEnding(atPiece index: Int) -> Verse? {
        verses.first { $0.lastPiece == index }
    }
}

public struct Verse: Codable, Sendable, Hashable {
    public var number: Int
    /// Traduction complète du verset, recopiée de la source.
    public var translation: String?
    public var firstPiece: Int
    public var lastPiece: Int
}

/// L'unité de pratique. Un verset court est un seul morceau, un verset long en a plusieurs.
public struct Piece: Codable, Sendable, Hashable, Identifiable {
    public var id: Int { index }
    public var index: Int
    /// `nil` pour la Basmala.
    public var verse: Int?
    public var arabic: String?
    public var phonetic: String?
    public var translation: String?
    public var audio: AudioClip
}

/// Un extrait d'un fichier audio embarqué, en trames (échantillons par canal).
public struct AudioClip: Codable, Sendable, Hashable {
    public var file: String
    public var startFrame: Int
    /// Exclu.
    public var endFrame: Int
    public var sampleRate: Double

    public var frameCount: Int { max(0, endFrame - startFrame) }
    public var duration: Double { Double(frameCount) / sampleRate }
}

/// Fiche « À propos de la sourate ».
public struct SurahInfo: Codable, Sendable, Hashable {
    /// Paragraphe « Parmi les objectifs de la sourate », recopié tel quel.
    public var objectives: String
    public var source: String
}
