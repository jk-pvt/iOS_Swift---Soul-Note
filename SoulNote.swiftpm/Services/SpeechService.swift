import Foundation
import Speech
import AVFoundation

/// Handles all voice interactions for Story Mode (Speech-to-Text and Text-to-Speech).
/// Uses @MainActor class (not actor) so @Published properties work correctly with Combine.
@MainActor
class SpeechService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {

    // MARK: - Published State
    @Published var transcription: String = ""
    @Published var isListening: Bool = false
    @Published var isSpeaking: Bool = false
    @Published var audioLevel: Float = 0.0

    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private let synthesizer = AVSpeechSynthesizer()

    private var speechContinuation: CheckedContinuation<Void, Never>?

    // MARK: - Init
    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        // Request microphone access first using a backward-compatible API
        let micGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        guard micGranted else { return false }

        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }

    // MARK: - Text to Speech (awaitable)
    func speakAsync(_ text: String) async {
        stopListening()
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85 // Slightly slower, warm pace
        utterance.pitchMultiplier = 1.05
        utterance.postUtteranceDelay = 0.3

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            self.speechContinuation = continuation
            self.isSpeaking = true
            self.synthesizer.speak(utterance)
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.speechContinuation?.resume()
            self.speechContinuation = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.speechContinuation?.resume()
            self.speechContinuation = nil
        }
    }

    // MARK: - Speech to Text
    func startListening() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        
        // Force on-device recognition for offline compliance
        recognitionRequest.shouldReportPartialResults = true
        
        // Only set requiresOnDeviceRecognition if the device supports it
        if speechRecognizer?.supportsOnDeviceRecognition ?? false {
            recognitionRequest.requiresOnDeviceRecognition = true
        }

        let inputNode = audioEngine.inputNode

        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self else { return }
            if let result = result {
                Task { @MainActor in
                    self.transcription = result.bestTranscription.formattedString
                }
            }
            if error != nil || (result?.isFinal ?? false) {
                Task { @MainActor in self.stopListening() }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            recognitionRequest.append(buffer)
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let values = UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength))
            let avg = values.reduce(0) { $0 + abs($1) } / Float(buffer.frameLength)
            Task { @MainActor in self?.audioLevel = min(avg * 12, 1.0) }
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true
        transcription = "" // Clear previous transcription
    }

    func stopListening() {
        guard audioEngine.isRunning else { return }
        audioEngine.stop()
        // Safely remove tap (guard against crash if none installed)
        if audioEngine.inputNode.numberOfInputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isListening = false
        audioLevel = 0.0
    }

    /// Checks if speech recognition is available on this device and for the current locale.
    func checkAvailability() -> Bool {
        guard let recognizer = speechRecognizer else { return false }
        return recognizer.isAvailable
    }
}
