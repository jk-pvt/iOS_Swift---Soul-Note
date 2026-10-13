import SwiftUI

/// Beautiful letter reading experience with 3D unfold animation
struct LetterReadingView: View {
    let letter: Letter
    let personName: String
    let onPreserve: () -> Void
    
    @State private var unfoldProgress: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var showContent = false
    @State private var exportedImage: Image?
    @Environment(\.dismiss) private var dismiss
    
    @MainActor
    private func render() {
        let renderer = ImageRenderer(content: 
            LetterExportView(letter: letter, personName: personName)
        )
        
        // Match the scale of the device screen for high quality
        renderer.scale = UIScreen.main.scale
        
        if let uiImage = renderer.uiImage {
            exportedImage = Image(uiImage: uiImage)
        }
    }
    
    var body: some View {
        ZStack {
            ZStack {
                DesignTokens.letterPaperColor
                    .ignoresSafeArea()
                
                PaperGrainView(opacity: 0.08)
                    .ignoresSafeArea()
                
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        DesignTokens.sepiaVignette
                    ],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()
            }
            
            if showContent {
                ScrollView {
                    VStack(spacing: 32) {
                        VStack(spacing: 12) {
                            Text("To \(personName)")
                                .font(DesignTokens.letterTitleFont())
                                .foregroundColor(DesignTokens.inkColor)
                            
                            if let deliveryDate = letter.deliveryDate {
                                Text("Written on \(letter.createdAt.timelineString())")
                                    .font(DesignTokens.metadata())
                                    .foregroundColor(DesignTokens.inkColor.opacity(0.6))
                                
                                Text("Delivered on \(deliveryDate.timelineString())")
                                    .font(DesignTokens.metadata())
                                    .foregroundColor(DesignTokens.amberGlow)
                            }
                        }
                        .padding(.top, 60)
                        
                        if letter.isHandwritten {
                            HStack {
                                Image(systemName: "pencil.tip")
                                    .foregroundColor(DesignTokens.amberGlow)
                                Text("Handwritten letter")
                                    .font(DesignTokens.letterReadingFont())
                                    .italic()
                                    .foregroundColor(DesignTokens.inkColor.opacity(0.6))
                            }
                            .padding(.horizontal, 32)
                            .opacity(textOpacity)
                        } else {
                            Text(letter.content)
                                .font(DesignTokens.letterReadingFont())
                                .foregroundColor(DesignTokens.inkColor)
                                .lineSpacing(8)
                                .multilineTextAlignment(.leading)
                                .padding(.horizontal, 32)
                                .opacity(textOpacity)
                        }
                        
                        Spacer(minLength: 100)
                    }
                }
                .transition(.opacity)
                
                VStack(spacing: 16) {
                    Spacer()
                    
                    if let image = exportedImage {
                        ShareLink(
                            item: image,
                            preview: SharePreview(
                                "Letter to \(personName)",
                                image: image
                            )
                        ) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Deliver to Recipient")
                            }
                            .font(DesignTokens.bodyText().weight(.semibold))
                            .foregroundColor(DesignTokens.amberGlow)
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignTokens.buttonHeight)
                            .background(
                                RoundedRectangle(cornerRadius: 28)
                                    .stroke(DesignTokens.amberGlow, lineWidth: 2)
                            )
                        }
                        .padding(.horizontal, 32)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .frame(height: DesignTokens.buttonHeight)
                            .padding(.horizontal, 32)
                            .onAppear { render() }
                    }
                    
                    Button(action: {
                        HapticService.shared.success()
                        onPreserve()
                    }) {
                        HStack {
                            Image(systemName: "archivebox.fill")
                            Text("Archive in Soul Collection")
                        }
                        .font(DesignTokens.bodyText().weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: DesignTokens.buttonHeight)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(DesignTokens.amberGradient)
                        )
                        .shadow(color: DesignTokens.amberGlow, radius: 12)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
                }
            } else {
                PaperUnfoldView(progress: unfoldProgress)
            }
        }
        .onAppear {
            startUnfoldAnimation()
        }
    }
    
    private func startUnfoldAnimation() {
        withAnimation(.easeOut(duration: DesignTokens.paperUnfoldDuration)) {
            unfoldProgress = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.paperUnfoldDuration) {
            withAnimation(.easeIn(duration: 0.3)) {
                showContent = true
            }
            
            withAnimation(.easeIn(duration: DesignTokens.textFadeInDuration).delay(0.2)) {
                textOpacity = 1.0
            }
        }
    }
}

struct PaperUnfoldView: View {
    let progress: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 0)
                    .fill(DesignTokens.letterPaperColor)
                    .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.6)
                    .rotation3DEffect(
                        .degrees(Double(90 - (90 * progress))),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: .bottom,
                        perspective: 0.5
                    )
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
}

/// A dedicated view for rendering a letter as a beautiful, shareable image.
struct LetterExportView: View {
    let letter: Letter
    let personName: String
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                DesignTokens.letterPaperColor
                    .ignoresSafeArea()
                
                PaperGrainView(opacity: 0.12)
                    .ignoresSafeArea()
                
                RadialGradient(
                    colors: [
                        Color.clear,
                        Color.clear,
                        DesignTokens.sepiaVignette.opacity(0.4)
                    ],
                    center: .center,
                    startRadius: 200,
                    endRadius: 600
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    VStack(spacing: 8) {
                        Text("To \(personName)")
                            .font(DesignTokens.letterTitleFont())
                            .foregroundColor(DesignTokens.inkColor)
                        
                        Rectangle()
                            .fill(DesignTokens.softSepia)
                            .frame(width: 100, height: 1)
                        
                        Text("Delivered on \(letter.deliveryDate?.timelineString() ?? "the appointed time")")
                            .font(DesignTokens.metadata())
                            .foregroundColor(DesignTokens.inkColor.opacity(0.5))
                    }
                    .padding(.top, 60)
                    
                    Text(letter.displayContent)
                        .font(DesignTokens.letterReadingFont())
                        .foregroundColor(DesignTokens.inkColor)
                        .lineSpacing(10)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("SOULNOTE")
                            .font(.system(size: 12, weight: .bold, design: .default))
                            .tracking(3)
                            .foregroundColor(DesignTokens.inkColor.opacity(0.3))
                        
                        Text("A digital heirloom preserved forever.")
                            .font(.system(size: 10, weight: .regular, design: .serif).italic())
                            .foregroundColor(DesignTokens.inkColor.opacity(0.25))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .frame(width: 500) // Fixed width for consistent export quality
        .background(DesignTokens.letterPaperColor)
    }
}
