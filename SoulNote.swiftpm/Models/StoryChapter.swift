import Foundation

/// Adapter model that combines Memory and Letter data into playback chapters
/// Non-destructive bridge between existing models and storybook feature
struct StoryChapter: Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let photoPath: String?
    let audioPath: String?
    let letterText: String?
    let emotionTag: EmotionTag?
    let chapterType: ChapterType
    
    var duration: TimeInterval {
        switch chapterType {
        case .voiceMemory:
            // Duration determined by audio length (handled by audio manager)
            return 0 // Placeholder, actual duration from audio file
        case .letter:
            let wordCount = letterText?.split(separator: " ").count ?? 0
            let readingTime = Double(wordCount) / 3.0 // ~3 words per second
            return min(max(readingTime, 5.0), 7.0) // Clamp between 5-7 seconds
        case .mixed:
            return 0 // Handled dynamically
        }
    }
}

enum ChapterType {
    case voiceMemory    // Memory with audio (may have photo)
    case letter         // Letter content only
    case mixed          // Memory with both audio and letter-like content
}

extension StoryChapter {
    static func from(memory: Memory) -> StoryChapter {
        StoryChapter(
            id: memory.id,
            title: memory.title,
            date: memory.createdAt,
            photoPath: memory.photoPath,
            audioPath: memory.audioPath,
            letterText: nil,
            emotionTag: memory.emotionTag,
            chapterType: .voiceMemory
        )
    }
    
    static func from(letter: Letter) -> StoryChapter {
        StoryChapter(
            id: letter.id,
            title: "Letter",
            date: letter.createdAt,
            photoPath: nil,
            audioPath: nil,
            letterText: letter.content,
            emotionTag: nil,
            chapterType: .letter
        )
    }
}
