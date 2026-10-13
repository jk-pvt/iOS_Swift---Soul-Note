import Foundation

class StorageService: ObservableObject {
    static let shared = StorageService()
    
    @Published var people: [Person] = []
    @Published var memories: [Memory] = []
    @Published var letters: [Letter] = []
    
    private let peopleURL: URL
    private let memoriesURL: URL
    private let lettersURL: URL
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        peopleURL = documentsPath.appendingPathComponent("people.json")
        memoriesURL = documentsPath.appendingPathComponent("memories.json")
        lettersURL = documentsPath.appendingPathComponent("letters.json")
        
        loadData()
    }
    
    // MARK: - Computed Properties
    
    var allMemories: [Memory] {
        return memories
    }
    
    // MARK: - Load Data
    
    private func loadData() {
        people = load(from: peopleURL) ?? []
        memories = load(from: memoriesURL) ?? []
        letters = load(from: lettersURL) ?? []
    }
    
    private func load<T: Decodable>(from url: URL) -> T? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Save Data
    
    private func save<T: Encodable>(_ items: T, to url: URL) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: url)
    }
    
    // MARK: - Person CRUD
    
    func addPerson(_ person: Person) {
        people.append(person)
        save(people, to: peopleURL)
    }
    
    func updatePerson(_ person: Person) {
        if let index = people.firstIndex(where: { $0.id == person.id }) {
            people[index] = person
            save(people, to: peopleURL)
        }
    }
    
    func deletePerson(_ person: Person) {
        people.removeAll { $0.id == person.id }
        memories.removeAll { $0.personId == person.id }
        letters.removeAll { $0.personId == person.id }
        save(people, to: peopleURL)
        save(memories, to: memoriesURL)
        save(letters, to: lettersURL)
    }
    
    // MARK: - Memory CRUD
    
    func addMemory(_ memory: Memory) {
        memories.append(memory)
        save(memories, to: memoriesURL)
    }
    
    func updateMemory(_ memory: Memory) {
        if let index = memories.firstIndex(where: { $0.id == memory.id }) {
            memories[index] = memory
            save(memories, to: memoriesURL)
        }
    }
    
    func deleteMemory(_ memory: Memory) {
        memories.removeAll { $0.id == memory.id }
        save(memories, to: memoriesURL)
    }
    
    // MARK: - Letter CRUD
    
    func addLetter(_ letter: Letter) {
        letters.append(letter)
        save(letters, to: lettersURL)
        
        // Schedule notification if delivery date is set and in future
        if letter.deliveryDate != nil && letter.state == .scheduled {
            LetterNotificationService.shared.scheduleDeliveryNotification(for: letter)
        }
    }
    
    func updateLetter(_ letter: Letter) {
        if let index = letters.firstIndex(where: { $0.id == letter.id }) {
            letters[index] = letter
            save(letters, to: lettersURL)
            
            LetterNotificationService.shared.cancelNotification(for: letter.id)
            if letter.deliveryDate != nil && letter.state == .scheduled {
                LetterNotificationService.shared.scheduleDeliveryNotification(for: letter)
            }
        }
    }
    
    func deleteLetter(_ letter: Letter) {
        LetterNotificationService.shared.cancelNotification(for: letter.id)
        
        letters.removeAll { $0.id == letter.id }
        save(letters, to: lettersURL)
    }
    
    // MARK: - Helpers
    
    func memories(for person: Person) -> [Memory] {
        memories.filter { $0.personId == person.id }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func letters(for person: Person) -> [Letter] {
        letters.filter { $0.personId == person.id }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Letter Delivery
    
    func updateLetterState(_ letterId: UUID, to newState: LetterState, openedAt: Date? = nil) {
        if let index = letters.firstIndex(where: { $0.id == letterId }) {
            letters[index].state = newState
            if let openedAt = openedAt {
                letters[index].openedAt = openedAt
            }
            save(letters, to: lettersURL)
        }
    }
    
    func lettersReadyForDelivery() -> [Letter] {
        return letters.filter { $0.isReadyForDelivery }
    }
    
    func unopenedDeliveredLetters(for person: Person) -> [Letter] {
        return letters.filter { 
            $0.personId == person.id && 
            ($0.currentState == .delivered || $0.isReadyForDelivery)
        }
    }
}

