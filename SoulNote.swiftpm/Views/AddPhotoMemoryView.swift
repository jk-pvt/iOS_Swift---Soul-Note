import SwiftUI

/// Simple sheet to add a photo-only memory — no audio required.
/// The user picks a photo from their library, writes an optional caption,
/// and picks an emotion tag. Saved as a Memory with photoPath set and audioPath nil.
struct AddPhotoMemoryView: View {
    let person: Person
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: MockDataService

    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var caption = ""
    @State private var selectedEmotion: EmotionTag = .love

    var canSave: Bool {
        selectedImage != nil && !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {

                    Button(action: { showingImagePicker = true }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(DesignTokens.ivoryPaper)
                                .frame(height: 260)
                                .shadow(color: .black.opacity(0.08), radius: 10, y: 4)

                            if let image = selectedImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 260)
                                    .clipShape(RoundedRectangle(cornerRadius: 20))
                            } else {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo.badge.plus")
                                        .font(.system(size: 48, weight: .light))
                                        .foregroundColor(DesignTokens.amberGlow)
                                    Text("Tap to add a photo")
                                        .font(DesignTokens.bodyText())
                                        .foregroundColor(DesignTokens.archiveBrown.opacity(0.6))
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Caption")
                            .font(DesignTokens.metadata())
                            .foregroundColor(DesignTokens.archiveBrown.opacity(0.7))
                            .padding(.horizontal)

                        TextField("e.g. Her 70th birthday, November 1998", text: $caption, axis: .vertical)
                            .font(DesignTokens.bodyText())
                            .foregroundColor(DesignTokens.inkColor)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(DesignTokens.ivoryPaper)
                                    .shadow(color: .black.opacity(0.06), radius: 6, y: 3)
                            )
                            .lineLimit(3...6)
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Emotion")
                            .font(DesignTokens.metadata())
                            .foregroundColor(DesignTokens.archiveBrown.opacity(0.7))
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(EmotionTag.allCases, id: \.self) { tag in
                                    EmotionChip(tag: tag, isSelected: selectedEmotion == tag) {
                                        HapticService.shared.light()
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedEmotion = tag
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 40)
                }
                .padding(.top, 12)
            }
            .background(DesignTokens.memoryPaper.ignoresSafeArea())
            .navigationTitle("Add Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(DesignTokens.nostalgiaAccent)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveMemory() }
                        .fontWeight(.semibold)
                        .foregroundColor(canSave ? DesignTokens.amberGlow : .gray)
                        .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }

    private func saveMemory() {
        guard let image = selectedImage,
              let data = image.jpegData(compressionQuality: 0.8) else { return }

        let photoPath = FileManager.generatePhotoPath()
        try? data.write(to: URL(fileURLWithPath: photoPath))

        let memory = Memory(
            personId: person.id,
            title: caption.trimmingCharacters(in: .whitespacesAndNewlines),
            audioPath: nil,
            photoPath: photoPath,
            emotionTag: selectedEmotion
        )
        storage.addMemory(memory)
        HapticService.shared.success()
        dismiss()
    }
}

private struct EmotionChip: View {
    let tag: EmotionTag
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(tag.icon)
                    .font(.system(size: 16))
                Text(tag.rawValue)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? DesignTokens.archiveBackground : DesignTokens.archiveBrown)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? DesignTokens.amberGlow : DesignTokens.ivoryPaper)
                    .shadow(color: .black.opacity(0.07), radius: 4, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
