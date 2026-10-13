import SwiftUI
import PencilKit

@main
struct SoulNoteApp: App {
    @StateObject private var storage = MockDataService.shared
    @StateObject private var audioService = AudioService.shared

    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    /// True after the guided first-run arc (Intro → Write → Seal) is complete
    @AppStorage("hasCompletedFirstRun") private var hasCompletedFirstRun = false

    @State private var letterToDeliver: Letter?
    @State private var showDeliveryRitual = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if !hasSeenIntro {
                    IntroView(hasSeenIntro: $hasSeenIntro)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))

                } else if !hasCompletedFirstRun {
                    // Walks new users through: Write a letter → Seal it
                    FirstRunArcView(onComplete: {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            hasCompletedFirstRun = true
                        }
                    })
                    .environmentObject(storage)
                    .environmentObject(audioService)
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))

                } else {
                    DashboardView()
                        .environmentObject(storage)
                        .environmentObject(audioService)
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                        .onAppear {
                            setupNotificationHandling()
                            checkForDeliveries()
                        }
                }
            }
            .animation(.easeInOut(duration: 0.8), value: hasSeenIntro)
            .animation(.easeInOut(duration: 0.8), value: hasCompletedFirstRun)
            .fullScreenCover(isPresented: $showDeliveryRitual) {
                if let letter = letterToDeliver,
                   let person = storage.people.first(where: { $0.id == letter.personId }) {
                    LetterDeliveryUnlockView(
                        letter: letter,
                        personName: person.name,
                        onComplete: {
                            showDeliveryRitual = false
                            letterToDeliver = nil
                            checkForDeliveries()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Letter Delivery Check

    private func checkForDeliveries() {
        let readyLetters = storage.lettersReadyForDelivery()
        if let firstLetter = readyLetters.first {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                letterToDeliver = firstLetter
                showDeliveryRitual = true
            }
        }
    }

    private func setupNotificationHandling() {
        LetterNotificationService.shared.onNotificationTap = { letterId in
            if let letter = storage.letters.first(where: { $0.id == letterId }) {
                if letter.currentState == .delivered || letter.isReadyForDelivery {
                    self.letterToDeliver = letter
                    self.showDeliveryRitual = true
                }
            }
        }
    }
}

// MARK: - First-Run Arc View

/// Step 1 — Write (a short letter to themselves or a loved one)
/// Step 2 — Seal (experience the ritual before reaching the dashboard)
struct FirstRunArcView: View {
    let onComplete: () -> Void
    @EnvironmentObject var storage: MockDataService

    @State private var currentStep: FirstRunStep = .welcome
    @State private var stepOpacity: Double = 0
    @State private var stepOffset: CGFloat = 30

    enum FirstRunStep {
        case welcome, write, seal, done
    }

    var body: some View {
        ZStack {
            DesignTokens.archiveBackground.ignoresSafeArea()
            FilmGrainTexture(opacity: 0.07).ignoresSafeArea().blendMode(.softLight)
            RadialGradient(
                colors: [Color.white.opacity(0.08), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 800
            ).ignoresSafeArea()

            switch currentStep {
            case .welcome:
                welcomeStep
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            case .write:
                writeStep
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity.combined(with: .move(edge: .leading))
                    ))
            case .seal:
                sealStep
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
            case .done:
                Color.clear
            }
        }
        .statusBar(hidden: true)
        .onAppear { animateIn() }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 48) {
            Spacer()

            ZStack {
                Circle()
                    .fill(DesignTokens.amberGlow.opacity(0.12))
                    .frame(width: 120, height: 120)
                    .blur(radius: 24)
                Image(systemName: "envelope.open.fill")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundColor(DesignTokens.amberGlow.opacity(0.85))
            }

            VStack(spacing: 16) {
                Text("Write Your First Letter")
                    .font(.system(size: 34, weight: .light, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Some words are too important\nfor a text message.\n\nLet's write one together.")
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }

            Spacer()

            CeremonialButton(title: "Begin Writing", icon: "pencil") {
                HapticService.shared.medium()
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentStep = .write
                }
            }
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 40)
        .opacity(stepOpacity)
        .offset(y: stepOffset)
    }

    // MARK: - Step 2: Write

    @State private var letterContent = ""
    @State private var demoDeliveryDate: Date? = nil
    @State private var showDemoDatePicker = false
    @State private var demoIsHandwriting = false
    @State private var demoCanvasView = PKCanvasView()
    @State private var demoHasDrawing = false

    private var writeStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Step 1 of 2")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .kerning(2)
                    .textCase(.uppercase)

                Text("Write Something True")
                    .font(.system(size: 26, weight: .light, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.top, 60)
            .padding(.bottom, 16)

            HStack(spacing: 0) {
                ForEach([(false, "keyboard", "Type"), (true, "pencil.tip", "Handwrite")], id: \.0) { isHand, icon, label in
                    Button {
                        HapticService.shared.light()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            demoIsHandwriting = isHand
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: icon)
                                .font(.system(size: 12, weight: .medium))
                            Text(label)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(demoIsHandwriting == isHand ? DesignTokens.archiveBackground : .white.opacity(0.55))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(demoIsHandwriting == isHand ? DesignTokens.amberGlow : Color.clear)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: demoIsHandwriting)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Capsule().fill(Color.black.opacity(0.3)).overlay(Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)))
            .padding(.horizontal, 60)
            .padding(.bottom, 12)

            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(DesignTokens.ivoryPaper)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

                PaperGrainView(opacity: 0.18)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                LinedPaperPatternView()
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                if demoIsHandwriting {
                    DemoCanvasView(canvasView: $demoCanvasView, onDrawingChanged: {
                        demoHasDrawing = !demoCanvasView.drawing.strokes.isEmpty
                    })
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    TextEditor(text: $letterContent)
                        .font(DesignTokens.letterText())
                        .foregroundColor(DesignTokens.inkColor)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .padding(24)
                        .lineSpacing(17)

                    if letterContent.isEmpty {
                        Text("Dear future reader,\n\nI wanted you to know…")
                            .font(DesignTokens.letterText())
                            .foregroundColor(DesignTokens.inkColor.opacity(0.3))
                            .padding(24)
                            .padding(.top, 8)
                            .allowsHitTesting(false)
                    }
                }
            }
            .padding(.horizontal, 24)
            .frame(maxHeight: 320)

            Button {
                HapticService.shared.light()
                showDemoDatePicker = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: demoDeliveryDate == nil ? "calendar.badge.clock" : "seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(demoDeliveryDate == nil ? .white.opacity(0.5) : DesignTokens.amberGlow)

                    if let date = demoDeliveryDate {
                        Text("Opens on \(date.formatted(date: .long, time: .omitted))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(DesignTokens.amberGlow)
                    } else {
                        Text("When should this arrive?")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.45))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.25))
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.25))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    demoDeliveryDate == nil
                                        ? Color.white.opacity(0.08)
                                        : DesignTokens.amberGlow.opacity(0.35),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .sheet(isPresented: $showDemoDatePicker) {
                HeritageDatePickerSheet(
                    selectedDate: Binding(
                        get: { demoDeliveryDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date())! },
                        set: { demoDeliveryDate = $0 }
                    ),
                    onDone: {
                        showDemoDatePicker = false
                        HapticService.shared.light()
                    }
                )
            }

            Spacer()

            // Next: seal the letter
            let hasContent = demoIsHandwriting ? demoHasDrawing : !letterContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            CeremonialButton(
                title: "Seal This Letter",
                icon: "seal.fill"
            ) {
                HapticService.shared.medium()
                saveDemoLetter()
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentStep = .seal
                }
            }
            .disabled(!hasContent)
            .opacity(hasContent ? 1 : 0.4)
            .padding(.bottom, 60)
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Step 3: Seal Ritual

    @State private var sealingPhase: SealingPhase = .idle
    @State private var envelopeScale: CGFloat = 0.6
    @State private var envelopeOpacity: Double = 0
    @State private var sealOpacity: Double = 0
    @State private var sealScale: CGFloat = 0
    @State private var completionOpacity: Double = 0
    @State private var completionOffset: CGFloat = 30

    enum SealingPhase { case idle, sealing, sealed, complete }

    private var sealStep: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Step 2 of 2")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .kerning(2)
                    .textCase(.uppercase)

                Text("Seal Your Letter")
                    .font(.system(size: 26, weight: .light, design: .serif))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.top, 60)

            Spacer()

            ZStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DesignTokens.envelopePaper)
                        .frame(width: 280, height: 180)
                        .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

                    EnvelopeFlapShape()
                        .fill(DesignTokens.envelopePaper.opacity(0.85))
                        .frame(width: 280, height: 90)
                        .offset(y: -90)

                    if sealingPhase != .idle {
                        WaxSealView(isPulsing: sealingPhase == .sealed, rotation: 0)
                            .offset(y: -45)
                            .scaleEffect(sealScale)
                            .opacity(sealOpacity)
                    }
                }
                .scaleEffect(envelopeScale)
                .opacity(envelopeOpacity)

                if sealingPhase == .complete {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 44))
                            .foregroundColor(DesignTokens.amberGlow)

                        Text("Your words are safe.")
                            .font(.system(size: 22, weight: .light, design: .serif))
                            .foregroundColor(.white)

                        Text("They will arrive exactly\nwhen they're needed.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                            .lineSpacing(5)
                    }
                    .opacity(completionOpacity)
                    .offset(y: completionOffset)
                }
            }

            Spacer()

            if sealingPhase == .complete {
                CeremonialButton(title: "Enter SoulNote", icon: "arrow.right") {
                    HapticService.shared.success()
                    onComplete()
                }
                .opacity(completionOpacity)
                .padding(.bottom, 60)
            } else if sealingPhase == .idle {
                CeremonialButton(title: "Press to Seal", icon: "seal") {
                    playSealingSequence()
                }
                .padding(.bottom, 60)
            }
        }
        .padding(.horizontal, 24)
        .onAppear { appearEnvelope() }
    }

    // MARK: - Sealing Sequence

    private func appearEnvelope() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            envelopeScale = 1.0
            envelopeOpacity = 1.0
        }
    }

    private func playSealingSequence() {
        sealingPhase = .sealing

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            envelopeScale = 0.95
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            HapticService.shared.heavy()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.45)) {
                sealScale = 1.15
                sealOpacity = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                sealScale = 1.0
                envelopeScale = 1.0
            }
            sealingPhase = .sealed
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            withAnimation(.easeInOut(duration: 0.55)) {
                envelopeOpacity = 0
                envelopeScale = 0.85
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            sealingPhase = .complete
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                completionOpacity = 1.0
                completionOffset = 0
            }
        }
    }

    // MARK: - Helpers

    private func animateIn() {
        withAnimation(.easeOut(duration: 1.0)) {
            stepOpacity = 1
            stepOffset = 0
        }
    }

    private func saveDemoLetter() {
        guard let demoPersonId = storage.people.first?.id else { return }
        let finalDate = demoDeliveryDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date())
        let content: String
        if demoIsHandwriting {
            let drawingData = demoCanvasView.drawing.dataRepresentation()
            content = "[HANDWRITTEN]" + drawingData.base64EncodedString()
        } else {
            content = letterContent
        }
        let letter = Letter(
            personId: demoPersonId,
            content: content,
            deliveryDate: finalDate
        )
        storage.addLetter(letter)
    }
}

// MARK: - Demo Canvas View

/// Lightweight PKCanvasView wrapper for the first-run arc write step.
struct DemoCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let onDrawingChanged: () -> Void

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: UIColor(DesignTokens.inkColor), width: 2)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onDrawingChanged) }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let onDrawingChanged: () -> Void
        init(_ onDrawingChanged: @escaping () -> Void) { self.onDrawingChanged = onDrawingChanged }
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) { onDrawingChanged() }
    }
}
