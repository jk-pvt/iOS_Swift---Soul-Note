import SwiftUI

struct StorybookPlayerView: View {
    let person: Person
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storage: MockDataService
    @StateObject private var audioManager = StorybookAudioManager()
    
    @State private var chapters: [StoryChapter] = []
    @State private var currentChapterIndex = 0
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var showContent = false
    @State private var controlsTimer: Timer?
    
    private var currentChapter: StoryChapter? {
        guard currentChapterIndex < chapters.count else { return nil }
        return chapters[currentChapterIndex]
    }
    
    var body: some View {
        ZStack {
            Color(red: 0.18, green: 0.16, blue: 0.15)
                .ignoresSafeArea()
            
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.3)
                ],
                center: .center,
                startRadius: 200,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            PaperGrainView(opacity: 0.15)
                .ignoresSafeArea()
                .allowsHitTesting(false)
            
            if let chapter = currentChapter {
                VStack {
                    Spacer()
                    
                    StorybookPhotoCard(
                        photoPath: chapter.photoPath,
                        isVisible: showContent
                    )
                    
                    Spacer()
                }
                .overlay(
                    StorybookTextOverlay(
                        title: chapter.title,
                        date: chapter.date,
                        letterText: chapter.letterText,
                        isVisible: showContent
                    )
                )
            } else {
                emptyStateView
            }
            
            if showControls && !chapters.isEmpty {
                VStack {
                    Spacer()
                    controlBar
                        .padding(.bottom, 40)
                }
                .transition(.opacity)
            }
        }
        .statusBar(hidden: true)
        .onAppear {
            loadChapters()
            startPlayback()
        }
        .onDisappear {
            audioManager.stop()
        }
        .onTapGesture {
            toggleControls()
        }
        .gesture(
            DragGesture(minimumDistance: 50)
                .onEnded { value in
                    HapticService.shared.light()
                    
                    if value.translation.width < -50 {
                        // Swipe left: next chapter with page curl
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showContent = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            nextChapter()
                        }
                    } else if value.translation.width > 50 {
                        // Swipe right: previous chapter with page curl
                        withAnimation(.easeInOut(duration: 0.5)) {
                            showContent = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            previousChapter()
                        }
                    }
                }
        )
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 80))
                .foregroundColor(DesignTokens.amberGlow.opacity(0.5))
            
            Text("No memories to play")
                .font(DesignTokens.heroTitle())
                .foregroundColor(.white.opacity(0.7))
            
            Text("Record memories or write letters to create a storybook")
                .font(DesignTokens.bodyText())
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: { exitStorybook() }) {
                Text("Close")
                    .font(DesignTokens.bodyText())
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(DesignTokens.amberGlow)
                    )
            }
            .padding(.top, 16)
        }
    }
    
    // MARK: - Control Bar
    
    private var controlBar: some View {
        HStack(spacing: 32) {
            Button(action: previousChapter) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(currentChapterIndex > 0 ? 0.9 : 0.3))
            }
            .disabled(currentChapterIndex == 0)
            
            Button(action: togglePlayback) {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Button(action: nextChapter) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(currentChapterIndex < chapters.count - 1 ? 0.9 : 0.3))
            }
            .disabled(currentChapterIndex >= chapters.count - 1)
            
            Spacer()
            
            Button(action: exitStorybook) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 20)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
                .blur(radius: 20)
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Playback Logic
    
    private func loadChapters() {
        var allChapters: [StoryChapter] = []
        
        let memories = storage.memories(for: person)
        allChapters += memories.map { StoryChapter.from(memory: $0) }
        
        let letters = storage.letters(for: person)
        allChapters += letters.map { StoryChapter.from(letter: $0) }
        
        chapters = allChapters.sorted { $0.date < $1.date }
    }
    
    private func startPlayback() {
        guard !chapters.isEmpty else { return }
        isPlaying = true
        playCurrentChapter()
    }
    
    private func playCurrentChapter() {
        guard let chapter = currentChapter else { return }
        
        showContent = false
        
        // Stage 1: Photo fades in (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showContent = true
            }
        }
        
        // Stage 2: Micro silence before voice (0.4s) - reflective pause
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if isPlaying {
                playChapterAudio(chapter)
            }
        }
    }
    
    private func playChapterAudio(_ chapter: StoryChapter) {
        if let audioPath = chapter.audioPath {
            // Voice memory: play audio, then proceed
            audioManager.playChapterAudio(at: audioPath) {
                self.proceedToNextChapter()
            }
        } else {
            // Letter or photo-only: use dynamic duration
            let duration = chapter.chapterType == .letter ? chapter.duration : 4.0
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                self.proceedToNextChapter()
            }
        }
    }
    
    private func proceedToNextChapter() {
        guard isPlaying else { return }
        
        withAnimation(.easeInOut(duration: 0.5)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if self.currentChapterIndex < self.chapters.count - 1 {
                self.currentChapterIndex += 1
                self.playCurrentChapter()
            } else {
                self.isPlaying = false
            }
        }
    }
    
    private func togglePlayback() {
        isPlaying.toggle()
        
        if isPlaying {
            playCurrentChapter()
        } else {
            audioManager.stop()
        }
    }
    
    private func nextChapter() {
        guard currentChapterIndex < chapters.count - 1 else { return }
        
        audioManager.stop()
        showContent = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentChapterIndex += 1
            if self.isPlaying {
                self.playCurrentChapter()
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.showContent = true
                }
            }
        }
    }
    
    private func previousChapter() {
        guard currentChapterIndex > 0 else { return }
        
        audioManager.stop()
        showContent = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentChapterIndex -= 1
            if self.isPlaying {
                self.playCurrentChapter()
            } else {
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.showContent = true
                }
            }
        }
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        
        if showControls {
            controlsTimer?.invalidate()
            controlsTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.showControls = false
                }
            }
        } else {
            controlsTimer?.invalidate()
        }
    }
    
    private func exitStorybook() {
        audioManager.stop()
        
        withAnimation(.easeInOut(duration: 0.5)) {
            showContent = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            dismiss()
        }
    }
}
