import SwiftUI

struct StorybookPhotoCard: View {
    let photoPath: String?
    let isVisible: Bool
    
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Group {
            if let photoPath = photoPath,
               let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 320, height: 400)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(DesignTokens.amberGlow.opacity(0.2), lineWidth: 1)
                    )
                    .scaleEffect(scale)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(DesignTokens.ivoryPaper)
                    .frame(width: 320, height: 400)
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
                    .overlay(
                        Image(systemName: "envelope.open.fill")
                            .font(.system(size: 80))
                            .foregroundColor(DesignTokens.archiveBrown.opacity(0.3))
                    )
                    .scaleEffect(scale)
            }
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .onChange(of: isVisible) { newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 4.0)) {
                    scale = 1.03
                }
            } else {
                scale = 1.0
            }
        }
    }
}
