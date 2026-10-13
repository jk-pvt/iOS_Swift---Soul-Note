import simd

/// Adjusts audio and particles based on user distance from the memory anchor
class ProximityInteractionSystem {
    private var anchorPosition: simd_float3 = .zero
    private var audioController: SpatialAudioController?
    private var particleSystem: AtmosphericParticleSystem?
    
    func setup(
        anchorPosition: simd_float3,
        audioController: SpatialAudioController,
        particleSystem: AtmosphericParticleSystem
    ) {
        self.anchorPosition = anchorPosition
        self.audioController = audioController
        self.particleSystem = particleSystem
    }
    
    func update(cameraPosition: simd_float3) {
        let distance = simd_distance(cameraPosition, anchorPosition)
        let normalizedDistance = min(max(distance / 2.0, 0), 1)
        let _ = 1.0 - normalizedDistance
    }
}
