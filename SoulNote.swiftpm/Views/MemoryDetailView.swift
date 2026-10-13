import SwiftUI

struct MemoryDetailView: View {
    let memory: Memory
    @EnvironmentObject var audioService: AudioService
    @EnvironmentObject var storage: MockDataService
    @State private var showingAR = false
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let photoPath = memory.photoPath,
                   let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 300)
                        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.cardCornerRadius))
                        .padding(.horizontal)
                        .shadow(color: Color.black.opacity(0.12), radius: 15, y: 10)
                }
                
                VStack(spacing: 12) {
                    Text(memory.title)
                        .font(DesignTokens.nameDisplay())
                        .foregroundColor(DesignTokens.archiveBrown)
                    
                    HStack {
                        Text(memory.emotionTag.rawValue)
                            .font(DesignTokens.metadata())
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(DesignTokens.nostalgiaAccent.opacity(0.2))
                            )
                            .foregroundColor(DesignTokens.nostalgiaAccent)
                        
                        Text(memory.createdAt.timelineString())
                            .font(DesignTokens.metadata())
                            .foregroundColor(DesignTokens.archiveBrown.opacity(0.7))
                    }
                }
                .padding(.horizontal)
                
                if let audioPath = memory.audioPath,
                   URL.audioExists(at: audioPath) {
                    AudioPlayer(audioPath: audioPath)
                        .padding(.horizontal)
                }
                
                if let photoPath = memory.photoPath,
                   UIImage.loadFromAssetOrBundle(photoPath) != nil {
                    PrimaryActionButton(title: "View in AR", icon: "arkit") {
                        showingAR = true
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 24)
        }
        .background(DesignTokens.memoryPaper)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            SoundService.shared.playChime()
        }
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .alert("Delete Memory?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteMemory()
            }
        } message: {
            Text("This will permanently delete \"\(memory.title)\". This action cannot be undone.")
        }
        .sheet(isPresented: $showingAR) {
            ARMemoryView(memory: memory, personName: personName)
        }
    }
    
    private var personName: String {
        storage.people.first(where: { $0.id == memory.personId })?.name ?? "Unknown"
    }
    
    private func deleteMemory() {
        storage.deleteMemory(memory)
        dismiss()
    }
}
