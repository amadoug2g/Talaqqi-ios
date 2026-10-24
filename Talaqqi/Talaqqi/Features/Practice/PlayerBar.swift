import SwiftUI
import ShadowingCore

/// Le lecteur en bas de l'écran de pratique.
struct PlayerBar: View {
    let session: PracticeSession
    let snapshot: PlaybackSnapshot
    @Binding var showSettings: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Menu {
                    Button(session.wholeLabel) { session.selectWhole() }
                } label: {
                    HStack(spacing: 4) {
                        Text(Format.selection(session.selection))
                            .font(.subheadline.weight(.semibold))
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .tint(.primary)
                Spacer()
                if let plan = snapshot.plan, let position = snapshot.position {
                    Text(Format.clock(position.passElapsedSeconds, of: plan.passSeconds))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
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

    @ViewBuilder
    private var status: some View {
        if let message = session.player.errorMessage {
            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
        } else if let remaining = snapshot.turnRemaining {
            VStack(alignment: .leading, spacing: 6) {
                Text(Format.turn(remainingSeconds: remaining))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color("Gold"))
                ProgressView(value: 1 - min(1, max(0, snapshot.turnProgress)))
                    .tint(Color("Gold"))
            }
        } else if let plan = snapshot.plan, let position = snapshot.position {
            Text(Format.repetition(position.repetition, of: plan.repetitions))
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            Text(idleText)
                .font(.footnote)
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
