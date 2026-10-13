import SwiftUI

/// Designed for emotional, meaningful actions (not productivity CTAs)
struct CeremonialButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            HapticService.shared.light()
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .light))
                Text(title)
                    .font(.system(size: 17, weight: .medium, design: .default))
            }
            .foregroundColor(DesignTokens.archiveBackground)
            .padding(.horizontal, 36)
            .frame(height: 56)
            .frame(minWidth: 220, maxWidth: 340)
            .background(
                Capsule()
                    .fill(DesignTokens.amberGradient)
                    .overlay(
                        Capsule()
                            .stroke(Color.black.opacity(0.10), lineWidth: 1)
                            .blur(radius: 2)
                            .offset(y: 1)
                            .mask(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.black, Color.clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                    )
            )
            .shadow(color: DesignTokens.amberGlow.opacity(0.45), radius: 20, x: 0, y: 0)
            .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 5)
            .scaleEffect(isPressed ? 0.97 : 1.0)
        }
        .buttonStyle(.plain)
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
        }
        .accessibilityLabel("\(title) - Begin your memory preservation journey")
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

#Preview {
    ZStack {
        DesignTokens.introGradient
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            CeremonialButton(title: "Begin Preserving", icon: "heart") {
                print("Button tapped")
            }
            .padding(.bottom, 60)
        }
    }
}
