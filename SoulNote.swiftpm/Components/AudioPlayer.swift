import SwiftUI

struct AudioPlayer: View {
    let audioPath: String
    @EnvironmentObject var audioService: AudioService
    @State private var waveformHeights: [CGFloat] = []
    @State private var animationTimer: Timer?
    
    var body: some View {
        VStack(spacing: 16) {
            if let duration = audioService.audioDuration, duration > 0 {
                HStack {
                    Text(formatTime(audioService.currentPlaybackTime))
                        .font(DesignTokens.metadata())
                        .foregroundColor(DesignTokens.archiveBrown)
                    
                    Spacer()
                    
                    Text(formatTime(duration))
                        .font(DesignTokens.metadata())
                        .foregroundColor(DesignTokens.archiveBrown.opacity(0.7))
                }
                .padding(.horizontal, 8)
            }
            
            HStack(spacing: 2) {
                ForEach(Array(waveformHeights.enumerated()), id: \.offset) { index, height in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.nostalgiaAccent)
                        .frame(width: 3, height: height)
                        .animation(.easeInOut(duration: 0.3), value: height)
                }
            }
            .frame(height: 50)
            
            Button(action: togglePlayback) {
                Image(systemName: audioService.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(DesignTokens.nostalgiaAccent)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(DesignTokens.memoryPaper.opacity(0.5))
        )
        .onAppear {
            initializeWaveform()
            audioService.prepareAudio(at: audioPath)
        }
        .onDisappear {
            stopAnimation()
        }
        .onChange(of: audioService.isPlaying) { isPlaying in
            if isPlaying {
                startAnimation()
            } else {
                stopAnimation()
            }
        }
    }
    
    private func initializeWaveform() {
        waveformHeights = (0..<30).map { _ in CGFloat.random(in: 10...40) }
    }
    
    private func startAnimation() {
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { _ in
            for i in 0..<waveformHeights.count {
                waveformHeights[i] = CGFloat.random(in: 15...45)
            }
        }
    }
    
    private func stopAnimation() {
        animationTimer?.invalidate()
        animationTimer = nil
        initializeWaveform()
    }
    
    private func togglePlayback() {
        if audioService.isPlaying {
            audioService.pauseAudio()
        } else {
            audioService.playAudio(from: audioPath)
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
