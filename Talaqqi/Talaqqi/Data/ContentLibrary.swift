import Foundation
import ShadowingCore

/// Le contenu embarqué, produit par tools/build_content.py.
enum ContentLibrary {
    static let shared: Library = load()

    private static func load() -> Library {
        guard let url = resource("library.json", folder: "Content"),
              let data = try? Data(contentsOf: url),
              let library = try? JSONDecoder().decode(Library.self, from: data)
        else {
            fatalError("library.json est absent ou illisible : relancer tools/build_content.py")
        }
        return library
    }

    static func audioURL(_ file: String) -> URL? {
        resource(file, folder: "Audio")
    }

    /// Xcode range les ressources à la racine de l'application ; on accepte aussi leur dossier d'origine.
    private static func resource(_ file: String, folder: String) -> URL? {
        let name = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension
        return Bundle.main.url(forResource: name, withExtension: ext)
            ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: folder)
            ?? Bundle.main.url(forResource: name, withExtension: ext, subdirectory: "Resources/\(folder)")
    }
}
