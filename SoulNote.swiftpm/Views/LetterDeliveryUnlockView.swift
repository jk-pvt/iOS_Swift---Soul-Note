import SwiftUI

struct LetterDeliveryUnlockView: View {
    let letter: Letter
    let personName: String
    let onComplete: () -> Void
    
    @State private var showSealed = true
    @State private var showBreaking = false
    @State private var showReading = false
    @EnvironmentObject var storage: MockDataService
    
    var body: some View {
        ZStack {
            DesignTokens.sealedEnvelopeGradient
                .ignoresSafeArea()
            
            if showSealed {
                VStack(spacing: 40) {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Text("A letter has arrived")
                            .font(DesignTokens.letterTitleFont())
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text("From your memories of \(personName)")
                            .font(DesignTokens.bodyText())
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    SealedLetterAnimationView {
                        breakSeal()
                    }
                    
                    Text("Tap to open")
                        .font(DesignTokens.metadata())
                        .foregroundColor(DesignTokens.deliveryGlow)
                        .opacity(0.8)
                    
                    Spacer()
                }
                .transition(.opacity)
            } else if showBreaking {
                SealBreakingView {
                    openLetter()
                }
                .transition(.opacity)
            } else if showReading {
                LetterReadingView(
                    letter: letter,
                    personName: personName,
                    onPreserve: {
                        markAsOpened()
                        onComplete()
                    }
                )
                .transition(.opacity)
            }
        }
        .statusBar(hidden: true)
    }
    
    private func breakSeal() {
        SoundService.shared.playChime()
        
        withAnimation(.easeOut(duration: DesignTokens.sealBreakDuration)) {
            showSealed = false
            showBreaking = true
        }
    }
    
    private func openLetter() {
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignTokens.envelopeOpenDuration) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showBreaking = false
                showReading = true
            }
        }
    }
    
    private func markAsOpened() {
        storage.updateLetterState(letter.id, to: .opened, openedAt: Date())
    }
}

// SealBreakingView and CrackLinesShape are defined in SealedLetterAnimationView.swift
