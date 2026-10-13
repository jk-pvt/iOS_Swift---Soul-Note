import Foundation
import AVFoundation

extension URL {
    /// - Parameter nameOrPath: Either a resource name (e.g., "memory_oak") or a file path
    static func audioFromBundleOrPath(_ nameOrPath: String) -> URL? {
        print("🔍 Attempting to load audio: \(nameOrPath)")
        print("📦 Bundle path: \(Bundle.module.bundlePath)")
        
        if let resourcePath = Bundle.module.resourcePath {
            do {
                let contents = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("📂 Bundle contents (first 15): \(contents.prefix(15))")
            } catch {
                print("⚠️ Could not list bundle contents: \(error)")
            }
        }

        // Try as direct file path first (for user-recorded audio)
        if FileManager.default.fileExists(atPath: nameOrPath) {
            print("✅ Audio file found at path: \(nameOrPath)")
            return URL(fileURLWithPath: nameOrPath)
        }
        
        // Try bundle root FIRST (matching flattened structure)
        let path1 = Bundle.module.path(forResource: nameOrPath, ofType: "m4a")
        print("   Checking bundle root (.m4a): \(path1 ?? "not found")")
        if let bundlePath = path1 {
            print("✅ Loaded audio '\(nameOrPath).m4a' from bundle root")
            return URL(fileURLWithPath: bundlePath)
        }
        
        // Try bundle resources with .m4a extension (Audio folder - fallback)
        let path2 = Bundle.module.path(forResource: nameOrPath, ofType: "m4a", inDirectory: "Audio")
        print("   Checking Audio/ (.m4a): \(path2 ?? "not found")")
        if let bundlePath = path2 {
            print("✅ Loaded audio '\(nameOrPath).m4a' from bundle Audio folder")
            return URL(fileURLWithPath: bundlePath)
        }
        
        let path3 = Bundle.module.path(forResource: nameOrPath, ofType: "mp3", inDirectory: "Audio")
        print("   Checking Audio/ (.mp3): \(path3 ?? "not found")")
        if let bundlePath = path3 {
            print("✅ Loaded audio '\(nameOrPath).mp3' from bundle Audio folder")
            return URL(fileURLWithPath: bundlePath)
        }
        
        let path4 = Bundle.module.path(forResource: nameOrPath, ofType: "mp3")
        print("   Checking bundle root (.mp3): \(path4 ?? "not found")")
        if let bundlePath = path4 {
            print("✅ Loaded audio '\(nameOrPath).mp3' from bundle root")
            return URL(fileURLWithPath: bundlePath)
        }
        
        print("⚠️ Could not load audio: \(nameOrPath)")
        print("   Tried: bundle root (.m4a/.mp3), Audio/ (.m4a/.mp3), file path")
        return nil
    }
    
    static func audioExists(at nameOrPath: String) -> Bool {
        return audioFromBundleOrPath(nameOrPath) != nil
    }
}
