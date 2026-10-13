import Foundation

struct Person: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var photoPath: String?
    var relationship: String
    var memories: [UUID] = []
    var letters: [UUID] = []
    
    init(id: UUID = UUID(), name: String, photoPath: String? = nil, relationship: String) {
        self.id = id
        self.name = name
        self.photoPath = photoPath
        self.relationship = relationship
    }
}
