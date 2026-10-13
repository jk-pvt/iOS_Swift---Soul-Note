import SwiftUI

struct PaperGrainView: View {
    let opacity: Double
    
    var body: some View {
        Canvas { context, size in
            for _ in 0..<2000 {
                let x = CGFloat.random(in: 0...size.width)
                let y = CGFloat.random(in: 0...size.height)
                let brightness = CGFloat.random(in: 0.3...0.7)
                
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: 1, height: 1)),
                    with: .color(.white.opacity(brightness * opacity))
                )
            }
        }
        .allowsHitTesting(false)
    }
}
