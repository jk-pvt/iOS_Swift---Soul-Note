import SwiftUI
import PencilKit

// MARK: - Letter Editor View

struct LetterEditorView: View {
    let person: Person
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: MockDataService
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var typedContent = ""
    @State private var deliveryDate: Date?
    @State private var showingDatePicker = false

    @State private var isHandwritingMode = false
    @State private var canvasView = PKCanvasView()
    @State private var hasHandwriting = false

    @State private var modeToggleScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                WritingDeskBackground()

                VStack(spacing: 0) {
                    headerBar

                    modeTogglePill
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                    if isHandwritingMode {
                        HandwritingCanvasView(canvasView: $canvasView, hasDrawing: $hasHandwriting)
                            .transition(reduceMotion ? .opacity : .asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        TypedLetterEditor(content: $typedContent)
                            .transition(reduceMotion ? .opacity : .asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
            }
            .navigationTitle("Write Letter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Seal") { saveLetter() }
                        .disabled(!canSave)
                        .foregroundColor(canSave ? DesignTokens.amberGlow : .white.opacity(0.3))
                        .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingDatePicker) { datePicker }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 14) {
            if let photoPath = person.photoPath,
               let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 1))
            } else {
                Circle()
                    .fill(DesignTokens.archiveBrown.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(person.name.prefix(1)))
                            .font(.system(size: 18, weight: .light, design: .serif))
                            .foregroundColor(.white.opacity(0.7))
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("To \(person.name)")
                    .font(DesignTokens.nameDisplay())
                    .foregroundColor(.white)

                if let date = deliveryDate {
                    Text("Unlocks \(date.timelineString())")
                        .font(DesignTokens.metadata())
                        .foregroundColor(DesignTokens.amberGlow.opacity(0.9))
                } else {
                    Text("Tap to set an unlock date")
                        .font(DesignTokens.metadata())
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            Button {
                HapticService.shared.light()
                showingDatePicker.toggle()
            } label: {
                VStack(spacing: 3) {
                    Image(systemName: deliveryDate == nil ? "seal" : "seal.fill")
                        .font(.system(size: 20))
                    Text(deliveryDate == nil ? "Set Date" : "Change")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundColor(DesignTokens.amberGlow)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Mode Toggle Pill

    private var modeTogglePill: some View {
        HStack(spacing: 0) {
            modeButton(title: "Type", icon: "textformat", isActive: !isHandwritingMode) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isHandwritingMode = false
                }
            }
            modeButton(title: "Handwrite", icon: "pencil.tip", isActive: isHandwritingMode) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    isHandwritingMode = true
                }
            }
        }
        .background(
            Capsule()
                .fill(Color.black.opacity(0.3))
                .overlay(Capsule().stroke(Color.white.opacity(0.1), lineWidth: 1))
        )
    }

    private func modeButton(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticService.shared.light()
            action()
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                modeToggleScale = 0.94
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    modeToggleScale = 1.0
                }
            }
        }) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? DesignTokens.inkColor : .white.opacity(0.5))
                .padding(.horizontal, 20)
                .padding(.vertical, 9)
                .background(
                    Capsule()
                        .fill(isActive ? DesignTokens.ivoryPaper : Color.clear)
                        .shadow(color: isActive ? .black.opacity(0.2) : .clear, radius: 4, y: 2)
                )
        }
        .scaleEffect(modeToggleScale)
    }

    // MARK: - Date Picker Sheet

    private var datePicker: some View {
        HeritageDatePickerSheet(
            selectedDate: Binding(
                get: { deliveryDate ?? Calendar.current.date(byAdding: .year, value: 1, to: Date())! },
                set: { deliveryDate = $0 }
            ),
            onDone: { showingDatePicker = false }
        )
    }

    // MARK: - Save Logic

    private var canSave: Bool {
        isHandwritingMode ? hasHandwriting : !typedContent.isEmpty
    }

    private func saveLetter() {
        let finalContent: String
        if isHandwritingMode {
            // Encode PKDrawing as base64 for storage; LetterReadingView can render it
            let drawingData = canvasView.drawing.dataRepresentation()
            finalContent = "[HANDWRITTEN]" + drawingData.base64EncodedString()
        } else {
            finalContent = typedContent
        }

        let letter = Letter(
            personId: person.id,
            content: finalContent,
            deliveryDate: deliveryDate
        )

        if deliveryDate != nil {
            LetterNotificationService.shared.requestPermission { _ in
                storage.addLetter(letter)
                dismiss()
            }
        } else {
            storage.addLetter(letter)
            dismiss()
        }
    }
}

// MARK: - Typed Letter Editor

struct TypedLetterEditor: View {
    @Binding var content: String

    var body: some View {
        TextEditor(text: $content)
            .font(DesignTokens.letterText())
            .foregroundColor(DesignTokens.inkColor)
            .scrollContentBackground(.hidden)
            .padding(.horizontal, 40)
            .padding(.top, 40)
            .lineSpacing(17)
            .background(Color.clear)
    }
}

// MARK: - Handwriting Canvas

struct HandwritingCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var hasDrawing: Bool

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.tool = PKInkingTool(.pen, color: UIColor(DesignTokens.inkColor), width: 2.5)
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: HandwritingCanvasView
        init(_ parent: HandwritingCanvasView) { self.parent = parent }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.hasDrawing = !canvasView.drawing.strokes.isEmpty
        }
    }
}

// MARK: - Atmospheric Components

struct WritingDeskBackground: View {
    var body: some View {
        ZStack {
            DesignTokens.archiveBackground
                .ignoresSafeArea()

            FilmGrainTexture(opacity: 0.1)
                .blendMode(.softLight)
                .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(0.12), Color.clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 800
            )
            .ignoresSafeArea()

            VStack {
                Spacer()
                ZStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.ivoryPaper.opacity(0.8))
                        .offset(x: 4, y: 4)
                        .rotationEffect(.degrees(0.5))
                        .shadow(color: .black.opacity(0.1), radius: 2)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.ivoryPaper.opacity(0.9))
                        .offset(x: -3, y: 2)
                        .rotationEffect(.degrees(-0.3))
                        .shadow(color: .black.opacity(0.15), radius: 4)

                    ZStack {
                        DesignTokens.ivoryPaper

                        PaperGrainView(opacity: 0.2)

                        LinedPaperPatternView()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 2))
                    .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, -100)
            }
            .padding(.top, 120)
        }
    }
}

struct LinedPaperPatternView: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let lineSpacing: CGFloat = 36
                let startY: CGFloat = 40
                var currentY = startY
                while currentY < geometry.size.height + 100 {
                    path.move(to: CGPoint(x: 20, y: currentY))
                    path.addLine(to: CGPoint(x: geometry.size.width - 20, y: currentY))
                    currentY += lineSpacing
                }
            }
            .stroke(DesignTokens.archiveBrown.opacity(0.12), lineWidth: 0.5)
        }
    }
}
