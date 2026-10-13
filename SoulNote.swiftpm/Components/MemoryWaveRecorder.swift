import SwiftUI

struct MemoryWaveRecorder: View {
    @EnvironmentObject var audioService: AudioService
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignTokens.nostalgiaAccent.opacity(0.8),
                            DesignTokens.nostalgiaAccent.opacity(0.3)
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 150
                    )
                )
                .frame(width: 200, height: 200)
                .scaleEffect(1.0 + Double(audioService.currentAmplitude) * 0.5)
                .animation(.easeInOut(duration: 0.1), value: audioService.currentAmplitude)
            
            Image(systemName: "waveform")
                .font(.system(size: 60))
                .foregroundColor(.white)
        }
    }
}
