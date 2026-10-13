import SwiftUI

struct FloatingParticleSystem: View {
    enum ParticleType {
        case dust
        case paperFragment
        case lightRay
    }
    
    let type: ParticleType
    let count: Int
    
    @State private var particles: [Particle] = []
    
    init(type: ParticleType = .dust, count: Int? = nil) {
        self.type = type
        self.count = count ?? (type == .dust ? DesignTokens.dustParticleCount : DesignTokens.paperFragmentCount)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    particleView(for: particle)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles()
            }
        }
    }
    
    @ViewBuilder
    private func particleView(for particle: Particle) -> some View {
        switch type {
        case .dust:
            Circle()
                .fill(Color.white.opacity(0.6)) // Increased from dustParticle color
                .frame(width: particle.size, height: particle.size)
                .blur(radius: 0.5) // Reduced blur
            
        case .paperFragment:
            RoundedRectangle(cornerRadius: 2)
                .fill(DesignTokens.envelopePaper.opacity(0.5)) // Increased from 0.3
                .frame(width: particle.size * 1.5, height: particle.size)
                .rotationEffect(.degrees(particle.rotation))
                .blur(radius: 0.3) // Reduced blur
            
        case .lightRay:
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            DesignTokens.amberGlow.opacity(0.3), // Increased from 0.1
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 3, height: particle.size * 3) // Increased width from 2
                .rotationEffect(.degrees(particle.rotation))
                .blur(radius: 1) // Reduced blur
        }
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<count).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: type == .dust ? 4...8 : 6...12), // Increased sizes
                opacity: Double.random(in: 0.4...0.8), // Increased opacity range
                rotation: Double.random(in: -30...30)
            )
        }
    }
    
    private func animateParticles() {
        for index in particles.indices {
            let duration = Double.random(in: (DesignTokens.particleDriftSpeed - 3)...(DesignTokens.particleDriftSpeed + 3))
            let delay = Double.random(in: 0...2)
            
            withAnimation(
                .linear(duration: duration)
                .repeatForever(autoreverses: false)
                .delay(delay)
            ) {
                particles[index].position.y -= CGFloat.random(in: 300...500)
                
                particles[index].position.x += CGFloat.random(in: -50...50)
                
                particles[index].opacity = 0
            }
            
            if type == .paperFragment {
                withAnimation(
                    .linear(duration: duration * 0.5)
                    .repeatForever(autoreverses: true)
                ) {
                    particles[index].rotation += Double.random(in: -45...45)
                }
            }
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
    var rotation: Double
}
