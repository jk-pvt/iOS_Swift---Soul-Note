import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    
    let features = [
        Feature(
            icon: "person.crop.circle.badge.plus",
            title: "Preserve Lives",
            description: "Keep the essence of those who shaped your world alive forever.",
            imagePath: "onboarding_preserve_lives"
        ),
        Feature(
            icon: "mic.circle.fill",
            title: "Capture Voices",
            description: "Record the stories that only they can tell, in the voice you can't forget.",
            imagePath: "onboarding_capture_voices"
        ),
        Feature(
            icon: "envelope.fill",
            title: "Sent Letters",
            description: "Reach across time. Send meaningful letters that unlock in the future.",
            imagePath: "onboarding_write_letters"
        ),
        Feature(
            icon: "sparkles",
            title: "Legacy Threads",
            description: "Visualize the invisible connections that bind your history together.",
            imagePath: "onboarding_legacy_tree"
        )
    ]
    
    var body: some View {
        // VStack drives layout — background can NEVER affect button position
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    HapticService.shared.light()
                    isPresented = false
                }) {
                    Text("Skip")
                        .font(DesignTokens.metadata())
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                }
            }
            .padding(.top, 10)
            
            Spacer()
            
            FeatureCard(
                icon: features[currentPage].icon,
                title: features[currentPage].title,
                description: features[currentPage].description
            )
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity),
                removal: .opacity
            ))
            .id("card_\(currentPage)")
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            
            HStack(spacing: 8) {
                ForEach(0..<features.count, id: \.self) { index in
                    Capsule()
                        .fill(index == currentPage ? Color.white : Color.white.opacity(0.2))
                        .frame(width: index == currentPage ? 24 : 8, height: 4)
                }
            }
            .padding(.bottom, 32)
            .animation(.spring(), value: currentPage)
            
            Button(action: {
                HapticService.shared.light()
                if currentPage < features.count - 1 {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        currentPage += 1
                    }
                } else {
                    isPresented = false
                }
            }) {
                HStack(spacing: 12) {
                    Text(currentPage < features.count - 1 ? "Next" : "Begin")
                        .font(.system(size: 17, weight: .medium))
                    Image(systemName: currentPage < features.count - 1 ? "arrow.right" : "heart.fill")
                        .font(.system(size: 15, weight: .light))
                }
                .foregroundColor(DesignTokens.archiveBackground)
                .padding(.horizontal, 36)
                .frame(height: 56)
                .frame(minWidth: 220, maxWidth: 340)
                .background(
                    Capsule()
                        .fill(DesignTokens.amberGradient)
                        .shadow(color: DesignTokens.amberGlow.opacity(0.45), radius: 20, x: 0, y: 0)
                        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            ZStack {
                Color.black
                
                if let uiImage = UIImage.loadFromAssetOrBundle(features[currentPage].imagePath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                        .id("bg_\(currentPage)")
                }
                
                LinearGradient(
                    colors: [.clear, .black.opacity(0.4), .black.opacity(0.85)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                FilmGrainTexture(opacity: 0.05)
            }
            .animation(.easeInOut(duration: 1.2), value: currentPage)
            .ignoresSafeArea()
        }
    }
}

struct Feature {
    let icon: String
    let title: String
    let description: String
    let imagePath: String
}
