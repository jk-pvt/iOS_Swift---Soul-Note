import RealityKit
import UIKit
import simd

/// Orchestrates the 4-stage memory formation animation sequence
class MemoryMaterializationController {
    
    private var bloomEntity: Entity?
    private var particleSystem: AtmosphericParticleSystem?
    private var emotionParticleSystem: EmotionParticleSystem?
    private var frameEntity: ModelEntity?
    
    func materialize(
        image: UIImage,
        emotionTag: EmotionTag?,
        at anchor: AnchorEntity,
        arView: ARView,
        onVoiceReady: @escaping () -> Void
    ) {
        // Stage 1: Light Bloom (0.0–1.0s)
        createLightBloom(at: anchor)
        
        // Stage 2: Particle Drift (0.8–1.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.startParticleDrift(at: anchor)
        }
        
        // Stage 3: Frame Fade-In (1.2–2.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.fadeInFrame(image: image, at: anchor)
        }
        
        // Stage 4: Voice Playback (2.2s + 0.6s delay)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            HapticService.shared.light()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                onVoiceReady()
            }
        }
        
        // Stage 5: Emotion Particles (voice + dynamic 0.6-0.8s delay)
        let emotionDelay = 2.8 + Double.random(in: 0.6...0.8) // Dynamic delay
        DispatchQueue.main.asyncAfter(deadline: .now() + emotionDelay) { [weak self] in
            self?.startEmotionParticles(emotionTag: emotionTag, at: anchor)
        }
    }
    
    private func createLightBloom(at anchor: AnchorEntity) {
        let bloom = Entity()
        
        var light = PointLightComponent()
        light.color = .init(red: 0.85, green: 0.65, blue: 0.45, alpha: 1.0)
        light.intensity = 200
        light.attenuationRadius = 0.8
        
        bloom.components.set(light)
        bloom.position = simd_float3(0, 0.01, 0) // Slightly above surface
        
        anchor.addChild(bloom)
        self.bloomEntity = bloom
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.fadeOutBloom(duration: 0.5)
        }
    }
    
    private func fadeOutBloom(duration: TimeInterval) {
        guard let bloom = bloomEntity else { return }
        
        var light = bloom.components[PointLightComponent.self]
        
        let steps = 10
        let stepDuration = duration / Double(steps)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                light?.intensity = 200 * Float(steps - i - 1) / Float(steps)
                if let updatedLight = light {
                    bloom.components.set(updatedLight)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.bloomEntity?.removeFromParent()
            self?.bloomEntity = nil
        }
    }
    
    private func startParticleDrift(at anchor: AnchorEntity) {
        let particleSystem = AtmosphericParticleSystem()
        let particles = particleSystem.createParticles(for: anchor)
        
        particles.position = simd_float3(0, 0.2, 0) // Center at frame height
        anchor.addChild(particles)
        
        self.particleSystem = particleSystem
    }
    
    private func fadeInFrame(image: UIImage, at anchor: AnchorEntity) {
        guard let frame = ArchivalFrameEntity.createFrame(with: image) else { return }
        
        frame.position = simd_float3(0, 0.2, 0)
        
        anchor.addChild(frame)
        self.frameEntity = frame
        
        let portalDust = particleSystem?.createPortalDust(
            width: 0.35, 
            height: 0.35 * 1.25, 
            depth: DesignTokens.portalDepth
        )
        if let dust = portalDust {
            frame.addChild(dust)
        }
        
        ArchivalFrameEntity.animateMaterialization(
            entity: frame,
            duration: 1.0,
            delay: 0.0
        )
    }
    
    func getParticleSystem() -> AtmosphericParticleSystem? {
        return particleSystem
    }
    
    func getFrameEntity() -> ModelEntity? {
        return frameEntity
    }
    
    private func startEmotionParticles(emotionTag: EmotionTag?, at anchor: AnchorEntity) {
        let emotionSystem = EmotionParticleSystem()
        
        if let particles = emotionSystem.createParticles(for: emotionTag, anchor: anchor) {
            particles.position = simd_float3(0, 0.2, 0) // Same height as frame
            anchor.addChild(particles)
            self.emotionParticleSystem = emotionSystem
        }
    }
    
    func executeExitTransition(
        audioController: SpatialAudioController?,
        completion: @escaping () -> Void
    ) {
        let _ = DesignTokens.exitTransitionDuration
        var completionCount = 0
        let totalComponents = 3
        
        let checkCompletion = {
            completionCount += 1
            if completionCount >= totalComponents {
                completion()
            }
        }
        
        // 0. Emotion Particles Fade First (0.0–0.6s) - emotional closure
        emotionParticleSystem?.fadeOut(duration: 0.6) {
        }
        
        audioController?.fadeOutAndStop(duration: 0.8) {
            checkCompletion()
        }
        
        // 2. Particle Dissolve (0.2–1.2s) - dust lingers after emotion
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.particleSystem?.dissolveParticles(duration: 1.0) {
                checkCompletion()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let frame = self?.frameEntity else {
                checkCompletion()
                return
            }
            
            ArchivalFrameEntity.animateDissolution(entity: frame, duration: 1.0) {
                checkCompletion()
            }
        }
    }
}
