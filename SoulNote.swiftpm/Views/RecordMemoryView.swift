import SwiftUI

struct RecordMemoryView: View {
    let person: Person
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: MockDataService
    @EnvironmentObject var audioService: AudioService
    
    @State private var title = ""
    @State private var selectedEmotion: EmotionTag = .happy
    @State private var audioPath: String?
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    
    private let memoryPrompts = [
        "Tell a story about your childhood together",
        "Share a lesson they taught you",
        "Describe a moment that made you laugh",
        "What do you want to remember most?",
        "Capture the sound of their voice saying your name",
        "Share a tradition you want to preserve",
        "Describe how they made you feel safe"
    ]
    
    private var memoryPrompt: String {
        memoryPrompts[Int(Date().timeIntervalSince1970 / 10) % memoryPrompts.count]
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.08, green: 0.08, blue: 0.08)
                    .ignoresSafeArea()
                
                if audioPath == nil {
                    recordingView
                } else {
                    saveFormView
                }
            }
            .navigationTitle("Record Memory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if audioService.isRecording {
                            audioService.stopRecording()
                        }
                        dismiss()
                    }
                }
                
                if audioPath != nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") { saveMemory() }
                            .disabled(title.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    // MARK: - Recording View
    
    private var recordingView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VoiceOrbView(
                isRecording: audioService.isRecording,
                audioLevel: CGFloat(audioService.currentAmplitude)
            )
            .frame(height: 300)
            
            if audioService.isRecording {
                Text(formatDuration(audioService.recordingDuration))
                    .font(.system(size: 36, weight: .light, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 20)
            } else {
                VStack(spacing: 12) {
                    Text(memoryPrompt)
                        .font(DesignTokens.bodyText())
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("Tap to begin")
                        .font(DesignTokens.metadata())
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            
            Spacer()
            
            Button(action: toggleRecording) {
                Text(audioService.isRecording ? "Stop Recording" : "Start Recording")
                    .font(DesignTokens.bodyText())
                    .fontWeight(.semibold)
                    .foregroundColor(audioService.isRecording ? .white : Color(red: 0.08, green: 0.08, blue: 0.08))
                    .frame(maxWidth: .infinity)
                    .frame(height: DesignTokens.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(audioService.isRecording ? Color.red.opacity(0.8) : DesignTokens.amberGlow)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Save Form View
    
    private var saveFormView: some View {
        ScrollView {
            VStack(spacing: 24) {
                successIndicator
                formCard
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private var successIndicator: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(DesignTokens.amberGlow)
            
            Text("Memory Captured")
                .font(DesignTokens.heroTitle())
                .foregroundColor(.white)
            
            Text("Now preserve the details")
                .font(DesignTokens.metadata())
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.top, 32)
        .padding(.bottom, 16)
    }
    
    private var formCard: some View {
        VStack(spacing: 20) {
            titleInput
            emotionSelector
            photoAttachment
        }
        .padding(24)
        .background(formCardBackground)
        .shadow(color: DesignTokens.amberGlow.opacity(0.1), radius: 20, y: 10)
    }
    
    private var formCardBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.08),
                        Color.white.opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                DesignTokens.amberGlow.opacity(0.3),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    private var titleInput: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Memory Title")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignTokens.amberGlow)
                .textCase(.uppercase)
                .tracking(1)
            
            TextField("Give this memory a name", text: $title)
                .font(DesignTokens.bodyText())
                .foregroundColor(.white)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(DesignTokens.amberGlow.opacity(0.2), lineWidth: 1)
                        )
                )
        }
    }
    
    private var emotionSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Emotion")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignTokens.amberGlow)
                .textCase(.uppercase)
                .tracking(1)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(EmotionTag.allCases, id: \.self) { emotion in
                        emotionButton(for: emotion)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private func emotionButton(for emotion: EmotionTag) -> some View {
        Button(action: { 
            HapticService.shared.selection()
            selectedEmotion = emotion 
        }) {
            HStack(spacing: 6) {
                Text(emotion.icon)
                    .font(.system(size: 16))
                Text(emotion.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(selectedEmotion == emotion ? 
                          AnyShapeStyle(DesignTokens.amberGradient) : 
                          AnyShapeStyle(Color.white.opacity(0.08)))
            )
            .overlay(
                Capsule()
                    .stroke(selectedEmotion == emotion ? 
                           DesignTokens.amberGlow.opacity(0.5) : 
                           Color.white.opacity(0.15), lineWidth: 1)
            )
            .foregroundColor(selectedEmotion == emotion ? .white : .white.opacity(0.7))
        }
    }
    
    private var photoAttachment: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Photo (Optional)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(DesignTokens.amberGlow)
                .textCase(.uppercase)
                .tracking(1)
            
            Button(action: { 
                HapticService.shared.light()
                showingImagePicker = true 
            }) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(selectedImage != nil ? DesignTokens.amberGlow.opacity(0.2) : Color.white.opacity(0.08))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: selectedImage != nil ? "photo.fill" : "photo")
                            .font(.system(size: 20))
                            .foregroundColor(selectedImage != nil ? DesignTokens.amberGlow : .white.opacity(0.5))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedImage != nil ? "Photo Attached" : "Add a Photo")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(selectedImage != nil ? "Tap to change" : "Enhance this memory with an image")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedImage != nil ? DesignTokens.amberGlow.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private func toggleRecording() {
        if audioService.isRecording {
            HapticService.shared.light()
            audioService.stopRecording()
            audioPath = audioService.lastRecordingPath
        } else {
            HapticService.shared.medium()
            audioService.startRecording()
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func saveMemory() {
        var photoPath: String?
        
        if let image = selectedImage,
           let data = image.jpegData(compressionQuality: 0.7) {
            let path = FileManager.generatePhotoPath()
            try? data.write(to: URL(fileURLWithPath: path))
            photoPath = path
        }
        
        let memory = Memory(
            personId: person.id,
            title: title,
            audioPath: audioPath,
            photoPath: photoPath,
            emotionTag: selectedEmotion
        )
        
        HapticService.shared.success()
        SoundService.shared.playWhoosh()
        
        storage.addMemory(memory)
        dismiss()
    }
}
