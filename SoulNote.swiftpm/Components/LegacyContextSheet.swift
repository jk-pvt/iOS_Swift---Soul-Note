import SwiftUI

struct LegacyContextSheet: View {
    let person: Person
    let onOpenMemories: () -> Void
    let onPlayStorybook: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @EnvironmentObject var storage: MockDataService
    
    private var memoryCount: Int {
        storage.memories(for: person).count
    }
    
    private var hasMemories: Bool {
        !storage.memories(for: person).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(DesignTokens.archiveBrown.opacity(0.3))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 24)
            
            VStack(spacing: 12) {
                if let photoPath = person.photoPath,
                   let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(DesignTokens.legacyNodeBorder, lineWidth: 3)
                        )
                        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
                } else {
                    ZStack {
                        Circle()
                            .fill(DesignTokens.archiveBrown.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundColor(DesignTokens.archiveBrown.opacity(0.3))
                    }
                    .overlay(
                        Circle()
                            .stroke(DesignTokens.legacyNodeBorder, lineWidth: 3)
                    )
                }
                
                Text(person.name)
                    .font(DesignTokens.nameDisplay())
                    .foregroundColor(DesignTokens.archiveBrown)
                
                Text(person.relationship)
                    .font(DesignTokens.metadata())
                    .foregroundColor(DesignTokens.archiveBrown.opacity(0.7))
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 14))
                    Text("\(memoryCount) \(memoryCount == 1 ? "memory" : "memories")")
                        .font(DesignTokens.metadata())
                }
                .foregroundColor(DesignTokens.nostalgiaAccent)
                .padding(.top, 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            VStack(spacing: 16) {
                Button(action: {
                    HapticService.shared.light()
                    dismiss()
                    onOpenMemories()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 20))
                        Text("Open Memories")
                            .font(DesignTokens.bodyText().weight(.semibold))
                    }
                    .foregroundColor(Color(red: 0.18, green: 0.16, blue: 0.15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(DesignTokens.ivoryPaper)
                            .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                    )
                }
                
                if hasMemories {
                    Button(action: {
                        HapticService.shared.light()
                        dismiss()
                        onPlayStorybook()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 20))
                            Text("Play Storybook")
                                .font(DesignTokens.bodyText().weight(.semibold))
                        }
                        .foregroundColor(Color(red: 0.18, green: 0.16, blue: 0.15))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(DesignTokens.ivoryPaper)
                                .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .background(DesignTokens.memoryPaper)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.3), radius: 20, y: -5)
    }
}
