import Foundation

/// Provides pre-seeded grandmother-grandson narrative with read-only data
class MockDataService: ObservableObject {
    static let shared = MockDataService()
    
    // MARK: - Published Properties (matching StorageService API)
    
    @Published var people: [Person] = [] { didSet { saveToPersistence() } }
    @Published var memories: [Memory] = [] { didSet { saveToPersistence() } }
    @Published var letters: [Letter] = [] { didSet { saveToPersistence() } }
    
    private var isLoading = false
    private let peopleKey = "soul_note_people_v1"
    private let memoriesKey = "soul_note_memories_v1"
    private let lettersKey = "soul_note_letters_v1"
    
    // MARK: - Initialization
    
    private init() {
        print("🚀 MockDataService: Initializing...")
        isLoading = true
        _ = loadFromPersistence()
        seedDemoData() // Safe to call: only adds missing pieces
        isLoading = false
        saveToPersistence() // Final save after init/seed
        print("✅ MockDataService: Initialization complete")
        print("📊 MockDataService: Loaded \(people.count) people, \(memories.count) memories, \(letters.count) letters")
    }
    
    // MARK: - Computed Properties
    
    var allMemories: [Memory] {
        return memories
    }
    
    // MARK: - Constants
    
    /// The fixed ID for the demo grandmother (Elara) to ensure consistency
    private let demoPersonId = UUID(uuidString: "E1A7A71E-0000-4000-8000-000000000000")!
    
    // MARK: - Demo Data Seeding
    
    private func seedDemoData() {
        print("🌱 MockDataService: Checking for demo data...")
        
        if !people.contains(where: { $0.id == demoPersonId }) {
            let elara = Person(
                id: demoPersonId,
                name: "Elara",
                photoPath: "elara_portrait",
                relationship: "Grandmother"
            )
            people.insert(elara, at: 0) // Always keep her first
            print("👵 MockDataService: Restored demo person - Elara")
        }
        
        let elaraMemories = memories.filter { $0.personId == demoPersonId }
        if elaraMemories.isEmpty {
            let now = Date()
            
            let memory1 = Memory(
                id: UUID(),
                personId: demoPersonId,
                title: "The Old Oak Tree",
                audioPath: "memory_oak",
                photoPath: "memory_oak",
                emotionTag: .childhood,
                createdAt: Calendar.current.date(byAdding: .day, value: -3, to: now)!
            )
            
            let memory2 = Memory(
                id: UUID(),
                personId: demoPersonId,
                title: "How I Met Your Grandfather",
                audioPath: "memory_love",
                photoPath: "memory_dance",
                emotionTag: .love,
                createdAt: Calendar.current.date(byAdding: .day, value: -7, to: now)!
            )
            
            let memory3 = Memory(
                id: UUID(),
                personId: demoPersonId,
                title: "My Secret Recipe",
                audioPath: "recipe",
                photoPath: "memory_recipe",
                emotionTag: .wisdom,
                createdAt: Calendar.current.date(byAdding: .day, value: -14, to: now)!
            )
            
            memories.append(contentsOf: [memory1, memory2, memory3])
            print("🧠 MockDataService: Restored demo memories")
        }
        
        let elaraLetters = letters.filter { $0.personId == demoPersonId }
        if elaraLetters.isEmpty {
            let now = Date()
            let letter = Letter(
                id: UUID(),
                personId: demoPersonId,
                content: """
My dearest,

When the world feels heavy and the path unclear, remember this: you carry within you the strength of generations. The same hands that built treehouses and kneaded dough are the hands that will build your future.

Life is not about avoiding the storms—it's about learning to dance in the rain. Every challenge you face is a chapter in your story, and every scar is proof that you survived.

I may not always be there to guide you, but my love will remain in every sunset you watch, every recipe you cook, and every memory you hold dear.

You are never truly lost, my child. You are exactly where you need to be.

With all my love,
Grandma Elara
""",
                deliveryDate: Calendar.current.date(byAdding: .day, value: -1, to: now),
                createdAt: Calendar.current.date(byAdding: .day, value: -30, to: now)!,
                state: .delivered,
                openedAt: nil
            )
            letters.append(letter)
            print("✉️ MockDataService: Restored demo letter")
        }
    }
    
    // MARK: - Persistence
    
    private func saveToPersistence() {
        guard !isLoading else { return }
        let encoder = JSONEncoder()
        
        if let encodedPeople = try? encoder.encode(people) {
            UserDefaults.standard.set(encodedPeople, forKey: peopleKey)
        }
        
        if let encodedMemories = try? encoder.encode(memories) {
            UserDefaults.standard.set(encodedMemories, forKey: memoriesKey)
        }
        
        if let encodedLetters = try? encoder.encode(letters) {
            UserDefaults.standard.set(encodedLetters, forKey: lettersKey)
        }
        print("💾 MockDataService: Saved data to persistence")
    }
    
    private func loadFromPersistence() -> Bool {
        let decoder = JSONDecoder()
        
        guard let peopleData = UserDefaults.standard.data(forKey: peopleKey),
              let loadedPeople = try? decoder.decode([Person].self, from: peopleData),
              !loadedPeople.isEmpty else {
            return false
        }
        
        people = loadedPeople
        
        if let memoriesData = UserDefaults.standard.data(forKey: memoriesKey),
           let loadedMemories = try? decoder.decode([Memory].self, from: memoriesData) {
            memories = loadedMemories
        }
        
        if let lettersData = UserDefaults.standard.data(forKey: lettersKey),
           let loadedLetters = try? decoder.decode([Letter].self, from: lettersData) {
            letters = loadedLetters
        }
        
        print("📖 MockDataService: Loaded data from persistence")
        return true
    }
    
    // MARK: - Person CRUD (Read-Only - No-Ops)
    
    func addPerson(_ person: Person) {
        people.append(person)
        print("👤 MockDataService: Added person - \(person.name)")
    }
    
    func updatePerson(_ person: Person) {
        print("⚠️ MockDataService: updatePerson is disabled in demo mode")
    }
    
    func deletePerson(_ person: Person) {
        guard person.id != demoPersonId else {
            print("🛡️ MockDataService: Delete ignored - Elara is an exceptional demo profile.")
            return
        }
        
        let personLetters = letters(for: person)
        for letter in personLetters {
            LetterNotificationService.shared.cancelNotification(for: letter.id)
        }
        
        memories.removeAll { $0.personId == person.id }
        
        letters.removeAll { $0.personId == person.id }
        
        people.removeAll { $0.id == person.id }
        
        print("👤 MockDataService: Deleted person and all associated data - \(person.name)")
    }
    
    // MARK: - Memory CRUD (Read-Only - No-Ops)
    
    func addMemory(_ memory: Memory) {
        memories.append(memory)
        print("🧠 MockDataService: Added memory - \(memory.title)")
    }
    
    func updateMemory(_ memory: Memory) {
        print("⚠️ MockDataService: updateMemory is disabled in demo mode")
    }
    
    func deleteMemory(_ memory: Memory) {
        memories.removeAll { $0.id == memory.id }
        print("🧠 MockDataService: Deleted memory - \(memory.title)")
    }
    
    // MARK: - Letter CRUD (Read-Only - No-Ops)
    
    func addLetter(_ letter: Letter) {
        letters.append(letter)
        
        LetterNotificationService.shared.scheduleDeliveryNotification(for: letter)
        
        print("✉️ MockDataService: Added letter and scheduled notification")
    }
    
    func updateLetter(_ letter: Letter) {
        print("⚠️ MockDataService: updateLetter is disabled in demo mode")
    }
    
    func deleteLetter(_ letter: Letter) {
        LetterNotificationService.shared.cancelNotification(for: letter.id)
        
        letters.removeAll { $0.id == letter.id }
        print("✉️ MockDataService: Deleted letter and cancelled notification")
    }
    
    // MARK: - Helper Methods (Matching StorageService API)
    
    func memories(for person: Person) -> [Memory] {
        return memories.filter { $0.personId == person.id }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func letters(for person: Person) -> [Letter] {
        return letters.filter { $0.personId == person.id }.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Letter Delivery
    
    func updateLetterState(_ letterId: UUID, to newState: LetterState, openedAt: Date? = nil) {
        if let index = letters.firstIndex(where: { $0.id == letterId }) {
            letters[index].state = newState
            if let openedAt = openedAt {
                letters[index].openedAt = openedAt
            }
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
