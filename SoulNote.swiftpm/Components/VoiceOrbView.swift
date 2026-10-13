import SwiftUI

struct VoiceOrbView: View {
    let isRecording: Bool
    let audioLevel: CGFloat // Real-time amplitude from AudioService (0.0 to 1.0)
    @State private var pulseScale: CGFloat = 1.0
    @State private var particleOffsets: [CGPoint] = []
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignTokens.amberGlow.opacity(isRecording ? 0.4 : 0.2),
                            DesignTokens.amberGlow.opacity(isRecording ? 0.2 : 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: isRecording ? 200 : 150
                    )
                )
                .frame(width: 300, height: 300)
                .blur(radius: 30)
                .scaleEffect(pulseScale)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignTokens.amberGlow.opacity(0.9),
                            DesignTokens.amberGlow.opacity(0.6),
                            DesignTokens.amberGlow.opacity(0.3)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 80
                    )
                )
                .frame(width: 160, height: 160)
                .scaleEffect(isRecording ? (1.0 + audioLevel * 0.3) : 1.0)
                .shadow(color: DesignTokens.amberGlow.opacity(0.6), radius: 40)
            
            if isRecording {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            DesignTokens.amberGlow.opacity(0.3 - Double(index) * 0.1),
                            lineWidth: 2
                        )
                        .frame(width: 160 + CGFloat(index) * 40, height: 160 + CGFloat(index) * 40)
                        .scaleEffect(pulseScale)
                }
            }
            
            if isRecording {
                ForEach(0..<12, id: \.self) { index in
                    ParticleView()
                        .offset(
                            x: particleOffsets.indices.contains(index) ? particleOffsets[index].x : 0,
                            y: particleOffsets.indices.contains(index) ? particleOffsets[index].y : 0
                        )
                }
            }
        }
        .onAppear {
            if isRecording {
                startAnimations()
            }
        }
        .onChange(of: isRecording) { newValue in
            if newValue {
                startAnimations()
            }
        }
    }
    
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
        
        particleOffsets = (0..<12).map { index in
            let angle = Double(index) * (360.0 / 12.0) * .pi / 180.0
            let radius: CGFloat = 120
            return CGPoint(
                x: cos(angle) * radius,
                y: sin(angle) * radius
            )
        }
        
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            particleOffsets = particleOffsets.map { offset in
                let angle = atan2(offset.y, offset.x) + 0.1
                let radius = sqrt(offset.x * offset.x + offset.y * offset.y) * 1.2
                return CGPoint(
                    x: cos(angle) * radius,
                    y: sin(angle) * radius
                )
            }
        }
    }
}

struct ParticleView: View {
    @State private var opacity: Double = 0.0
    
    var body: some View {
        Circle()
            .fill(DesignTokens.amberGlow.opacity(opacity))
            .frame(width: 4, height: 4)
            .blur(radius: 1)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    opacity = 0.6
                }
            }
    }
}
