import SwiftUI

/// Atmospheric background with floating particles and parallax layers
struct AtmosphericBackgroundView: View {
    @State private var parallaxOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            DesignTokens.archiveBackground
                .ignoresSafeArea()
            
            FloatingParticleSystem(type: .lightRay, count: 8)
                .offset(y: parallaxOffset * 0.1)
                .opacity(0.3)
            
            FloatingParticleSystem(type: .paperFragment, count: DesignTokens.paperFragmentCount)
                .offset(y: parallaxOffset * 0.2)
            
            FloatingParticleSystem(type: .dust, count: DesignTokens.dustParticleCount)
                .offset(y: parallaxOffset * 0.3)
            
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    DesignTokens.archiveBackground.opacity(0.5)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
    
    func updateParallax(offset: CGFloat) {
        parallaxOffset = offset
    }
}
