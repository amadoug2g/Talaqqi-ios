import SwiftUI
import ShadowingCore

/// L'écran de pratique (maquettes 2 et 3) : la feuille de récitation et le lecteur en bas.
struct PracticeView: View {
    @State private var session: PracticeSession
    @State private var showSettings = false
    @State private var showInfo = false

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
                            pieceCell(piece, snapshot: snapshot)
                                .id(piece.index)
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }
                .onChange(of: snapshot.playingPiece) { _, index in
                    guard let index else { return }
                    withAnimation(.easeInOut(duration: 0.35)) {
                        proxy.scrollTo(index, anchor: .center)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                displayBar
            }
            .safeAreaInset(edge: .bottom) {
                PlayerBar(session: session, snapshot: snapshot, showSettings: $showSettings)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 0) {
                    Text(session.content.title)
                        .font(.system(size: 17, weight: .semibold))
                    Text(Format.subtitle(of: session.content))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .disabled(session.content.info == nil)
                .accessibilityLabel("À propos de la sourate")
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(settings: $session.settings)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showInfo) {
            SurahInfoSheet(content: session.content)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: session.settings) {
            session.settingsChanged()
        }
        .onDisappear {
            session.stop()
        }
    }

    /// Phonétique, Arabe, Français, Mémoire.
    private var displayBar: some View {
        HStack(spacing: 4) {
            ToggleChip(title: "Phonétique", isOn: session.display.phonetic) { session.toggle(\.phonetic) }
            ToggleChip(title: "Arabe", isOn: session.display.arabic) { session.toggle(\.arabic) }
            ToggleChip(title: "Français", isOn: session.display.translation) { session.toggle(\.translation) }
            ToggleChip(title: "Mémoire", isOn: session.display.memory) { session.toggle(\.memory) }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private func pieceCell(_ piece: Piece, snapshot: PlaybackSnapshot) -> some View {
        let index = piece.index
        let selection = session.selection
        let inSelection = selection.contains(index)
        let isFirst = inSelection && index == selection.start
        let isLast = inSelection && index == selection.end
        return VStack(spacing: 0) {
            PieceRow(
                piece: piece,
                verseEnd: session.content.verseEnding(atPiece: index),
                display: session.display,
                inSelection: inSelection,
                isPlaying: snapshot.playingPiece == index,
                isTurn: snapshot.turnRemaining != nil,
                isMasked: session.isMasked(index),
                progress: snapshot.progress(ofPiece: index),
                reveal: { session.reveal(index) }
            )
            .contentShape(Rectangle())
            .onTapGesture { session.tap(index) }
            if index < session.content.pieceCount - 1 {
                Divider().padding(.leading, 48)
            }
        }
        .padding(.top, isFirst ? 18 : 0)
        .background(alignment: .topLeading) {
            if inSelection {
                RepeatMarker(label: Format.repetitionMarker(session.settings.repetitions), isFirst: isFirst, isLast: isLast)
            }
        }
    }
}

/// Le repère de reprise : un trait d'encre rouge dans la marge, de la première à la dernière ligne
/// sélectionnée, avec le nombre de répétitions au-dessus.
struct RepeatMarker: View {
    let label: String
    let isFirst: Bool
    let isLast: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 1.5)
                .padding(.top, isFirst ? 20 : 0)
                .padding(.bottom, isLast ? 13 : 0)
                .offset(x: 38)
            if isFirst {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .monospacedDigit()
                    .foregroundStyle(Color.accentColor)
                    .offset(x: 30)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .accessibilityHidden(true)
    }
}

struct PieceRow: View {
    let piece: Piece
    let verseEnd: Verse?
    let display: DisplayOptions
    let inSelection: Bool
    let isPlaying: Bool
    let isTurn: Bool
    let isMasked: Bool
    let progress: Double
    let reveal: () -> Void

    /// Trois niveaux d'encre : hors sélection, dans la sélection, en lecture (et pendant « À toi »).
    private var ink: Double {
        if !inSelection { return 0.35 }
        return isPlaying || isTurn ? 1 : 0.6
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 18) {
            Text("\(piece.index)")
                .font(.system(size: 13, weight: isPlaying ? .semibold : .regular))
                .monospacedDigit()
                .foregroundStyle(isPlaying ? Color.accentColor : Color.secondary)
                .frame(width: 30, alignment: .trailing)
            VStack(alignment: .leading, spacing: 4) {
                if inSelection {
                    selectedTexts
                        .blur(radius: isMasked ? 7 : 0)
                        .overlay {
                            if isMasked {
                                Button("Voir", action: reveal)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(Color.primary)
                                    .padding(.horizontal, 11)
                                    .frame(height: 32)
                                    .background(Theme.neutralFill, in: Capsule())
                                    .buttonStyle(.plain)
                            }
                        }
                    if isPlaying {
                        progressBar.padding(.top, 8)
                    }
                } else {
                    unselectedText
                }
            }
            .opacity(ink)
        }
        .padding(.top, 10)
        .padding(.bottom, inSelection ? 12 : 10)
        .padding(.trailing, 16)
    }

    /// Dans la sélection : les textes choisis dans la barre d'affichage.
    @ViewBuilder
    private var selectedTexts: some View {
        VStack(alignment: .leading, spacing: 4) {
            if display.phonetic, let phonetic = piece.phonetic {
                phoneticText(phonetic)
            }
            if display.arabic, let arabic = piece.arabic {
                arabicText(arabic)
            } else if verseEnd != nil {
                verseEndLine
            }
            if display.translation, let translation = piece.translation {
                Text(translation)
                    .font(Theme.serif(15))
                    .lineSpacing(2)
                    .foregroundStyle(.secondary)
            }
            if !display.phonetic && !display.arabic && !display.translation {
                Text("Texte masqué, écoute seulement.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Hors sélection : une seule ligne, la phonétique de préférence, jamais vide.
    /// Sans l'arabe, le marqueur de fin de verset garde sa propre ligne (maquette 2, morceau 8).
    @ViewBuilder
    private var unselectedText: some View {
        if !display.phonetic && display.arabic, let arabic = piece.arabic {
            arabicText(arabic)
        } else {
            if !display.phonetic && display.translation, let translation = piece.translation {
                Text(translation)
                    .font(Theme.serif(15))
                    .foregroundStyle(.secondary)
            } else if let phonetic = piece.phonetic {
                phoneticText(phonetic)
            }
            if verseEnd != nil {
                verseEndLine
            }
        }
    }

    private func phoneticText(_ text: String) -> some View {
        Text(text)
            .font(Theme.serif(17))
            .lineSpacing(4)
    }

    /// Le texte arabe, suivi du marqueur de fin de verset en plus petit et en gris.
    private func arabicText(_ arabic: String) -> some View {
        var line = AttributedString(Theme.arabicForDisplay(arabic))
        if let verseEnd {
            var marker = AttributedString(" " + Format.verseEndMarker(verseEnd.number))
            marker.font = Theme.arabic(Self.inlineMarkerSize)
            marker.foregroundColor = .secondary
            line.append(marker)
        }
        return Text(line)
            .font(Theme.arabic(26))
            .lineSpacing(6)
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
    }

    /// Sans le texte arabe, le numéro du verset reste discret sur sa propre ligne.
    @ViewBuilder
    private var verseEndLine: some View {
        if let verseEnd {
            Text(Format.verseEndMarker(verseEnd.number))
                .font(Theme.arabic(Self.aloneMarkerSize))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    private static let inlineMarkerSize: CGFloat = 18
    private static let aloneMarkerSize: CGFloat = 15

    /// Barre de 2 pt sous le morceau en lecture.
    private var progressBar: some View {
        Capsule()
            .fill(Color.accentColor.opacity(0.16))
            .frame(height: 2)
            .overlay(alignment: .leading) {
                GeometryReader { geometry in
                    Capsule()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * min(1, max(0, progress)))
                }
            }
    }
}
