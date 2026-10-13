import SwiftUI

struct AccessibilityHelpers {
    static func voiceOverLabel(for person: Person) -> String {
        "\(person.name), \(person.relationship)"
    }
    
    static func voiceOverLabel(for memory: Memory) -> String {
        "\(memory.title), \(memory.emotionTag.rawValue) memory, \(memory.createdAt.relativeString())"
    }
    
    static func voiceOverHint(for action: String) -> String {
        "Double tap to \(action)"
    }
}
