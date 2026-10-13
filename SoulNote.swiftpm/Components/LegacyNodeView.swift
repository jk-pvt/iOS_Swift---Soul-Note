import SwiftUI

/// Individual memory node representing a person in the Legacy Tree
struct LegacyNodeView: View {
    let person: Person
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var floatOffset: CGFloat = 0
    @State private var glowPulse: Double = 0.15
    
    private let nodeSize: CGFloat = 100
    
    var body: some View {
        Button(action: {
            HapticService.shared.light()
            onTap()
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(DesignTokens.legacyNodeGlow)
                        .frame(width: nodeSize + 20, height: nodeSize + 20)
                        .blur(radius: 12)
                        .opacity(isSelected ? 1.0 : glowPulse)
                    
                    Circle()
                        .fill(DesignTokens.legacyNodeBorder)
                        .frame(width: nodeSize, height: nodeSize)
                        .shadow(color: Color.black.opacity(0.3), radius: 8, y: 4)
                    
                    Group {
                        if let photoPath = person.photoPath,
                           let uiImage = loadDownscaledImage(from: photoPath) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: nodeSize - 8, height: nodeSize - 8)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [
                                                    Color.clear,
                                                    Color.black.opacity(0.2)
                                                ],
                                                center: .center,
                                                startRadius: 30,
                                                endRadius: 50
                                            )
                                        )
                                )
                        } else {
                            ZStack {
                                Circle()
                                    .fill(DesignTokens.archiveBrown.opacity(0.1))
                                    .frame(width: nodeSize - 8, height: nodeSize - 8)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(DesignTokens.archiveBrown.opacity(0.3))
                            }
                        }
                    }
                }
                .frame(width: nodeSize, height: nodeSize)
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .animation(.easeOut(duration: DesignTokens.nodeScaleDuration), value: isSelected)
                
                Text(person.relationship)
                    .font(DesignTokens.metadata())
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .frame(width: nodeSize + 20)
            }
            .offset(y: floatOffset)
            .onAppear {
                startFloatingAnimation()
                startGlowPulse()
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(person.name), \(person.relationship)")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Animations
    
    private func startFloatingAnimation() {
        withAnimation(
            .easeInOut(duration: DesignTokens.nodeFloatDuration)
            .repeatForever(autoreverses: true)
        ) {
            floatOffset = CGFloat.random(in: -5...5)
        }
    }
    
    private func startGlowPulse() {
        withAnimation(
            .easeInOut(duration: DesignTokens.connectorPulseDuration)
            .repeatForever(autoreverses: true)
        ) {
            glowPulse = 0.25
        }
    }
    
    // MARK: - Image Loading
    
    private func loadDownscaledImage(from path: String) -> UIImage? {
        guard let originalImage = UIImage.loadFromAssetOrBundle(path) else { return nil }
        
        let maxDimension: CGFloat = 512
        let scale = min(maxDimension / originalImage.size.width, maxDimension / originalImage.size.height)
        
        if scale >= 1 { return originalImage } // Already small enough
        
        let newSize = CGSize(
            width: originalImage.size.width * scale,
            height: originalImage.size.height * scale
        )
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        originalImage.draw(in: CGRect(origin: .zero, size: newSize))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}
