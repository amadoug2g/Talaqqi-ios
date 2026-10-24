import SwiftUI
import ShadowingCore

struct HomeView: View {
    private let library = ContentLibrary.shared

    var body: some View {
        NavigationStack {
            List {
                ForEach(library.sections) { section in
                    Section(section.title) {
                        ForEach(section.items, id: \.self) { id in
                            if let content = library.content(id: id) {
                                NavigationLink(value: content) {
                                    ContentRow(content: content)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Sourates")
            .navigationDestination(for: Content.self) { content in
                PracticeView(content: content)
            }
        }
    }
}

struct ContentRow: View {
    let content: Content

    var body: some View {
        HStack(spacing: 12) {
            Text(content.kind == .surah ? "\(content.surah)" : "")
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)
            VStack(alignment: .leading, spacing: 1) {
                Text(content.title)
                Text(content.kind == .surah ? Format.verseCount(content.verseCount) : content.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(Theme.arabicForDisplay(content.arabicName))
                .font(Theme.arabic(22))
        }
        .padding(.vertical, 4)
    }
}
