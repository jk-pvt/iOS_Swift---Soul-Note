import SwiftUI

struct ArchivalMemoryCard: View {
    let person: Person
    let index: Int
    let action: () -> Void
    
    @State private var isPressing = false
    
    // Organic rotation based on index to create "tossed" look
    private var randomRotation: Double {
        let rotations: [Double] = [-1.5, 0.8, -0.4, 1.2, -1.0, 0.5, -0.8, 1.0]
        return rotations[index % rotations.count]
    }
    
    var body: some View {
        Button(action: {
            HapticService.shared.light()
            action()
        }) {
            VStack(spacing: 0) {
                // Polaroid Frame (Top margin: 20, Side: 20, Bottom: 60)
                ZStack(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(DesignTokens.polaroidFrame)
                        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                    
                    VStack(spacing: 0) {
                        Group {
                            if let photoPath = person.photoPath,
                               let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 240, height: 240)
                                    .clipped()
                                    .overlay(
                                        RadialGradient(
                                            colors: [.clear, .black.opacity(0.15)],
                                            center: .center,
                                            startRadius: 80,
                                            endRadius: 180
                                        )
                                    )
                                    .saturation(0.9) // Slight desaturation for vintage feel
                                    .contrast(1.1)   // Slight boost for depth
                            } else {
                                ZStack {
                                    Rectangle()
                                        .fill(DesignTokens.archiveBackground.opacity(0.1))
                                    
                                    Text(String(person.name.prefix(1)))
                                        .font(.system(size: 60, weight: .light, design: .serif))
                                        .foregroundColor(DesignTokens.archiveBrown.opacity(0.2))
                                }
                                .frame(width: 240, height: 240)
                            }
                        }
                        .padding(20) // Polaroid borders
                        .padding(.top, 4)
                        
                        VStack(alignment: .center, spacing: 2) {
                            Text(person.name)
                                .font(DesignTokens.handLabeled())
                                .foregroundColor(DesignTokens.archiveBrown.opacity(0.85))
                            
                            Text(person.relationship)
                                .font(DesignTokens.metadata())
                                .foregroundColor(DesignTokens.archiveBrown.opacity(0.5))
                                .italic()
                        }
                        .padding(.bottom, 24)
                    }
                    
                    TapeCornerView(angle: Double((index % 3) * 10 - 5))
                        .offset(x: 8, y: -8)
                    
                    DateStampView(date: Date())
                        .offset(x: -28, y: 250)
                }
                .frame(width: 280, height: 350)
            }
            .background(
                RoundedRectangle(cornerRadius: 2)
                    .fill(DesignTokens.polaroidFrame)
                    .shadow(
                        color: Color.black.opacity(isPressing ? 0.3 : 0.18),
                        radius: isPressing ? 25 : 12,
                        y: isPressing ? 15 : 6
                    )
            )
            .rotationEffect(.degrees(randomRotation))
            .scaleEffect(isPressing ? 0.96 : 1.0)
            .animation(DesignTokens.gentleSpring, value: isPressing)
        }
        .buttonStyle(CardButtonStyle(isPressing: $isPressing))
    }
}

struct CardButtonStyle: ButtonStyle {
    @Binding var isPressing: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                isPressing = newValue
            }
    }
}

struct TapeCornerView: View {
    let angle: Double
    
    var body: some View {
        Rectangle()
            .fill(DesignTokens.tapeColor)
            .frame(width: 45, height: 18)
            .rotationEffect(.degrees(45 + angle))
            .shadow(color: Color.black.opacity(0.08), radius: 1, y: 1)
            .blur(radius: 0.5)
    }
}

struct DateStampView: View {
    let date: Date
    
    var body: some View {
        Text(dateFormatter.string(from: date))
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(DesignTokens.archiveBrown.opacity(0.35))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .overlay(
                RoundedRectangle(cornerRadius: 1)
                    .stroke(DesignTokens.archiveBrown.opacity(0.2), lineWidth: 0.5)
            )
            .rotationEffect(.degrees(-2))
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd.yy"
        return formatter
    }
}
