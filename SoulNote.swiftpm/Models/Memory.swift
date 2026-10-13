import Foundation

struct Memory: Identifiable, Codable, Equatable {
    let id: UUID
    var personId: UUID
    var title: String
    var audioPath: String?
    var photoPath: String?
    var emotionTag: EmotionTag
    var createdAt: Date
    
    init(id: UUID = UUID(), personId: UUID, title: String, audioPath: String? = nil, photoPath: String? = nil, emotionTag: EmotionTag, createdAt: Date = Date()) {
        self.id = id
        self.personId = personId
        self.title = title
        self.audioPath = audioPath
        self.photoPath = photoPath
        self.emotionTag = emotionTag
        self.createdAt = createdAt
    }
}

enum EmotionTag: String, Codable, CaseIterable {
    case happy = "Happy"
    case advice = "Advice"
    case childhood = "Childhood"
    case wisdom = "Wisdom"
    case funny = "Funny"
    case love = "Love"
    
    var icon: String {
        switch self {
        case .happy: return "😊"
        case .advice: return "💡"
        case .childhood: return "🎈"
        case .wisdom: return "📖"
        case .funny: return "😄"
        case .love: return "❤️"
        }
    }
}
