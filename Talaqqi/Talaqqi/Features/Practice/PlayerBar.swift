import SwiftUI
import ShadowingCore

/// Le lecteur flottant (maquettes 2 et 3) : sélection et temps, frise, état, commandes.
struct PlayerBar: View {
    let session: PracticeSession
    let snapshot: PlaybackSnapshot
    @Binding var showSettings: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let plan = snapshot.plan ?? session.previewPlan
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Menu {
                    Button(session.wholeLabel) { session.selectWhole() }
                } label: {
                    HStack(spacing: 4) {
                        Text(Format.selection(session.selection))
                            .font(.system(size: 15, weight: .semibold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)
                Spacer()
                if let plan {
                    Text(clock(plan))
                        .font(.system(size: 15))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }

            if let plan {
                Timeline(plan: plan, snapshot: snapshot)
                    .padding(.top, 2)
                    .opacity(snapshot.turnRemaining != nil ? 0.35 : 1)
            }

            status

            HStack(spacing: 4) {
                iconButton("slider.horizontal.3", label: "Réglages") { showSettings = true }
                iconButton("minus", label: "Retirer un morceau") { session.removeLast() }
                    .disabled(!session.canRemoveLast)
                Spacer()
                Button(action: session.togglePlayback) {
                    Image(systemName: session.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 26))
                        .foregroundStyle(colorScheme == .dark ? Color.black : Color.white)
                        .frame(width: 64, height: 64)
                        .background(Color.accentColor, in: Circle())
                }
                .accessibilityLabel(session.isPlaying ? "Pause" : "Lire")
                Spacer()
                iconButton("plus", label: "Ajouter un morceau") { session.addNext() }
                    .disabled(!session.canAddNext)
                iconButton("stop.fill", label: "Arrêter") { session.stop() }
                    .disabled(!session.isActive)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .glassEffect(in: .rect(cornerRadius: 32))
        .padding(.horizontal, 8)
    }

    /// « 0:09 / 0:16 » en lecture, la durée du passage à l'arrêt.
    private func clock(_ plan: PlaybackPlan) -> String {
        guard let position = snapshot.position else { return Format.clock(plan.passSeconds) }
        return Format.clock(position.passElapsedSeconds, of: plan.passSeconds)
    }

    @ViewBuilder
    private var status: some View {
        if let message = session.player.errorMessage {
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(.red)
        } else if let remaining = snapshot.turnRemaining {
            VStack(alignment: .leading, spacing: 6) {
                Text(Format.turn(remainingSeconds: remaining))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.gold)
                CountdownBar(remaining: 1 - min(1, max(0, snapshot.turnProgress)))
            }
        } else if let plan = snapshot.plan, let position = snapshot.position {
            Text(Format.repetition(position.repetition, of: plan.repetitions))
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        } else {
            Text(idleText)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
    }

    private var idleText: String {
        let settings = session.settings
        let repetitions = settings.repetitions.count.map { $0 == 1 ? "Lu 1 fois" : "Lu \($0) fois" } ?? "En boucle"
        guard settings.repetitions.count != 1 else { return repetitions }
        let gap = settings.echo ? "écho" : Format.gap(settings.gapSeconds) + " pour répéter"
        return "\(repetitions) · \(gap)"
    }

    private func iconButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
        }
        .tint(.primary)
        .accessibilityLabel(label)
    }
}

/// La frise : un segment par morceau de la sélection, de largeur proportionnelle à sa durée.
struct Timeline: View {
    let plan: PlaybackPlan
    let snapshot: PlaybackSnapshot

    private let spacing: CGFloat = 3

    var body: some View {
        let indices = Array(plan.selection.indices)
        let durations = indices.map { plan.duration(ofPiece: $0) }
        let total = max(0.001, durations.reduce(0, +))
        GeometryReader { geometry in
            let available = max(0, geometry.size.width - spacing * CGFloat(max(0, indices.count - 1)))
            HStack(alignment: .top, spacing: spacing) {
                ForEach(Array(indices.enumerated()), id: \.element) { offset, index in
                    let width = available * durations[offset] / total
                    let isCurrent = snapshot.playingPiece == index
                    VStack(alignment: .leading, spacing: 5) {
                        Capsule()
                            .fill(Theme.track)
                            .frame(width: width, height: 4)
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(Color.accentColor)
                                    .frame(width: width * min(1, max(0, snapshot.progress(ofPiece: index))), height: 4)
                            }
                        Text("\(index)")
                            .font(.system(size: 13, weight: isCurrent ? .semibold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(isCurrent ? Color.accentColor : Color.secondary)
                            .lineLimit(1)
                            .fixedSize()
                    }
                    .frame(width: width, alignment: .leading)
                }
            }
        }
        .frame(height: 25)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Frise des morceaux \(plan.selection.start) à \(plan.selection.end)")
    }
}

/// « À toi » : une fine barre dorée qui se vide pendant le silence.
struct CountdownBar: View {
    let remaining: Double

    var body: some View {
        Capsule()
            .fill(Theme.gold.opacity(0.2))
            .frame(height: 2)
            .overlay(alignment: .leading) {
                GeometryReader { geometry in
                    Capsule()
                        .fill(Theme.gold)
                        .frame(width: geometry.size.width * remaining)
                }
            }
    }
}

/// Réglages (maquette 4), feuille native à mi-hauteur.
struct SettingsSheet: View {
    @Binding var settings: PlaybackSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Répétitions") {
                    Picker("Répétitions", selection: $settings.repetitions) {
                        ForEach(Repetitions.choices, id: \.self) { choice in
                            Text(choice.count.map { "\($0)" } ?? "∞").tag(choice)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                Section {
                    Stepper(value: $settings.gapSeconds, in: PlaybackSettings.gapRange, step: PlaybackSettings.gapStep) {
                        HStack {
                            Text("Temps pour répéter")
                            Spacer()
                            Text(Format.gap(settings.gapSeconds))
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .disabled(settings.echo)
                    Toggle("Écho", isOn: $settings.echo)
                } footer: {
                    Text("Un silence aussi long que le passage.")
                }
                Section("Vitesse") {
                    Picker("Vitesse", selection: $settings.rate) {
                        ForEach(PlaybackSettings.rates, id: \.self) { rate in
                            Text(Format.rate(rate)).tag(rate)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
    }
}
