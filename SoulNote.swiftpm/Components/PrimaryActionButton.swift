import SwiftUI

struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                Text(title)
                    .font(DesignTokens.bodyText())
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: DesignTokens.buttonCornerRadius)
                    .fill(DesignTokens.amberGradient)
                    .shadow(color: DesignTokens.amberGlow.opacity(0.35), radius: 15, y: 8)
            )
        }
        .buttonStyle(.plain)
    }
}
