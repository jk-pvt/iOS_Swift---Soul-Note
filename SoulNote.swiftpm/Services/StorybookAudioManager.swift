import Foundation
import AVFoundation

@MainActor
class StorybookAudioManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentChapterAudioDuration: TimeInterval = 0
    @Published var enableAmbientBed = false // Optional ambient layer
    
    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    private var completionHandler: (() -> Void)?
    
    func preloadAudio(at path: String) -> TimeInterval? {
        guard FileManager.default.fileExists(atPath: path) else { return nil }
        
        let url = URL(fileURLWithPath: path)
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            return player.duration
        } catch {
            print("Error preloading audio: \(error)")
            return nil
        }
    }
    
    func playChapterAudio(at path: String?, completion: @escaping () -> Void) {
        guard let path = path, FileManager.default.fileExists(atPath: path) else {
            completion()
            return
        }
        
        completionHandler = completion
        let url = URL(fileURLWithPath: path)
        
        do {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .default)
            try? session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.volume = 0.0 // Start silent for fade-in
            audioPlayer?.play()
            
            currentChapterAudioDuration = audioPlayer?.duration ?? 0
            isPlaying = true
            
            fadeIn()
        } catch {
            print("Error playing chapter audio: \(error)")
            completion()
        }
    }
    
    /// Stops current audio with fade-out and silence gap before next chapter
    func stopWithFadeAndGap(completion: @escaping () -> Void) {
        guard let player = audioPlayer, player.isPlaying else {
            completion()
            return
        }
        
        fadeOut { [weak self] in
            self?.audioPlayer?.stop()
            self?.isPlaying = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                completion()
            }
        }
    }
    
    func stop() {
        fadeTimer?.invalidate()
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        completionHandler = nil
    }
    
    // MARK: - Fade Transitions
    
    private func fadeIn() {
        guard let player = audioPlayer else { return }
        
        let fadeDuration: TimeInterval = 0.3
        let steps = 30
        let stepDuration = fadeDuration / Double(steps)
        let volumeIncrement = 1.0 / Float(steps)
        
        var currentStep = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            player.volume = min(volumeIncrement * Float(currentStep), 1.0)
            
            if currentStep >= steps {
                timer.invalidate()
                self?.fadeTimer = nil
            }
        }
    }
    
    private func fadeOut(completion: @escaping () -> Void) {
        guard let player = audioPlayer else {
            completion()
            return
        }
        
        let fadeDuration: TimeInterval = 0.3
        let steps = 30
        let stepDuration = fadeDuration / Double(steps)
        let volumeDecrement = player.volume / Float(steps)
        
        var currentStep = 0
        fadeTimer = Timer.scheduledTimer(withTimeInterval: stepDuration, repeats: true) { [weak self] timer in
            currentStep += 1
            player.volume = max(player.volume - volumeDecrement, 0.0)
            
            if currentStep >= steps {
                timer.invalidate()
                self?.fadeTimer = nil
                completion()
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension StorybookAudioManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.completionHandler?()
            self.completionHandler = nil
        }
    }
}
