import AVFoundation
import simd

/// Handles spatial audio playback for AR memory experiences
class SpatialAudioController {
    private var audioPlayer: AVAudioPlayer?
    private var fadeTimer: Timer?
    
    func loadAudio(from path: String) {
        guard let url = Bundle.module.url(forResource: path, withExtension: nil)
                ?? Bundle.module.url(forResource: path, withExtension: "m4a") else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch { }
    }
    
    func play(at position: simd_float3, fadeIn: Bool) {
        guard let player = audioPlayer else { return }
        if fadeIn {
            player.volume = 0
            player.play()
            fadeVolume(to: 1.0, duration: 0.8)
        } else {
            player.play()
        }
    }
    
    func updateListenerPosition(_ position: simd_float3) {
        // Spatial audio positioning placeholder
    }
    
    func fadeOutAndStop(duration: TimeInterval, completion: @escaping () -> Void) {
        fadeVolume(to: 0, duration: duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.audioPlayer?.stop()
            completion()
        }
    }
    
    func stop() {
        audioPlayer?.stop()
    }
    
    private func fadeVolume(to target: Float, duration: TimeInterval) {
        let steps = 10
        let stepDuration = duration / Double(steps)
        let currentVolume = audioPlayer?.volume ?? 0
        let delta = (target - currentVolume) / Float(steps)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) { [weak self] in
                self?.audioPlayer?.volume = currentVolume + delta * Float(i + 1)
            }
        }
    }
}
