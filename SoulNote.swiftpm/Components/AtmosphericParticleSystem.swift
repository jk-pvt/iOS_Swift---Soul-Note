import RealityKit
import SwiftUI

/// iOS 16-compatible implementation using simple sphere entities
class AtmosphericParticleSystem {
    private var particleEntity: Entity?
    private var particleEntities: [Entity] = []
    private var birthRate: Float = 4.0
    
    func createParticles(for anchor: AnchorEntity) -> Entity {
        let particles = Entity()
        
        createSimpleParticles(parent: particles)
        
        let auraEntity = createLightAura()
        particles.addChild(auraEntity)
        
        self.particleEntity = particles
        
        return particles
    }
    
    func createPortalDust(width: Float, height: Float, depth: Float) -> Entity {
        let dustRoot = Entity()
        let count = 15
        
        for _ in 0..<count {
            let particle = Entity()
            let mesh = MeshResource.generateSphere(radius: 0.002)
            var material = UnlitMaterial()
            material.color = .init(tint: UIColor.white.withAlphaComponent(0.15))
            
            let model = ModelEntity(mesh: mesh, materials: [material])
            particle.addChild(model)
            
            particle.position = [
                Float.random(in: -width/2...width/2),
                Float.random(in: -height/2...height/2),
                Float.random(in: -depth...0)
            ]
            
            dustRoot.addChild(particle)
        }
        
        return dustRoot
    }
    
    private func createSimpleParticles(parent: Entity) {
        let particleCount = 30 // Static particle count for performance
        
        for i in 0..<particleCount {
            let particle = Entity()
            
            let mesh = MeshResource.generateSphere(radius: 0.003) // 3mm particles
            
            var material = UnlitMaterial()
            let hue = Float.random(in: 0.05...0.15) // Warm amber/sepia range
            material.color = .init(
                tint: UIColor(
                    hue: CGFloat(hue),
                    saturation: 0.3,
                    brightness: 0.9,
                    alpha: 0.25
                )
            )
            
            let modelEntity = ModelEntity(mesh: mesh, materials: [material])
            particle.addChild(modelEntity)
            
            let radius = Float.random(in: 0.1...0.4)
            let theta = Float.random(in: 0...(2 * .pi))
            let phi = Float.random(in: 0...(2 * .pi))
            
            let x = radius * sin(phi) * cos(theta)
            let y = radius * sin(phi) * sin(theta)
            let z = radius * cos(phi)
            
            particle.position = simd_float3(x, y, z)
            
            parent.addChild(particle)
            particleEntities.append(particle)
            
            animateParticle(particle, index: i)
        }
    }
    
    private func animateParticle(_ particle: Entity, index: Int) {
        let duration: TimeInterval = Double.random(in: 8.0...12.0)
        let delay: TimeInterval = Double(index) * 0.1 // Stagger animations
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            let startY = particle.position.y
            let endY = startY + Float.random(in: 0.05...0.15) // Drift 5-15cm upward
            
            self.animateDrift(particle: particle, startY: startY, endY: endY, duration: duration)
        }
    }
    
    private func animateDrift(particle: Entity, startY: Float, endY: Float, duration: TimeInterval) {
        let steps = 60
        let stepDuration = duration / Double(steps)
        
        for i in 0..<steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + stepDuration * Double(i)) {
                let progress = Float(i) / Float(steps)
                let newY = startY + (endY - startY) * progress
                
                var pos = particle.position
                pos.y = newY
                particle.position = pos
                
                if i == steps - 1 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.animateDrift(particle: particle, startY: endY, endY: startY, duration: duration)
                    }
                }
            }
        }
    }
    
    private func createLightAura() -> Entity {
        let aura = Entity()
        
        var light = PointLightComponent()
        light.color = .init(
            red: 0.85,
            green: 0.65,
            blue: 0.45,
            alpha: 1.0
        )
        light.intensity = 100
        light.attenuationRadius = 0.5 // 0.5m radius
        
        aura.components.set(light)
        
        return aura
    }
    
    /// Update particle density based on proximity (simplified for iOS 16)
    func updateProximityDensity(distance: Float) {
        let targetAlpha: Float
        if distance < 1.0 {
            targetAlpha = 0.35 // Dense
        } else if distance < 2.5 {
            targetAlpha = 0.25 // Normal
        } else {
            targetAlpha = 0.15 // Sparse
        }
        
        for particle in particleEntities {
            if let modelEntity = particle.children.first as? ModelEntity {
                var material = modelEntity.model?.materials.first as? UnlitMaterial
                if let currentColor = material?.color.tint {
                    material?.color = .init(tint: currentColor.withAlphaComponent(CGFloat(targetAlpha)))
                    if let updatedMaterial = material {
                        modelEntity.model?.materials = [updatedMaterial]
                    }
                }
            }
        }
    }
    
    func updateAuraIntensity(distance: Float, duration: TimeInterval = 1.0) {
        guard let auraEntity = particleEntity?.children.first else { return }
        
        let intensity: Float
        if distance < 1.0 {
            intensity = 150 // Close - brightest
        } else if distance < 2.5 {
            intensity = 100 // Medium
        } else {
            intensity = 50 // Far - dimmest
        }
        
        var light = auraEntity.components[PointLightComponent.self]
        light?.intensity = intensity
        
        if let updatedLight = light {
            auraEntity.components.set(updatedLight)
        }
    }
    
    func dissolveParticles(duration: TimeInterval = 1.2, completion: (() -> Void)? = nil) {
        for particle in particleEntities {
            if let modelEntity = particle.children.first as? ModelEntity {
                var material = modelEntity.model?.materials.first as? UnlitMaterial
                material?.color = .init(tint: .clear)
                if let updatedMaterial = material {
                    modelEntity.model?.materials = [updatedMaterial]
                }
            }
        }
        
        if let auraEntity = particleEntity?.children.first {
            var light = auraEntity.components[PointLightComponent.self]
            light?.intensity = 0
            if let updatedLight = light {
                auraEntity.components.set(updatedLight)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            completion?()
        }
    }
}
