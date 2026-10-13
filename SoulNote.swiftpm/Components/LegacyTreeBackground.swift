import SwiftUI

struct LegacyTreeBackground: View {
    @State private var particleOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            DesignTokens.legacyBackgroundGradient
                .ignoresSafeArea()
            
            PaperGrainView(opacity: 0.08)
                .blur(radius: 3)
                .ignoresSafeArea()
                .blendMode(.softLight)
            
            FloatingDustView()
                .ignoresSafeArea()
        }
    }
}

struct FloatingDustView: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(DesignTokens.dustParticle)
                        .frame(width: CGFloat.random(in: 2...4), height: CGFloat.random(in: 2...4))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height) + animationOffset
                        )
                        .blur(radius: 1)
                }
            }
            .onAppear {
                withAnimation(
                    .linear(duration: 20)
                    .repeatForever(autoreverses: false)
                ) {
                    animationOffset = -50
                }
            }
        }
    }
}
