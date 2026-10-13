import SwiftUI

/// A mesmerizing, fluid orb animation that visualizes the "Story Mode" listening state.
struct StoryOrbView: View {
    
    // MARK: - Properties
    var isListening: Bool
    var audioLevel: Float
    
    // MARK: - Animation State
    @State private var time: TimeInterval = 0
    
    var body: some View {
        SwiftUI.TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let baseRadius = min(size.width, size.height) / 3
                
                context.blendMode = .plusLighter // Additive blending for "Glow"
                
                // Layer 1: Core (Amber)
                context.drawLayer { ctx in
                    let scale = 1.0 + (Double(audioLevel) * 0.2)
                    let wobble = sin(now * 1.5) * 10
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - baseRadius * scale + wobble,
                            y: center.y - baseRadius * scale,
                            width: baseRadius * 2 * scale,
                            height: baseRadius * 2 * scale
                        )),
                        with: .color(.orange.opacity(0.6))
                    )
                }
                
                // Layer 2: Outer Glow (Gold)
                context.drawLayer { ctx in
                    let scale = 1.1 + (Double(audioLevel) * 0.3)
                    let wobbleX = cos(now * 2.0) * 15
                    let wobbleY = sin(now * 1.2) * 15
                    
                    ctx.fill(
                        Path(ellipseIn: CGRect(
                            x: center.x - baseRadius * scale + wobbleX,
                            y: center.y - baseRadius * scale + wobbleY,
                            width: baseRadius * 2 * scale,
                            height: baseRadius * 2 * scale
                        )),
                        with: .color(.yellow.opacity(0.4))
                    )
                }
                 
                // Layer 3: Detail/Highlight (White/Yellow)
                if isListening {
                    context.drawLayer { ctx in
                        let scale = 0.8 + (Double(audioLevel) * 0.5) // Reacts more to sound
                        let wobble = sin(now * 3.0) * 5
                        ctx.fill(
                            Path(ellipseIn: CGRect(
                                x: center.x - baseRadius * scale,
                                y: center.y - baseRadius * scale + wobble,
                                width: baseRadius * 2 * scale,
                                height: baseRadius * 2 * scale
                            )),
                            with: .color(.white.opacity(0.3))
                        )
                    }
                }
                
            }
        }
        .frame(width: 300, height: 300)
        .blur(radius: 30) // High blur creates the "Liquid" look
        .animation(.easeInOut(duration: 0.2), value: audioLevel)
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        StoryOrbView(isListening: true, audioLevel: 0.5)
    }
}
