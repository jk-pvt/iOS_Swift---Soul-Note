import SwiftUI
import CoreHaptics

// MARK: - Sealed Letter Animation View (Idle State)

/// The sealed envelope that floats and glows while waiting to be tapped.
/// This is the "sealed" idle state shown before the user initiates unlock.
struct SealedLetterAnimationView: View {
    let onTap: () -> Void

    @State private var isFloating = false
    @State private var glowPulse = false
    @State private var dustParticles: [DustParticle] = []
    @State private var sealRotation: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            ForEach(dustParticles) { particle in
                Circle()
                    .fill(DesignTokens.dustParticle)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }

            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.deliveryGlow.opacity(glowPulse ? 0.18 : 0.06))
                        .frame(width: glowPulse ? 220 : 200, height: glowPulse ? 220 : 200)
                        .blur(radius: 28)

                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.35))
                            .frame(width: 284, height: 184)
                            .blur(radius: 18)
                            .offset(y: isFloating ? 12 : 20)

                        RoundedRectangle(cornerRadius: 10)
                            .fill(DesignTokens.envelopePaper)
                            .frame(width: 280, height: 180)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(DesignTokens.amberGlow.opacity(0.15), lineWidth: 1)
                            )

                        EnvelopeFlapShape()
                            .fill(DesignTokens.envelopePaper.opacity(0.85))
                            .frame(width: 280, height: 90)
                            .offset(y: -90)

                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 140, y: 90))
                            path.addLine(to: CGPoint(x: 280, y: 0))
                        }
                        .stroke(DesignTokens.archiveBrown.opacity(0.12), lineWidth: 0.8)
                        .frame(width: 280, height: 90)
                        .offset(y: -90)

                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 140, y: 90))
                            path.addLine(to: CGPoint(x: 280, y: 0))
                        }
                        .stroke(DesignTokens.archiveBrown.opacity(0.08), lineWidth: 0.6)
                        .frame(width: 280, height: 90)
                        .scaleEffect(x: 1, y: -1)
                        .offset(y: 90)

                        WaxSealView(isPulsing: glowPulse, rotation: sealRotation)
                            .offset(y: -45)
                    }
                    .frame(width: 280, height: 180)
                }
                .offset(y: isFloating ? -10 : 0)
            }
        }
        .onAppear { startAnimations() }
        .onTapGesture { onTap() }
    }

    private func startAnimations() {
        guard !reduceMotion else { return }

        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
            isFloating = true
        }
        withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) {
            glowPulse = true
        }
        withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
            sealRotation = 3
        }
        generateDustParticles()
    }

    private func generateDustParticles() {
        dustParticles = (0..<20).map { _ in
            DustParticle(
                position: CGPoint(x: CGFloat.random(in: 40...360), y: CGFloat.random(in: 80...620)),
                size: CGFloat.random(in: 1.5...5),
                opacity: Double.random(in: 0.08...0.28)
            )
        }
        for index in dustParticles.indices {
            withAnimation(
                .linear(duration: Double.random(in: 9...18))
                .repeatForever(autoreverses: false)
            ) {
                dustParticles[index].position.y -= CGFloat.random(in: 200...420)
                dustParticles[index].opacity = 0
            }
        }
    }
}

// MARK: - Wax Seal Subview

struct WaxSealView: View {
    let isPulsing: Bool
    let rotation: Double

    var body: some View {
        ZStack {
            Circle()
                .fill(DesignTokens.deliveryGlow.opacity(isPulsing ? 0.5 : 0.25))
                .frame(width: isPulsing ? 84 : 74, height: isPulsing ? 84 : 74)
                .blur(radius: 14)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignTokens.waxSealColor.opacity(0.9),
                            DesignTokens.waxSealColor
                        ],
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 0,
                        endRadius: 35
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: .black.opacity(0.45), radius: 8, y: 4)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )

            Image(systemName: "s.circle.fill")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white.opacity(0.75), DesignTokens.waxSealColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .rotationEffect(.degrees(rotation))
        }
    }
}

// MARK: - Seal Breaking View (Full Cinematic Ritual)

struct SealBreakingView: View {
    let onComplete: () -> Void

    @State private var crackProgress: CGFloat = 0
    @State private var fragmentOffsets: [CGSize] = Array(repeating: .zero, count: 8)
    @State private var fragmentOpacities: [Double] = Array(repeating: 1.0, count: 8)
    @State private var fragmentRotations: [Double] = Array(repeating: 0, count: 8)

    @State private var foldAngle: Double = 0      // 0 → 180 = folded
    @State private var unfoldAngle: Double = 180   // 180 → 0 = unfolded
    @State private var envelopeScale: CGFloat = 1.0
    @State private var envelopeOpacity: Double = 1.0
    @State private var shakeOffset: CGFloat = 0

    @State private var hapticEngine: CHHapticEngine?

    @Environment(\.accessibilityReduceMotion) var reduceMotion

    private let fragmentAngles: [Double] = [0, 45, 90, 135, 180, 225, 270, 315]

    var body: some View {
        ZStack {
            Color.black.opacity(0.2)
                .ignoresSafeArea()
                .opacity(crackProgress)

            VStack(spacing: 0) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.envelopePaper)
                        .frame(width: 280, height: 180)
                        .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
                        .scaleEffect(envelopeScale)
                        .opacity(envelopeOpacity)
                        .offset(x: shakeOffset)

                    if !reduceMotion {
                        EnvelopeFlapShape()
                            .fill(DesignTokens.envelopePaper.opacity(0.9))
                            .frame(width: 280, height: 90)
                            .offset(y: -90)
                            .rotation3DEffect(
                                .degrees(unfoldAngle),
                                axis: (x: 1, y: 0, z: 0),
                                anchor: .bottom,
                                perspective: 0.4
                            )
                            .opacity(envelopeOpacity)
                    }

                    ZStack {
                        WaxSealView(isPulsing: false, rotation: 0)
                            .opacity(max(0, 1.0 - crackProgress * 1.4))

                        CrackLinesShape(progress: crackProgress)
                            .stroke(Color.black.opacity(0.7), lineWidth: 1.8)
                            .frame(width: 64, height: 64)

                        ForEach(0..<8, id: \.self) { i in
                            Circle()
                                .fill(DesignTokens.waxSealColor)
                                .frame(width: CGFloat.random(in: 5...12), height: CGFloat.random(in: 5...12))
                                .offset(fragmentOffsets[i])
                                .opacity(fragmentOpacities[i])
                                .rotationEffect(.degrees(fragmentRotations[i]))
                        }
                    }
                    .offset(y: -45)
                    .scaleEffect(envelopeScale)
                    .opacity(envelopeOpacity)
                }
                .offset(x: shakeOffset)
            }
        }
        .onAppear { prepareHaptics(); startBreakingSequence() }
    }

    // MARK: - Animation Sequence

    private func startBreakingSequence() {
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.6)) { envelopeOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { onComplete() }
            return
        }

        withAnimation(.easeInOut(duration: 0.07).repeatCount(6, autoreverses: true)) {
            shakeOffset = 4
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            playWaxSealHaptic()
            withAnimation(.easeIn(duration: 0.55)) { crackProgress = 1.0 }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            for i in 0..<8 {
                let angle = fragmentAngles[i] * .pi / 180
                let distance = CGFloat.random(in: 40...90)
                withAnimation(.easeOut(duration: 0.6).delay(Double(i) * 0.03)) {
                    fragmentOffsets[i] = CGSize(
                        width: cos(angle) * distance,
                        height: sin(angle) * distance
                    )
                    fragmentOpacities[i] = 0
                    fragmentRotations[i] = Double.random(in: -120...120)
                }
            }
        }

        // Phase 4 — envelope scale-up slightly then flap unfolds (0.9s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            playUnfoldHaptic()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                envelopeScale = 1.06
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.1)) {
                unfoldAngle = 0   // flap swings open
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
            withAnimation(.easeInOut(duration: 0.55)) {
                envelopeOpacity = 0
                envelopeScale = 0.88
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.35) {
            onComplete()
        }
    }

    // MARK: - Core Haptics

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        hapticEngine = try? CHHapticEngine()
        try? hapticEngine?.start()
    }

    /// Light tap → heavy stamp → buzz fade — the wax seal cracking moment
    private func playWaxSealHaptic() {
        guard let engine = hapticEngine else {
            HapticService.shared.medium()
            return
        }
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.35),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
                ],
                relativeTime: 0.28
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.33,
                duration: 0.45
            )
        ]
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: 0)
    }

    private func playUnfoldHaptic() {
        guard let engine = hapticEngine else { return }
        let events: [CHHapticEvent] = [
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.18),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.1)
                ],
                relativeTime: 0,
                duration: 0.6
            )
        ]
        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: 0)
    }
}

// MARK: - Shared Shapes

struct EnvelopeFlapShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

struct CrackLinesShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let primaryAngles: [Double] = [0, 45, 90, 135, 180, 225, 270, 315]
        let branchAngles: [Double]  = [22, 67, 157, 247]

        for angle in primaryAngles {
            let rad = angle * .pi / 180
            let len = rect.width * 0.52 * progress
            let endX = center.x + cos(rad) * len
            let endY = center.y + sin(rad) * len
            path.move(to: center)
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        for angle in branchAngles {
            let rad = angle * .pi / 180
            let len = rect.width * 0.3 * progress
            let endX = center.x + cos(rad) * len
            let endY = center.y + sin(rad) * len
            path.move(to: center)
            path.addLine(to: CGPoint(x: endX, y: endY))
        }
        return path
    }
}

// MARK: - Dust Particle Model

struct DustParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var opacity: Double
}
