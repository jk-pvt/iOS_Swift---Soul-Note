import Foundation

enum LetterState: String, Codable {
    case scheduled  // Future delivery date set
    case delivered  // Delivery date reached, awaiting unlock
    case opened     // User has experienced the unlock ritual
    case preserved  // Archived memory (default for old letters)
}

struct Letter: Identifiable, Codable, Equatable {
    let id: UUID
    var personId: UUID
    var content: String
    var deliveryDate: Date?
    var createdAt: Date
    var state: LetterState
    var openedAt: Date?  // When user opened the letter
    
    init(
        id: UUID = UUID(),
        personId: UUID,
        content: String,
        deliveryDate: Date? = nil,
        createdAt: Date = Date(),
        state: LetterState? = nil,
        openedAt: Date? = nil
    ) {
        self.id = id
        self.personId = personId
        self.content = content
        self.deliveryDate = deliveryDate
        self.createdAt = createdAt
        self.openedAt = openedAt
        
        if let state = state {
            self.state = state
        } else if let deliveryDate = deliveryDate {
            self.state = deliveryDate > Date() ? .scheduled : .preserved
        } else {
            self.state = .preserved
        }
    }
    
    // MARK: - Computed Properties
    
    var isReadyForDelivery: Bool {
        guard let deliveryDate = deliveryDate else { return false }
        return deliveryDate <= Date() && state == .scheduled
    }
    
    var currentState: LetterState {
        // If already opened or preserved, maintain that state
        if state == .opened || state == .preserved {
            return state
        }
        
        guard let deliveryDate = deliveryDate else {
            return .preserved
        }
        
        if deliveryDate > Date() {
            return .scheduled
        } else {
            return state == .scheduled ? .delivered : state
        }
    }
    
    var daysUntilDelivery: Int? {
        guard let deliveryDate = deliveryDate, state == .scheduled else { return nil }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: deliveryDate)
        return components.day
    }
    
    /// True if this letter contains handwritten (PencilKit) content
    var isHandwritten: Bool {
        content.hasPrefix("[HANDWRITTEN]")
    }
    
    /// Human-readable content for display — never shows raw base64 data
    var displayContent: String {
        isHandwritten ? "✍️ Handwritten letter" : content
    }
    
    var handwritingData: Data? {
        guard isHandwritten else { return nil }
        let base64 = String(content.dropFirst("[HANDWRITTEN]".count))
        return Data(base64Encoded: base64)
    }
    
    // MARK: - Codable (Backward Compatibility)
    
    enum CodingKeys: String, CodingKey {
        case id, personId, content, deliveryDate, createdAt, state, openedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        personId = try container.decode(UUID.self, forKey: .personId)
        content = try container.decode(String.self, forKey: .content)
        deliveryDate = try container.decodeIfPresent(Date.self, forKey: .deliveryDate)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        openedAt = try container.decodeIfPresent(Date.self, forKey: .openedAt)
        
        // Default to preserved for old letters without state
        state = try container.decodeIfPresent(LetterState.self, forKey: .state) ?? .preserved
    }
}
