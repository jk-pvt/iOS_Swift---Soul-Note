import SwiftUI
#if canImport(ARKit)
import RealityKit
import ARKit
#endif

struct ARMemoryView: View {
    let memory: Memory
    let personName: String
    @Environment(\.dismiss) private var dismiss
    @State private var showEntryView = true
    @State private var showInstructions = true
    
    var body: some View {
        ZStack {
            if showEntryView {
                ARMemoryEntryView(
                    memory: memory,
                    personName: personName,
                    onEnterAR: {
                        showEntryView = false
                    }
                )
            } else {
                #if canImport(ARKit)
                if ARWorldTrackingConfiguration.isSupported {
                    ARViewContainer(
                        memory: memory,
                        showInstructions: $showInstructions
                    )
                    .ignoresSafeArea()
                } else {
                    unavailableView
                }
                #else
                unavailableView
                #endif
                
                if showInstructions {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                            
                            Text("Tap to place memory")
                                .font(DesignTokens.bodyText())
                                .foregroundColor(.white)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.6))
                        )
                        .padding(.bottom, 100)
                    }
                    .transition(.opacity)
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            HapticService.shared.light()
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.white)
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                    Spacer()
                }
            }
        }
        .statusBar(hidden: true) // Hide status bar for immersion
    }
    
    private var unavailableView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "arkit")
                    .font(.system(size: 80))
                    .foregroundColor(.white.opacity(0.5))
                
                Text("AR Not Available")
                    .font(DesignTokens.nameDisplay())
                    .foregroundColor(.white)
                
                Text("AR features require a physical device with ARKit support")
                    .font(DesignTokens.bodyText())
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

#if canImport(ARKit)
struct ARViewContainer: UIViewRepresentable {
    let memory: Memory
    @Binding var showInstructions: Bool
    
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // Setup AR configuration with environmental lighting
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic // Enable light estimation
        arView.session.run(config)
        
        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = true
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        arView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: arView.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: arView.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: arView.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: arView.heightAnchor)
        ])
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateProximity()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(memory: memory, showInstructions: $showInstructions)
    }
    
    class Coordinator: NSObject {
        let memory: Memory
        @Binding var showInstructions: Bool
        var arView: ARView?
        
        var materializationController: MemoryMaterializationController?
        var audioController: SpatialAudioController?
        var proximitySystem: ProximityInteractionSystem?
        var memoryAnchor: AnchorEntity?
        
        init(memory: Memory, showInstructions: Binding<Bool>) {
            self.memory = memory
            self._showInstructions = showInstructions
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            
            guard materializationController == nil else { return }
            
            withAnimation {
                showInstructions = false
            }
            
            let tapLocation = recognizer.location(in: arView)
            
            guard let raycastResult = arView.raycast(
                from: tapLocation,
                allowing: .estimatedPlane,
                alignment: .any
            ).first else { return }
            
            HapticService.shared.medium()
            
            let anchor = AnchorEntity(world: raycastResult.worldTransform)
            arView.scene.addAnchor(anchor)
            self.memoryAnchor = anchor
            
            let anchorPosition = simd_float3(
                raycastResult.worldTransform.columns.3.x,
                raycastResult.worldTransform.columns.3.y,
                raycastResult.worldTransform.columns.3.z
            )
            
            if let audioPath = memory.audioPath {
                let audioController = SpatialAudioController()
                audioController.loadAudio(from: audioPath)
                self.audioController = audioController
            }
            
            if let photoPath = memory.photoPath,
               let uiImage = UIImage.loadFromAssetOrBundle(photoPath) {
                
                let controller = MemoryMaterializationController()
                self.materializationController = controller
                
                controller.materialize(
                    image: uiImage,
                    emotionTag: memory.emotionTag,
                    at: anchor,
                    arView: arView
                ) { [weak self] in
                    self?.startSpatialAudio(at: anchorPosition)
                    self?.setupProximitySystem(anchorPosition: anchorPosition)
                }
            }
        }
        
        private func startSpatialAudio(at position: simd_float3) {
            audioController?.play(at: position, fadeIn: true)
        }
        
        private func setupProximitySystem(anchorPosition: simd_float3) {
            guard let audioController = audioController,
                  let particleSystem = materializationController?.getParticleSystem() else {
                return
            }
            
            let proximitySystem = ProximityInteractionSystem()
            proximitySystem.setup(
                anchorPosition: anchorPosition,
                audioController: audioController,
                particleSystem: particleSystem
            )
            self.proximitySystem = proximitySystem
        }
        
        func updateProximity() {
            guard let arView = arView,
                  let proximitySystem = proximitySystem else { return }
            
            let cameraTransform = arView.cameraTransform
            let cameraPosition = simd_float3(
                cameraTransform.translation.x,
                cameraTransform.translation.y,
                cameraTransform.translation.z
            )
            
            audioController?.updateListenerPosition(cameraPosition)
            
            proximitySystem.update(cameraPosition: cameraPosition)
        }
        
        deinit {
            if let controller = materializationController,
               let audioController = audioController {
                controller.executeExitTransition(audioController: audioController) {
                }
            } else {
                audioController?.stop()
            }
        }
    }
}
#endif
