import AVFoundation
import UIKit

class SoundService {
    static let shared = SoundService()
    
    private init() {}
    
    func playShutter() {
        AudioServicesPlaySystemSound(1108)
    }
    
    func playWhoosh() {
        AudioServicesPlaySystemSound(1001)
    }
    
    func playChime() {
        AudioServicesPlaySystemSound(1315)
    }
    
    func playClick() {
        AudioServicesPlaySystemSound(1104)
    }
}
