import RealityKit
import UIKit

class ArchivalFrameEntity {
    
    static func createFrame(with image: UIImage, size: Float = 0.35) -> ModelEntity? {
        return createVolumetricPortal(with: image, size: size)
    }
    
    /// Creates a 3D "Memory Box" with recessed photo for parallax portal effect
    static func createVolumetricPortal(with image: UIImage, size: Float = 0.35) -> ModelEntity? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width: Float = size
        let height: Float = size * 1.25 // 4:5 ratio for a more "window" feel
        let depth = DesignTokens.portalDepth
        
        let root = ModelEntity()
        
        let photoMesh = MeshResource.generatePlane(width: width, height: height)
        var photoMaterial = SimpleMaterial()
        do {
            let texture = try TextureResource.generate(from: cgImage, options: .init(semantic: .color))
            photoMaterial.color = .init(tint: .white, texture: .init(texture))
            photoMaterial.roughness = .float(0.4)
            photoMaterial.metallic = .float(0.0)
        } catch {
            return nil
        }
        let photoEntity = ModelEntity(mesh: photoMesh, materials: [photoMaterial])
        photoEntity.position.z = -depth // Recess the photo
        root.addChild(photoEntity)
        
        addVolumetricFrame(to: root, width: width, height: height, depth: depth)
        
        // 4. Internal "Sleeve" Walls (To hide the gap between frame and recessed photo)
        addInternalWalls(to: root, width: width, height: height, depth: depth)
        
        addPortalLighting(to: root, depth: depth)
        
        return root
    }
    
    private static func addVolumetricFrame(to entity: Entity, width: Float, height: Float, depth: Float) {
        let frameThickness: Float = 0.04
        let frameMaterial = createWoodMaterial()
        
        let segments: [(w: Float, h: Float, d: Float, x: Float, y: Float)] = [
            (w: width + frameThickness, h: frameThickness, d: 0.03, x: 0, y: height/2 + frameThickness/2),
            (w: width + frameThickness, h: frameThickness, d: 0.03, x: 0, y: -(height/2 + frameThickness/2)),
            (w: frameThickness, h: height, d: 0.03, x: -(width/2 + frameThickness/2), y: 0),
            (w: frameThickness, h: height, d: 0.03, x: width/2 + frameThickness/2, y: 0)
        ]
        
        for s in segments {
            let mesh = MeshResource.generateBox(width: s.w, height: s.h, depth: s.d)
            let segment = ModelEntity(mesh: mesh, materials: [frameMaterial])
            segment.position = [s.x, s.y, -0.01] // Slightly back from true front
            entity.addChild(segment)
        }
    }
    
    private static func addInternalWalls(to entity: Entity, width: Float, height: Float, depth: Float) {
        var wallMaterial = SimpleMaterial()
        wallMaterial.color = .init(tint: UIColor(red: 0.15, green: 0.12, blue: 0.10, alpha: 1.0))
        wallMaterial.roughness = 0.9
        
        let walls: [(w: Float, h: Float, x: Float, y: Float, rx: Float, ry: Float)] = [
            (w: width, h: depth, x: 0, y: height/2, rx: .pi/2, ry: 0),
            (w: width, h: depth, x: 0, y: -height/2, rx: -.pi/2, ry: 0),
            (w: depth, h: height, x: -width/2, y: 0, rx: 0, ry: -.pi/2),
            (w: depth, h: height, x: width/2, y: 0, rx: 0, ry: .pi/2)
        ]
        
        for w in walls {
            let mesh = MeshResource.generatePlane(width: w.w, height: w.h)
            let wall = ModelEntity(mesh: mesh, materials: [wallMaterial])
            wall.position = [w.x, w.y, -depth/2]
            
            let qX = simd_quatf(angle: w.rx, axis: [1, 0, 0])
            let qY = simd_quatf(angle: w.ry, axis: [0, 1, 0])
            wall.orientation = qX * qY
            
            entity.addChild(wall)
        }
    }
    
    private static func addPortalLighting(to entity: Entity, depth: Float) {
        let light = PointLight()
        light.light.intensity = 150
        light.light.color = .init(red: 0.85, green: 0.65, blue: 0.45, alpha: 1.0)
        light.light.attenuationRadius = 0.4
        light.position = [0, 0, -depth/2]
        entity.addChild(light)
    }
    
    private static func createWoodMaterial() -> SimpleMaterial {
        var mat = SimpleMaterial()
        mat.color = .init(tint: UIColor(red: 0.35, green: 0.25, blue: 0.18, alpha: 1.0))
        mat.roughness = 0.8
        mat.metallic = 0.0
        return mat
    }
    
    private static func addFrameBorder(to entity: ModelEntity, width: Float, height: Float) {
        // Obsolete but kept for signature safety if needed elsewhere
    }
    
    static func animateMaterialization(
        entity: Entity,
        duration: TimeInterval = 1.0,
        delay: TimeInterval = 0.0,
        completion: (() -> Void)? = nil
    ) {
        entity.scale = simd_float3(0.8, 0.8, 0.8)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            var transform = entity.transform
            transform.scale = simd_float3(1.0, 1.0, 1.0)
            
            entity.move(
                to: transform,
                relativeTo: entity.parent,
                duration: duration,
                timingFunction: .easeInOut
            )
            
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                completion?()
            }
        }
    }
    
    static func animateDissolution(
        entity: Entity,
        duration: TimeInterval = 1.0,
        completion: (() -> Void)? = nil
    ) {
        var transform = entity.transform
        transform.scale = simd_float3(0.7, 0.7, 0.7)
        
        entity.move(
            to: transform,
            relativeTo: entity.parent,
            duration: duration,
            timingFunction: .easeInOut
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            entity.removeFromParent()
            completion?()
        }
    }
}
