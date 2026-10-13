import UIKit
import CoreImage

/// Pre-generates and caches all emotion textures for performance
class EmojiTextureGenerator {
    
    static let shared = EmojiTextureGenerator()
    
    private var textureCache: [EmotionTag: CGImage] = [:]
    private let textureSize = CGSize(width: 32, height: 32)
    
    private init() {
        // Pre-generate all emotion textures at initialization
        preGenerateTextures()
    }
    
    private func emoji(for emotion: EmotionTag) -> String {
        switch emotion {
        case .happy:
            return "😊"
        case .advice:
            return "💡"
        case .childhood:
            return "🌟"
        case .wisdom:
            return "🕊️"
        case .funny:
            return "✨" // Refined: Light joy instead of playful 😄
        case .love:
            return "❤️"
        }
    }
    
    private func preGenerateTextures() {
        for emotion in EmotionTag.allCases {
            if let texture = generateTexture(for: emotion) {
                textureCache[emotion] = texture
            }
        }
    }
    
    func getTexture(for emotion: EmotionTag) -> CGImage? {
        return textureCache[emotion]
    }
    
    private func generateTexture(for emotion: EmotionTag) -> CGImage? {
        let emojiString = emoji(for: emotion)
        
        let renderer = UIGraphicsImageRenderer(size: textureSize)
        
        let image = renderer.image { context in
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24),
                .foregroundColor: UIColor.white
            ]
            
            let attributedString = NSAttributedString(string: emojiString, attributes: attributes)
            let stringSize = attributedString.size()
            
            let x = (textureSize.width - stringSize.width) / 2
            let y = (textureSize.height - stringSize.height) / 2
            
            attributedString.draw(at: CGPoint(x: x, y: y))
        }
        
        guard let ciImage = CIImage(image: image) else { return nil }
        
        let sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(ciImage, forKey: kCIInputImageKey)
        sepiaFilter?.setValue(0.8, forKey: kCIInputIntensityKey) // 80% sepia
        
        guard let sepiaOutput = sepiaFilter?.outputImage else { return nil }
        
        let saturationFilter = CIFilter(name: "CIColorControls")
        saturationFilter?.setValue(sepiaOutput, forKey: kCIInputImageKey)
        saturationFilter?.setValue(0.2, forKey: kCIInputSaturationKey) // 20% saturation
        
        guard let finalOutput = saturationFilter?.outputImage else { return nil }
        
        let context = CIContext()
        return context.createCGImage(finalOutput, from: finalOutput.extent)
    }
}
