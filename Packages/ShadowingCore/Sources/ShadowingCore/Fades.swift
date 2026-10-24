/// Fondus appliqués sur les échantillons de chaque morceau, pour des coupes nettes sans clic.
public enum Fades {
    public static let fadeInSeconds = 0.010
    public static let fadeOutSeconds = 0.030

    /// Fondu linéaire d'entrée et de sortie, sur les échantillons d'un canal.
    /// Le premier et le dernier échantillon valent 0.
    public static func apply(to samples: UnsafeMutableBufferPointer<Float>, sampleRate: Double) {
        let count = samples.count
        guard count > 0, sampleRate > 0 else { return }
        let fadeIn = min(count, Int((fadeInSeconds * sampleRate).rounded()))
        let fadeOut = min(count, Int((fadeOutSeconds * sampleRate).rounded()))
        for i in 0..<fadeIn {
            samples[i] *= Float(i) / Float(fadeIn)
        }
        for i in 0..<fadeOut {
            samples[count - 1 - i] *= Float(i) / Float(fadeOut)
        }
    }
}
