import AVFoundation
import Foundation

@MainActor
final class Speech: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = Speech()

    private let synth = AVSpeechSynthesizer()
    private var usingFallbackProcess = false

    var onSpeakingChanged: ((Bool) -> Void)?
    var onSpeakRange: ((Int, Int) -> Void)?

    private override init() {
        super.init()
        synth.delegate = self
    }

    func toggle(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if synth.isSpeaking || usingFallbackProcess {
            stop()
            return
        }

        startSpeaking(trimmed)
    }

    func stop() {
        synth.stopSpeaking(at: .immediate)
        if usingFallbackProcess {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pkill")
            process.arguments = ["-x", "say"]
            try? process.run()
            usingFallbackProcess = false
        }
        notifySpeaking(false)
    }

    private func startSpeaking(_ text: String) {
        notifySpeaking(true)

        if let voice = AVSpeechSynthesisVoice(language: "ar-SA") ?? arabicFallbackVoice() {
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = voice
            synth.speak(utterance)
            return
        }

        fallbackSay(text)
    }

    private func arabicFallbackVoice() -> AVSpeechSynthesisVoice? {
        AVSpeechSynthesisVoice.speechVoices().first { $0.language.hasPrefix("ar") }
    }

    private func fallbackSay(_ text: String) {
        usingFallbackProcess = true
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        process.arguments = ["-v", "Maged", text]
        process.terminationHandler = { [weak self] _ in
            Task { @MainActor in
                self?.usingFallbackProcess = false
                self?.notifySpeaking(false)
            }
        }
        try? process.run()
    }

    private func notifySpeaking(_ speaking: Bool) {
        onSpeakingChanged?(speaking)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        willSpeakRangeOfSpeechString characterRange: NSRange,
        utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in
            onSpeakRange?(characterRange.location, characterRange.length)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            notifySpeaking(false)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            notifySpeaking(false)
        }
    }
}
