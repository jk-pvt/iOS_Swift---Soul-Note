import RealityKit
import UIKit

class EmotionParticleSystem {
    
    private var particleEntities: [Entity] = []
    private let particleCount = 10 // 25% of total (vs 30 dust = 75%)
    
    func createParticles(for emotionTag: EmotionTag?, anchor: AnchorEntity) -> Entity? {
        // Fallback: if no emotion tag, return nil (dust only)
        guard let emotionTag = emotionTag else { return nil }
        
        let particles = Entity()
        
        guard let emojiTexture = EmojiTextureGenerator.shared.getTexture(for: emotionTag) else {
            return nil
        }
        
        guard let textureResource = try? TextureResource.generate(
            from: emojiTexture,
            options: .init(semantic: .color)
        ) else {
            return nil
        }
        
        for i in 0..<particleCount {
            let particle = createEmojiParticle(
                texture: textureResource,
                index: i
            )
            particles.addChild(particle)
            particleEntities.append(particle)
        }
        
        return particles
    }
    
    private func createEmojiParticle(texture: TextureResource, index: Int) -> Entity {
        let particle = Entity()
        
        let mesh = MeshResource.generatePlane(width: 0.008, depth: 0.008) // 8mm
        
        var material = UnlitMaterial()
        material.color = .init(texture: .init(texture))
        material.blending = .transparent(opacity: .init(floatLiteral: 0.10)) // Start at 0.10
        
        let modelEntity = ModelEntity(mesh: mesh, materials: [material])
        particle.addChild(modelEntity)
        
        // Position in orbital ring (0.5–1.2m radius, outside dust sphere)
        let radius = Float.random(in: 0.5...1.2)
        let theta = Float(index) * (2 * .pi / Float(particleCount)) // Evenly distributed
        let phi = Float.random(in: 0...(2 * .pi))
        
        let x = radius * cos(theta)
        let y = Float.random(in: -0.1...0.3) // Slight vertical variation
        let z = radius * sin(theta)
        
        particle.position = simd_float3(x, y, z)
        
        particle.scale = simd_float3(0.01, 0.01, 0.01)
        
        animateParticle(particle, index: index)
        
        return particle
    }
    
    private func animateParticle(_ particle: Entity, index: Int) {
        let duration: TimeInterval = Double.random(in: 10.0...15.0)
        let delay: TimeInterval = Double(index) * 0.15 // Stagger animations
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.fadeInParticle(particle, duration: 1.0)
            
            self.rotateParticle(particle, duration: duration)
            
            self.orbitParticle(particle, duration: duration)
        }
    }
    
    private func fadeInParticle(_ particle: Entity, duration: TimeInterval) {
        let steps = 20
        let stepDuration = duration / Double(steps)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Float(i) / Float(steps)
                let scale = 0.01 + (1.0 - 0.01) * progress
                particle.scale = simd_float3(scale, scale, scale)
            }
        }
    }
    
    private func rotateParticle(_ particle: Entity, duration: TimeInterval) {
        let steps = 60
        let stepDuration = duration / Double(steps)
        let rotationSpeed: Float = 0.1 // 0.1 rad/s
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let angle = rotationSpeed * Float(i) * Float(stepDuration)
                particle.orientation = simd_quatf(angle: angle, axis: simd_float3(0, 1, 0))
                
                if i == steps - 1 {
                    self.rotateParticle(particle, duration: duration)
                }
            }
        }
    }
    
    private func orbitParticle(_ particle: Entity, duration: TimeInterval) {
        let steps = 60
        let stepDuration = duration / Double(steps)
        let startPos = particle.position
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Float(i) / Float(steps)
                let angle = progress * 2 * .pi
                
                let radius = simd_length(simd_float2(startPos.x, startPos.z))
                let newX = radius * cos(angle)
                let newZ = radius * sin(angle)
                let newY = startPos.y + sin(progress * .pi) * 0.05 // Gentle wave
                
                particle.position = simd_float3(newX, newY, newZ)
                
                if i == steps - 1 {
                    self.orbitParticle(particle, duration: duration)
                }
            }
        }
    }
    
    /// Update particle opacity based on audio amplitude (subtle glow)
    func updateAudioLevel(_ amplitude: Float) {
        let targetOpacity = 0.08 + (amplitude * 0.04) // 0.08 → 0.12 max
        
        for particle in particleEntities {
            if let modelEntity = particle.children.first as? ModelEntity {
                var material = modelEntity.model?.materials.first as? UnlitMaterial
                material?.blending = .transparent(opacity: .init(floatLiteral: Float(targetOpacity)))
                if let updatedMaterial = material {
                    modelEntity.model?.materials = [updatedMaterial]
                }
            }
        }
    }
    
    func fadeOut(duration: TimeInterval, completion: (() -> Void)? = nil) {
        for particle in particleEntities {
            let steps = 20
            let stepDuration = duration / Double(steps)
            
            for i in 0..<steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                    let progress = Float(steps - i) / Float(steps)
                    particle.scale = simd_float3(progress, progress, progress)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion?()
        }
    }
}
