import Foundation
import Testing
@testable import ShadowingCore

/// Le library.json réellement embarqué dans l'application, produit par tools/build_content.py.
struct LibraryTests {
    static let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // ShadowingCoreTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent() // ShadowingCore
        .deletingLastPathComponent() // Packages
        .deletingLastPathComponent() // racine du dépôt
        .appending(path: "Talaqqi/Talaqqi/Resources/Content/library.json")

    static func load() throws -> Library {
        try JSONDecoder().decode(Library.self, from: Data(contentsOf: url))
    }

    @Test func embeddedLibraryDecodes() throws {
        let library = try Self.load()
        #expect(!library.contents.isEmpty)
        for section in library.sections {
            for id in section.items {
                #expect(library.content(id: id) != nil, "contenu \(id) introuvable")
            }
        }
    }

    @Test func everyContentHasAPlaybackPlan() throws {
        for content in try Self.load().contents {
            #expect(content.pieces.map(\.index) == Array(0..<content.pieceCount), "\(content.id)")
            let plan = PlaybackPlan(content: content, selection: .whole(pieceCount: content.pieceCount), settings: PlaybackSettings())
            let pieceItems = plan?.pass.filter { item in
                if case .piece = item.kind { return true }
                return false
            }
            #expect(pieceItems?.count == content.pieceCount, "\(content.id)")
        }
    }

    @Test func contentsWithTheirOwnRecitationUseASingleFile() throws {
        for content in try Self.load().contents where content.reciter != nil {
            #expect(Set(content.pieces.map(\.audio.file)).count == 1, "\(content.id)")
        }
    }

    @Test func versesCoverTheirPieces() throws {
        for content in try Self.load().contents {
            for verse in content.verses {
                for index in verse.firstPiece...verse.lastPiece {
                    #expect(content.pieces[index].verse == verse.number, "\(content.id) morceau \(index)")
                }
                #expect(content.verseEnding(atPiece: verse.lastPiece)?.number == verse.number)
            }
        }
    }
}
