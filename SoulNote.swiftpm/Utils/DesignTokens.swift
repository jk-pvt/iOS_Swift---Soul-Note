import SwiftUI

struct DesignTokens {
    // MARK: - Archival Color System
    
    static let archiveBackground = Color(red: 0.18, green: 0.16, blue: 0.15) // Warm charcoal
    static let ivoryPaper = Color(red: 0.98, green: 0.96, blue: 0.92) // Card background
    static let polaroidFrame = Color(red: 0.99, green: 0.98, blue: 0.96) // Brighter Polaroid white
    static let amberGlow = Color(red: 0.85, green: 0.65, blue: 0.45) // Accent
    static let tapeColor = Color(red: 0.95, green: 0.93, blue: 0.85).opacity(0.5) // Transparent tape
    static let softSepia = Color(red: 0.45, green: 0.35, blue: 0.28).opacity(0.3) // Dividers
    
    static let memoryPaper = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let nostalgiaAccent = Color(red: 0.85, green: 0.65, blue: 0.45)
    static let archiveBrown = Color(red: 0.45, green: 0.35, blue: 0.28)
    static let glowShadow = Color(red: 0.85, green: 0.65, blue: 0.45).opacity(0.3)
    
    // MARK: - Gradients (Minimal Usage)
    
    // Refined Intro Gradient (reduced saturation ~25% - dusty, memory-like tones)
    // Temperature variation: warmer bottom, cooler top for emotional depth
    static let introGradient = LinearGradient(
        colors: [
            Color(red: 0.78, green: 0.66, blue: 0.60), // Cooler dusty peach (top)
            Color(red: 0.70, green: 0.52, blue: 0.57), // Muted rose (middle)
            Color(red: 0.52, green: 0.36, blue: 0.50)  // Warmer deep plum (bottom)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let amberGradient = LinearGradient(
        colors: [
            Color(red: 0.90, green: 0.70, blue: 0.50),
            Color(red: 0.85, green: 0.65, blue: 0.45)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let introTextGlow = Color.white.opacity(0.12)
    
    // Recording Pulse Gradient (only for recording screen)
    static let recordingPulse = RadialGradient(
        colors: [
            Color(red: 0.85, green: 0.65, blue: 0.45).opacity(0.8), // Amber glow
            Color(red: 0.85, green: 0.65, blue: 0.45).opacity(0.3),
            Color.clear
        ],
        center: .center,
        startRadius: 50,
        endRadius: 150
    )
    
    static let sunsetGradient = introGradient
    
    // MARK: - Typography
    
    static func heroTitle() -> Font {
        .system(size: 48, weight: .light, design: .default)
    }
    
    static func appName() -> Font {
        .system(size: 48, weight: .bold, design: .default) // SF Pro Display, not serif
    }
    
    static func nameDisplay() -> Font {
        .system(size: 28, weight: .semibold, design: .rounded)
    }
    
    static func bodyText() -> Font {
        .system(size: 17, weight: .regular, design: .default)
    }
    
    static func metadata() -> Font {
        .system(size: 14, weight: .medium, design: .default)
    }
    
    static func letterText() -> Font {
        .system(size: 19, weight: .regular, design: .serif)
    }
    
    static func tagline() -> Font {
        .system(size: 14, weight: .regular, design: .serif) // Keep serif for emotional text
    }
    
    static func handLabeled() -> Font {
        .system(size: 20, weight: .medium, design: .serif) // Organic, quasi-handwritten
    }
    
    // MARK: - Spacing
    
    static let cardPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let buttonHeight: CGFloat = 56
    
    // MARK: - AR Memory Colors & Effects
    
    static let memoryAura = Color(red: 0.85, green: 0.65, blue: 0.45).opacity(0.2)
    static let dustParticle = Color(red: 0.95, green: 0.90, blue: 0.85).opacity(0.25)
    static let archivalWood = Color(red: 0.45, green: 0.35, blue: 0.28)
    
    // MARK: - AR Animation Durations
    
    static let memoryMaterializationDuration: Double = 2.8
    static let proximityTransitionDuration: Double = 0.8
    static let exitTransitionDuration: Double = 1.5

    // MARK: - Shadows (Depth, not glow)
    
    static func depthShadow(radius: CGFloat = 16, y: CGFloat = 8) -> some View {
        EmptyView()
            .shadow(color: Color.black.opacity(0.18), radius: radius, y: y)
    }
    
    // MARK: - Glassmorphism Support
    
    static func glassMaterial(opacity: Double = 0.3) -> some View {
        VisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
            .opacity(opacity)
    }
    
    // MARK: - Corner Radii
    
    static let cardCornerRadius: CGFloat = 16
    static let buttonCornerRadius: CGFloat = 28
    
    // MARK: - Legacy Tree Colors
    
    static let legacyNodeBorder = Color(red: 0.95, green: 0.93, blue: 0.88) // Archival ivory
    static let legacyNodeGlow = Color(red: 0.85, green: 0.65, blue: 0.45).opacity(0.15) // Subtle amber
    static let legacyConnector = Color(red: 0.85, green: 0.65, blue: 0.45).opacity(0.3) // Faded amber
    static let legacyBackgroundGradient = LinearGradient(
        colors: [
            Color(red: 0.18, green: 0.16, blue: 0.15),
            Color(red: 0.15, green: 0.13, blue: 0.12)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // MARK: - Legacy Tree Animation Durations
    
    static let nodeFloatDuration: Double = 4.0
    static let nodeScaleDuration: Double = 0.3
    static let connectorPulseDuration: Double = 3.0
    
    // MARK: - Letter Delivery Ritual
    
    static let sealedEnvelopeGradient = LinearGradient(
        colors: [
            Color(red: 0.12, green: 0.10, blue: 0.09),  // Deep archival black
            Color(red: 0.18, green: 0.16, blue: 0.15)   // Warm charcoal
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    
    static let waxSealColor = Color(red: 0.55, green: 0.15, blue: 0.15)  // Deep burgundy
    static let envelopePaper = Color(red: 0.92, green: 0.88, blue: 0.82) // Aged cream
    static let deliveryGlow = Color(red: 0.85, green: 0.65, blue: 0.45).opacity(0.4)
    
    static let letterPaperColor = Color(red: 0.96, green: 0.94, blue: 0.88) // Warm cream
    static let inkColor = Color(red: 0.17, green: 0.09, blue: 0.06)        // Dark brown ink
    static let sepiaVignette = Color(red: 0.25, green: 0.20, blue: 0.15).opacity(0.3)
    
    static func letterReadingFont() -> Font {
        .system(size: 20, weight: .regular, design: .serif)
    }
    
    static func letterTitleFont() -> Font {
        .system(size: 32, weight: .light, design: .serif)
    }
    
    // MARK: - 3D Animation System
    
    // Animation Durations (keeping under 4-5 seconds total)
    static let sealBreakDuration: Double = 0.8
    static let envelopeOpenDuration: Double = 1.2
    static let paperUnfoldDuration: Double = 1.5
    static let textFadeInDuration: Double = 1.0
    static let cardFlipDuration: Double = 0.6
    static let cardLiftDuration: Double = 0.3
    static let portalExpandDuration: Double = 1.0
    static let heroTransitionDuration: Double = 0.5
    static let particleFadeDuration: Double = 2.0
    static let cardEntranceDuration: Double = 0.8

    static let cardHoverLift: CGFloat = 10
    static let cardFlipRotation: Double = 180
    static let pageUnfoldAngle: Double = 45
    static let parallaxDepthMultiplier: CGFloat = 0.3
    static let perspectiveDepth: CGFloat = 0.8
    
    static let dustParticleCount: Int = 25
    static let paperFragmentCount: Int = 12
    static let particleDriftSpeed: Double = 15.0
    static let particleOpacityRange: ClosedRange<Double> = 0.1...0.25
    static let portalDepth: Float = 0.06 // 6cm depth for parallax window
    
    static let cardSpring = Animation.spring(response: 0.5, dampingFraction: 0.7)
    static let gentleSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let bouncySpring = Animation.spring(response: 0.4, dampingFraction: 0.6)
    
    static func cardShadow(lifted: Bool = false) -> some View {
        EmptyView()
            .shadow(
                color: .black.opacity(lifted ? 0.25 : 0.12),
                radius: lifted ? 24 : 12,
                y: lifted ? 16 : 6
            )
    }
    
    static func floatingShadow() -> some View {
        EmptyView()
            .shadow(color: .black.opacity(0.15), radius: 20, y: 10)
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView { UIVisualEffectView() }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) { uiView.effect = effect }
}
