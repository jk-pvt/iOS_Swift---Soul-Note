import SwiftUI

struct ARMemoryEntryView: View {
    let memory: Memory
    let personName: String
    let onEnterAR: () -> Void
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            DesignTokens.introGradient
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 16) {
                    Text(memory.title)
                        .font(DesignTokens.heroTitle())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: DesignTokens.introTextGlow, radius: 20)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    
                    Text(personName)
                        .font(DesignTokens.nameDisplay())
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                VStack(spacing: 24) {
                    Text("Place this memory where it belongs.")
                        .font(DesignTokens.bodyText())
                        .foregroundColor(DesignTokens.amberGlow)
                        .multilineTextAlignment(.center)
                        .opacity(showContent ? 1 : 0)
                    
                    Button(action: {
                        HapticService.shared.medium()
                        withAnimation(.easeOut(duration: 0.4)) {
                            showContent = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onEnterAR()
                        }
                    }) {
                        Text("Enter Memory")
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
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.2)) {
                showContent = true
            }
        }
    }
}
