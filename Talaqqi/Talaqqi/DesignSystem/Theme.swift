import SwiftUI
import UIKit

/// Valeurs relevées dans les maquettes (docs/design/html).
enum Theme {
    static let gold = Color("Gold")
    /// Fond des bascules et des boutons neutres : rgba(120,120,128,.12) en clair, .24 en sombre.
    static let neutralFill = Color(uiColor: .tertiarySystemFill)
    /// Piste de la frise : rgba(120,120,128,.2) en clair, .36 en sombre.
    static let track = Color(uiColor: .systemFill)

    /// New York, la serif d'Apple, pour la phonétique et la traduction.
    static func serif(_ size: CGFloat) -> Font {
        .system(size: size, design: .serif)
    }

    /// Police coranique embarquée. KFGQPC Uthmanic Script HAFS n'était pas accessible :
    /// Amiri Quran, le secours prévu par le brief, la remplace pour l'instant.
    static func arabic(_ size: CGFloat) -> Font {
        .custom("AmiriQuran-Regular", size: size)
    }

    /// Le texte du Complexe du Roi Fahd note les tanwīn « ouverts » avec des points de code propres
    /// à sa police (U+065E, U+0656). Amiri Quran les attend à leur place Unicode (U+08F1, U+08F2).
    /// Simple correspondance d'affichage : le texte enregistré reste celui de la source.
    static func arabicForDisplay(_ text: String) -> String {
        text.replacingOccurrences(of: "\u{065E}", with: "\u{08F1}")
            .replacingOccurrences(of: "\u{0656}", with: "\u{08F2}")
    }
}

/// Bascule compacte de la barre d'affichage (Phonétique, Arabe, Français, Mémoire).
struct ToggleChip: View {
    let title: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: isOn ? .medium : .regular))
                .foregroundStyle(isOn ? Color.primary : Color.secondary)
                .padding(.horizontal, 11)
                .frame(height: 32)
                .background(isOn ? Theme.neutralFill : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? .isSelected : [])
    }
}
