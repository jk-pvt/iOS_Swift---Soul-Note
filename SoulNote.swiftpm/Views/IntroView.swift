import SwiftUI

/// Cinematic intro screen - Opening scene of a memory preservation experience
struct IntroView: View {
    @Binding var hasSeenIntro: Bool
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var showOnboarding = false
    @State private var hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    @State private var textOpacity1: Double = 0
    @State private var textOpacity2: Double = 0
    @State private var silhouetteOpacity: Double = 0
    @State private var breathingScale: CGFloat = 1.0
    @State private var gradientShift: Double = 0
    
    var body: some View {
        // Layout root: VStack controls where things appear
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 12) {
                Text("Memories fade.")
                    .font(.system(size: 52, weight: .light, design: .default))
                    .opacity(textOpacity1)
                
                Text("Voices shouldn't.")
                    .font(.system(size: 52, weight: .light, design: .default))
                    .opacity(textOpacity2)
                
                Text("Preserve the voices you love.")
                    .font(.system(size: 14, weight: .regular))
                    .italic()
                    .foregroundColor(.white.opacity(0.6))
                    .padding(.top, 8)
                    .opacity(textOpacity2)
            }
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .shadow(color: .white.opacity(0.12), radius: 10, y: 2)
            .padding(.horizontal, 24)
            
            Spacer()
            
            // CTA button — always visible, positioned by VStack layout
            CeremonialButton(
                title: "Begin Preserving",
                icon: "heart.fill",
                action: {
                    HapticService.shared.medium()
                    if !hasCompletedOnboarding {
                        showOnboarding = true
                    } else {
                        withAnimation(.easeOut(duration: 0.8)) {
                            hasSeenIntro = true
                        }
                    }
                }
            )
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                atmosphericGradient
                
                if let portrait = UIImage.loadFromAssetOrBundle("onboarding_preserve_lives") {
                    Image(uiImage: portrait)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .opacity(silhouetteOpacity * 0.4)
                        .blur(radius: 5)
                }
                
                FilmGrainTexture(opacity: 0.04)
                VignetteOverlay(opacity: 0.15)
                RadialBloom(opacity: 0.1)
            }
            .scaleEffect(breathingScale)
            .ignoresSafeArea()
        }
        .statusBar(hidden: true)
        .onAppear {
            startEntranceAnimations()
            startBreathingAnimation()
        }
        .overlay {
            if showOnboarding {
                OnboardingView(isPresented: $showOnboarding)
                    .transition(.opacity)
                    .zIndex(1000)
                    .onDisappear {
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        hasCompletedOnboarding = true
                        withAnimation(.easeOut(duration: 0.8)) {
                            hasSeenIntro = true
                        }
                    }
            }
        }
    }
    
    // MARK: - Atmospheric Gradient
    
    private var atmosphericGradient: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.82, green: 0.68, blue: 0.58), // Dusty peach
                    Color(red: 0.70, green: 0.52, blue: 0.57), // Muted rose
                    Color(red: 0.48, green: 0.33, blue: 0.52)  // Deep plum
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .hueRotation(.degrees(gradientShift))
            
            if !reduceMotion {
                FloatingParticleSystem(type: .lightRay, count: 8)
                    .opacity(0.7)
                
                FloatingParticleSystem(type: .paperFragment, count: 15)
                    .opacity(0.8)
                
                FloatingParticleSystem(type: .dust, count: 25)
                    .opacity(1.0)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 14).repeatForever(autoreverses: true)) {
                    gradientShift = 5
                }
            }
        }
    }
    
    // MARK: - Entrance Animations
    
    private func startEntranceAnimations() {
        // Stage 1: Silhouette fade in
        withAnimation(.easeIn(duration: 2.0)) {
            silhouetteOpacity = 1.0
        }
        
        // Stage 2: Hero text stage 1
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeOut(duration: 1.5)) {
                textOpacity1 = 1.0
            }
        }
        
        // Stage 3: Hero text stage 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation(.easeOut(duration: 1.5)) {
                textOpacity2 = 1.0
            }
        }
        
    }
    
    // MARK: - Breathing Animation
    private func startBreathingAnimation() {
        withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
            breathingScale = 1.03
        }
    }
}

// MARK: - Visual Effect Components

struct FilmGrainTexture: View {
    let opacity: Double
    
    var body: some View {
        Canvas { context, size in
            for _ in 0..<2000 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let grainSize = CGFloat.random(in: 0.3...1.2)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: grainSize, height: grainSize)),
                    with: .color(.white.opacity(opacity))
                )
            }
        }
    }
}

struct VignetteOverlay: View {
    let opacity: Double
    
    var body: some View {
        RadialGradient(
            colors: [
                .clear,
                .black.opacity(opacity)
            ],
            center: .center,
            startRadius: 100,
            endRadius: 600
        )
    }
}

struct RadialBloom: View {
    let opacity: Double
    
    var body: some View {
        RadialGradient(
            colors: [
                .white.opacity(opacity),
                .clear
            ],
            center: .center,
            startRadius: 0,
            endRadius: 400
        )
    }
}

// MARK: - Preview

#Preview {
    IntroView(hasSeenIntro: .constant(false))
}
