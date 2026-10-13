import SwiftUI

/// The immersive "Story Mode" full-screen interview experience.
/// Voice-first: the app speaks a question, listens, and shows live transcription.
struct InterviewView: View {

    @StateObject private var viewModel = StoryModeViewModel()
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            StoryOrbView(
                isListening: viewModel.state == .listeningToAnswer,
                audioLevel: viewModel.audioLevel
            )
            .scaleEffect(viewModel.state == .listeningToAnswer ? 1.15 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.state)
            .allowsHitTesting(false)

            VStack(spacing: 0) {

                HStack {
                    Button(action: {
                        viewModel.stopSession()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white.opacity(0.55))
                            .padding(20)
                    }
                    Spacer()
                }

                Spacer()

                if viewModel.isManualEntryEnabled {
                    manualEntryTextField
                } else if !viewModel.transcription.isEmpty {
                    transcriptionOverlay
                }

                Text(viewModel.currentQuestion)
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, (viewModel.transcription.isEmpty && !viewModel.isManualEntryEnabled) ? 0 : 20)
                    .scaleEffect(viewModel.state == .askingQuestion ? 1.04 : 1.0)
                    .animation(.spring(response: 0.4), value: viewModel.state)
                    .id(viewModel.currentQuestion)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))

                Text(statusLabel)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.top, 16)
                    .animation(.easeInOut, value: viewModel.state)

                Spacer()

                HStack(spacing: 48) {
                    Button(action: { viewModel.skipQuestion() }) {
                        VStack(spacing: 6) {
                            Image(systemName: "forward.end.fill")
                                .font(.title2)
                            Text("Skip")
                                .font(.caption2)
                        }
                        .foregroundColor(.white.opacity(0.4))
                    }

                    mainActionButton
                    
                    fallbackToggleButton

                }
                .padding(.bottom, 52)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.transcription.isEmpty)
        .onAppear { viewModel.startInterview() }
        .onDisappear { viewModel.stopSession() }
        .alert("Permissions Required", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Sub-views
    
    private var transcriptionOverlay: some View {
        Text(viewModel.transcription)
            .font(.body)
            .foregroundColor(.white.opacity(0.75))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 36)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.08))
            )
            .padding(.horizontal, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private var manualEntryTextField: some View {
        TextEditor(text: $viewModel.transcription)
            .scrollContentBackground(.hidden)
            .font(.body)
            .foregroundColor(.white)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .frame(height: 120)
            .padding(.horizontal, 24)
            .transition(.scale.combined(with: .opacity))
    }
    
    private var fallbackToggleButton: some View {
        Button(action: { viewModel.toggleManualEntry() }) {
            VStack(spacing: 6) {
                Image(systemName: viewModel.isManualEntryEnabled ? "mic.fill" : "keyboard.fill")
                    .font(.title2)
                Text(viewModel.isManualEntryEnabled ? "Use Voice" : "Type instead")
                    .font(.caption2)
            }
            .foregroundColor(.white.opacity(0.4))
        }
        .disabled(!viewModel.isSpeechAvailable && viewModel.isManualEntryEnabled)
    }

    @ViewBuilder
    private var mainActionButton: some View {
        switch viewModel.state {
        case .idle:
            // Shouldn't normally be visible but provide a fallback
            Button(action: { viewModel.startInterview() }) {
                micButtonLabel(icon: "mic.fill", label: nil, active: false)
            }

        case .askingQuestion:
            micButtonLabel(icon: "speaker.wave.2.fill", label: nil, active: true)
                .opacity(0.6)

        case .listeningToAnswer:
            Button(action: { viewModel.toggleListening() }) {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 16)
                    .background(
                        Capsule().fill(Color(red: 1.0, green: 0.78, blue: 0.35))
                    )
            }

        case .processing:
            ProgressView()
                .tint(.white)
                .scaleEffect(1.3)

        case .completed:
            Button(action: { viewModel.toggleListening() }) {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                    Text("Next Question")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
    }

    private func micButtonLabel(icon: String, label: String?, active: Bool) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(active ? Color(red: 1.0, green: 0.78, blue: 0.35).opacity(0.15) : Color.white.opacity(0.08))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(active ? Color(red: 1.0, green: 0.78, blue: 0.35) : .white.opacity(0.8))
            }
            if let label {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
    }

    private var statusLabel: String {
        switch viewModel.state {
        case .idle:            return "Preparing..."
        case .askingQuestion:  return "Listen to the question..."
        case .listeningToAnswer: return "Speak your answer. Tap Done when finished."
        case .processing:      return "Saving your memory..."
        case .completed:       return "Memory captured ✦"
        }
    }
}

#Preview {
    InterviewView()
}
