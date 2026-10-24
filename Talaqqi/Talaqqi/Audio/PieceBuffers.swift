import AVFoundation
import ShadowingCore

enum PlayerError: LocalizedError {
    case missingAudio(String)
    case unexpectedFormat(String)

    var errorDescription: String? {
        switch self {
        case .missingAudio(let file): "Fichier audio introuvable : \(file)"
        case .unexpectedFormat(let file): "Format audio inattendu : \(file)"
        }
    }
}

/// Les morceaux d'un contenu chargés en mémoire avec leurs fondus, et les silences du plan.
final class PieceBuffers {
    let format: AVAudioFormat
    private let content: Content
    private var pieces: [Int: AVAudioPCMBuffer] = [:]
    private var silences: [Int: AVAudioPCMBuffer] = [:]

    init(content: Content) throws {
        guard let first = content.pieces.first else { throw PlayerError.missingAudio(content.id) }
        guard let url = ContentLibrary.audioURL(first.audio.file) else { throw PlayerError.missingAudio(first.audio.file) }
        let file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
        self.format = file.processingFormat
        self.content = content
    }

    func piece(_ index: Int) throws -> AVAudioPCMBuffer {
        if let cached = pieces[index] { return cached }
        let clip = content.pieces[index].audio
        guard let url = ContentLibrary.audioURL(clip.file) else { throw PlayerError.missingAudio(clip.file) }
        let file = try AVAudioFile(forReading: url, commonFormat: .pcmFormatFloat32, interleaved: false)
        let count = AVAudioFrameCount(clip.frameCount)
        guard file.processingFormat == format,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: count)
        else { throw PlayerError.unexpectedFormat(clip.file) }
        file.framePosition = AVAudioFramePosition(clip.startFrame)
        try file.read(into: buffer, frameCount: count)
        if let channel = buffer.floatChannelData?[0] {
            Fades.apply(to: UnsafeMutableBufferPointer(start: channel, count: Int(buffer.frameLength)),
                        sampleRate: format.sampleRate)
        }
        pieces[index] = buffer
        return buffer
    }

    /// Un vrai silence audio, pour que la lecture continue écran éteint (jamais de minuteur).
    func silence(frames: Int) -> AVAudioPCMBuffer? {
        if let cached = silences[frames] { return cached }
        guard frames > 0, let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(frames)) else {
            return nil
        }
        buffer.frameLength = AVAudioFrameCount(frames)
        if let channel = buffer.floatChannelData?[0] {
            channel.update(repeating: 0, count: frames)
        }
        silences[frames] = buffer
        return buffer
    }
}
