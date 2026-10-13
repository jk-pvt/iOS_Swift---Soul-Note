import SwiftUI

/// Text overlay component for titles, dates, and letter content
struct StorybookTextOverlay: View {
    let title: String
    let date: Date
    let letterText: String?
    let isVisible: Bool
    
    @State private var showTitle = false
    @State private var showLetter = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            if showTitle {
                VStack(spacing: 8) {
                    Text(title)
                        .font(DesignTokens.nameDisplay())
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)
                    
                    Text(date.timelineString())
                        .font(DesignTokens.metadata())
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
                .transition(.opacity)
            }
            
            if let letterText = letterText, showLetter {
                ScrollView {
                    Text(letterText)
                        .font(DesignTokens.letterText())
                        .foregroundColor(.white.opacity(0.95))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                        .padding(.horizontal, 40)
                        .shadow(color: .black.opacity(0.6), radius: 6)
                }
                .frame(maxHeight: 200)
                .transition(.opacity)
            }
            
            Spacer()
                .frame(height: 100)
        }
        .onChange(of: isVisible) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showTitle = true
                    }
                }
                
                if letterText != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showLetter = true
                        }
                    }
                }
            } else {
                showTitle = false
                showLetter = false
            }
        }
    }
}
