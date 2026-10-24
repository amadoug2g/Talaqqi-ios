import SwiftUI
import ShadowingCore

struct PracticeView: View {
    @State private var session: PracticeSession
    @State private var showSettings = false

    init(content: Content) {
        _session = State(initialValue: PracticeSession(content: content))
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: !session.isPlaying)) { _ in
            let snapshot = session.snapshot()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(session.content.pieces) { piece in
                            PieceRow(
                                piece: piece,
                                verseEnd: session.content.verseEnding(atPiece: piece.index),
                                inSelection: session.selection.contains(piece.index),
                                isPlaying: snapshot.playingPiece == piece.index,
                                isTurn: snapshot.turnRemaining != nil,
                                progress: snapshot.progress(ofPiece: piece.index)
                            )
                            .id(piece.index)
                            .contentShape(Rectangle())
                            .onTapGesture { session.tap(piece.index) }
                            Divider().padding(.leading, 48)
                        }
                    }
                    .padding(.bottom, 16)
                }
                .onChange(of: snapshot.playingPiece) { _, index in
                    guard let index else { return }
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                PlayerBar(session: session, snapshot: snapshot, showSettings: $showSettings)
            }
        }
        .navigationTitle(session.content.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showSettings) {
            SettingsSheet(settings: $session.settings)
                .presentationDetents([.medium])
        }
        .onChange(of: session.settings) {
            session.settingsChanged()
        }
        .onDisappear {
            session.stop()
        }
    }
}

struct PieceRow: View {
    let piece: Piece
    let verseEnd: Verse?
    let inSelection: Bool
    let isPlaying: Bool
    let isTurn: Bool
    let progress: Double

    /// Trois niveaux d'encre : hors sélection, dans la sélection, en lecture.
    private var ink: Double {
        if !inSelection { return 0.35 }
        return isPlaying || isTurn ? 1 : 0.6
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Text("\(piece.index)")
                .font(.footnote.monospacedDigit())
                .fontWeight(isPlaying ? .semibold : .regular)
                .foregroundStyle(isPlaying ? Color.accentColor : Color.secondary)
                .frame(width: 30, alignment: .trailing)
            VStack(alignment: .leading, spacing: 4) {
                if let phonetic = piece.phonetic {
                    Text(phonetic)
                        .font(.system(size: 17, design: .serif))
                }
                if inSelection {
                    if let arabic = piece.arabic {
                        Text(arabicLine(arabic))
                            .font(.system(size: 26))
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    if let translation = piece.translation {
                        Text(translation)
                            .font(.system(size: 15, design: .serif))
                            .foregroundStyle(.secondary)
                    }
                    if isPlaying {
                        ProgressView(value: min(1, max(0, progress)))
                            .tint(.accentColor)
                            .padding(.top, 8)
                    }
                } else if let verseEnd {
                    Text(Format.verseEndMarker(verseEnd.number))
                        .font(.system(size: 26))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .opacity(ink)
        }
        .padding(.top, 10)
        .padding(.bottom, inSelection ? 12 : 10)
        .padding(.trailing, 16)
    }

    /// Le marqueur de fin de verset se place à la fin du texte arabe quand celui-ci est affiché.
    private func arabicLine(_ arabic: String) -> String {
        guard let verseEnd else { return arabic }
        return "\(arabic) \(Format.verseEndMarker(verseEnd.number))"
    }
}
