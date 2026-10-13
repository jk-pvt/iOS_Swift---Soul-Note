import Foundation
import Combine
import SwiftUI

/// Manages the state and logic for the Voice-First "Story Mode" storytelling experience.
@MainActor
class StoryModeViewModel: ObservableObject {

    // MARK: - State
    enum InterviewState: Equatable {
        case idle
        case askingQuestion
        case listeningToAnswer
        case processing
        case completed
    }

    // MARK: - Published Properties
    @Published var state: InterviewState = .idle
    @Published var currentQuestion: String = ""
    @Published var transcription: String = ""
    @Published var audioLevel: Float = 0.0
    @Published var errorMessage: String?
    
    @Published var isSpeechAvailable: Bool = true
    @Published var isManualEntryEnabled: Bool = false

    // MARK: - Dependencies
    private let speechService = SpeechService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Data
    private let questions = [
        "What is your earliest memory of home?",
        "Tell me about a friend who changed your life.",
        "What was the happiest day of your life?",
        "If you could give one piece of advice to your grandchild, what would it be?",
        "What is a mistake you learned the most from?",
        "Describe a moment you felt truly at peace.",
        "What do you want your family to remember most about you?"
    ]

    private var questionIndex: Int = 0

    // MARK: - Init
    init() {
        // Directly subscribe using sink for better type inference and thread safety
        speechService.$transcription
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                self?.transcription = text
            }
            .store(in: &cancellables)

        speechService.$audioLevel
            .receive(on: RunLoop.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }
            .store(in: &cancellables)

        currentQuestion = questions.first ?? "Tell me a story."
    }

    // MARK: - Public Intents

    func startInterview() {
        isSpeechAvailable = speechService.checkAvailability()
        
        Task {
            let authorized = await speechService.requestAuthorization()
            guard authorized else {
                errorMessage = "Please enable microphone and speech recognition in Settings to use Story Mode."
                return
            }
            
            if !isSpeechAvailable {
                // Automatically switch to manual entry if speech is not supported
                isManualEntryEnabled = true
            }
            
            await askCurrentQuestion()
        }
    }

    func toggleManualEntry() {
        isManualEntryEnabled.toggle()
        if isManualEntryEnabled {
            speechService.stopListening()
            state = .listeningToAnswer
        } else if isSpeechAvailable {
            Task { await askCurrentQuestion() }
        }
    }

    func skipQuestion() {
        speechService.stopListening()
        advanceQuestion()
        transcription = "" // Clear manual input or transcription
        Task { await askCurrentQuestion() }
    }

    func stopSession() {
        speechService.stopListening()
        state = .idle
    }

    func toggleListening() {
        if state == .listeningToAnswer {
            finishAnswer()
        } else if state == .completed {
            advanceQuestion()
            transcription = "" // Clear manual input or transcription
            Task { await askCurrentQuestion() }
        }
    }

    // MARK: - Private Logic

    private func advanceQuestion() {
        questionIndex = (questionIndex + 1) % questions.count
        currentQuestion = questions[questionIndex]
    }

    private func askCurrentQuestion() async {
        state = .askingQuestion
        await speechService.speakAsync(currentQuestion)
        try? await Task.sleep(nanoseconds: 600_000_000)
        startListeningNow()
    }

    private func startListeningNow() {
        state = .listeningToAnswer
        do {
            try speechService.startListening()
        } catch {
            errorMessage = "Could not start microphone: \(error.localizedDescription)"
            state = .idle
        }
    }

    private func finishAnswer() {
        state = .processing
        speechService.stopListening()
        Task {
            // Simulate saving (replace with real persistence later)
            try? await Task.sleep(nanoseconds: 800_000_000)
            state = .completed
        }
    }
}
