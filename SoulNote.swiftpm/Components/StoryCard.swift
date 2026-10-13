import SwiftUI

struct StoryCard: View {
    let person: Person
    let rotation: Double
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                if let photoPath = person.photoPath,
                   let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(DesignTokens.memoryPaper.opacity(0.3))
                        .frame(width: 140, height: 140)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(DesignTokens.archiveBrown.opacity(0.3))
                        )
                }
                
                Text(person.name)
                    .font(DesignTokens.nameDisplay())
                    .foregroundColor(DesignTokens.archiveBrown)
                    .lineLimit(1)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(DesignTokens.memoryPaper)
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            )
            .rotationEffect(.degrees(rotation))
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
        .accessibilityLabel(AccessibilityHelpers.voiceOverLabel(for: person))
        .accessibilityHint(AccessibilityHelpers.voiceOverHint(for: "view memories"))
    }
}
