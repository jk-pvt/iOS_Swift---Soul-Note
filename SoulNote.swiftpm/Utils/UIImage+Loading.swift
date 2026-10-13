import UIKit

/// Extension to help load images from either asset catalog or bundle resources
extension UIImage {
    /// - Parameter nameOrPath: Either an asset catalog name (e.g., "elara_portrait") or a file path
    static func loadFromAssetOrBundle(_ nameOrPath: String) -> UIImage? {
        print("🔍 Attempting to load image: \(nameOrPath)")
        
        if let image = UIImage(named: nameOrPath) {
            print("✅ Loaded image '\(nameOrPath)' from asset catalog")
            return image
        }
        
        if let bundlePath = Bundle.module.path(forResource: nameOrPath, ofType: "png"),
           let image = UIImage(contentsOfFile: bundlePath) {
            print("✅ Loaded image '\(nameOrPath).png' from bundle root")
            return image
        }
        
        if let bundlePath = Bundle.module.path(forResource: nameOrPath, ofType: "jpg"),
           let image = UIImage(contentsOfFile: bundlePath) {
            print("✅ Loaded image '\(nameOrPath).jpg' from bundle root")
            return image
        }
        
        if let bundlePath = Bundle.module.path(forResource: nameOrPath, ofType: "png", inDirectory: "Resources"),
           let image = UIImage(contentsOfFile: bundlePath) {
            print("✅ Loaded image '\(nameOrPath).png' from Resources/")
            return image
        }
        
        if let bundlePath = Bundle.module.path(forResource: nameOrPath, ofType: "jpg", inDirectory: "Resources"),
           let image = UIImage(contentsOfFile: bundlePath) {
            print("✅ Loaded image '\(nameOrPath).jpg' from Resources/")
            return image
        }
        
        if FileManager.default.fileExists(atPath: nameOrPath),
           let image = UIImage(contentsOfFile: nameOrPath) {
            print("✅ Loaded image from file path: \(nameOrPath)")
            return image
        }
        
        print("⚠️ Could not load image: \(nameOrPath)")
        return nil
    }
}
