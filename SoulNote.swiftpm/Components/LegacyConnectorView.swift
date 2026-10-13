import SwiftUI

struct LegacyConnectorView: View {
    let startPoint: CGPoint
    let endPoint: CGPoint
    
    @State private var pulseOpacity: Double = 0.2
    
    var body: some View {
        Path { path in
            let controlPoint = CGPoint(
                x: (startPoint.x + endPoint.x) / 2,
                y: (startPoint.y + endPoint.y) / 2 - 30 // Slight curve
            )
            
            path.move(to: startPoint)
            path.addQuadCurve(to: endPoint, control: controlPoint)
        }
        .stroke(
            DesignTokens.legacyConnector,
            style: StrokeStyle(lineWidth: 2, lineCap: .round)
        )
        .opacity(pulseOpacity)
        .shadow(color: DesignTokens.amberGlow.opacity(0.2), radius: 4)
        .onAppear {
            startPulseAnimation()
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(
            .easeInOut(duration: DesignTokens.connectorPulseDuration)
            .repeatForever(autoreverses: true)
        ) {
            pulseOpacity = 0.35
        }
    }
}
