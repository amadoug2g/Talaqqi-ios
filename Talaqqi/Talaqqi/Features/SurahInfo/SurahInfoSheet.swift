import SwiftUI
import ShadowingCore

/// « À propos de la sourate » (maquette 5). Le paragraphe est recopié de la source, avec elle.
struct SurahInfoSheet: View {
    let content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .lastTextBaseline, spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(content.title)
                                .font(.system(size: 28, weight: .bold))
                            Text(Format.listSubtitle(of: content))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(Theme.arabicForDisplay(content.arabicName))
                            .font(Theme.arabic(28))
                    }
                    Divider()
                        .padding(.vertical, 20)
                    if let info = content.info {
                        Text("Parmi les objectifs de la sourate")
                            .font(.headline)
                            .padding(.bottom, 8)
                        Text(info.objectives)
                            .font(Theme.serif(17))
                            .lineSpacing(6)
                        Text("Source : \(info.source)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 20)
                    }
                    if content.translatedName != nil, let names = ContentLibrary.shared.sources.surahNames {
                        Text("Nom en français : \(names)")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 28)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}
