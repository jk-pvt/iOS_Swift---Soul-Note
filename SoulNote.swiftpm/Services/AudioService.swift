import Foundation
import AVFoundation

@MainActor
class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()
    
    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var playbackProgress: Double = 0
    @Published var currentAmplitude: Float = 0
    @Published var lastRecordingPath: String?
    @Published var audioDuration: TimeInterval?
    @Published var currentPlaybackTime: TimeInterval = 0
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var recordingTimer: Timer?
    private var amplitudeTimer: Timer?
    private var playbackTimer: Timer?
    
    private override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)
    }
    
    // MARK: - Recording
    
    func startRecording() {
        let path = FileManager.generateAudioPath()
        let url = URL(fileURLWithPath: path)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            
            isRecording = true
            recordingDuration = 0
            lastRecordingPath = path
            
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration += 0.1
                }
            }
            
            amplitudeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.audioRecorder?.updateMeters()
                    let power = self?.audioRecorder?.averagePower(forChannel: 0) ?? -160
                    self?.currentAmplitude = self?.normalizedPower(power) ?? 0
                }
            }
        } catch {
            lastRecordingPath = nil
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        amplitudeTimer?.invalidate()
        isRecording = false
        currentAmplitude = 0
    }
    
    private func normalizedPower(_ power: Float) -> Float {
        let minDb: Float = -80
        let maxDb: Float = 0
        let clampedPower = max(minDb, min(power, maxDb))
        return (clampedPower - minDb) / (maxDb - minDb)
    }
    
    // MARK: - Playback
    
    func prepareAudio(at path: String) {
        guard let url = URL.audioFromBundleOrPath(path) else {
            print("⚠️ AudioService: Could not find audio file for preparation: \(path)")
            audioDuration = nil
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            audioDuration = player.duration
        } catch {
            print("⚠️ AudioService: Failed to prepare audio - \(error.localizedDescription)")
            audioDuration = nil
        }
    }
    
    func playAudio(from path: String) {
        stopAudio()
        
        guard let url = URL.audioFromBundleOrPath(path) else {
            print("⚠️ AudioService: Could not find audio file: \(path)")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            let success = audioPlayer?.play() ?? false
            if success {
                isPlaying = true
                audioDuration = audioPlayer?.duration
                print("✅ AudioService: Playing audio '\(path)', duration: \(audioDuration ?? 0)s")
            } else {
                print("⚠️ AudioService: Failed to start playback for '\(path)'")
            }
            
            playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, let player = self.audioPlayer else { return }
                    self.currentPlaybackTime = player.currentTime
                    if let duration = self.audioDuration, duration > 0 {
                        self.playbackProgress = player.currentTime / duration
                    }
                }
            }
        } catch {
            print("⚠️ AudioService: Failed to play audio - \(error.localizedDescription)")
        }
    }
    
    func stopAudio() {
        audioPlayer?.stop()
        playbackTimer?.invalidate()
        isPlaying = false
        playbackProgress = 0
        currentPlaybackTime = 0
    }
    
    func pauseAudio() {
        audioPlayer?.pause()
        playbackTimer?.invalidate()
        isPlaying = false
    }
    
    func resumeAudio() {
        audioPlayer?.play()
        isPlaying = true
        
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let player = self.audioPlayer else { return }
                self.currentPlaybackTime = player.currentTime
                if let duration = self.audioDuration, duration > 0 {
                    self.playbackProgress = player.currentTime / duration
                }
            }
        }
    }
}

extension AudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.playbackTimer?.invalidate()
            self.isPlaying = false
            self.playbackProgress = 0
            self.currentPlaybackTime = 0
        }
    }
}
