import Foundation

extension FileManager {
    static func generateAudioPath() -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let audioDir = documentsPath.appendingPathComponent("Audio")
        try? FileManager.default.createDirectory(at: audioDir, withIntermediateDirectories: true)
        let filename = "\(UUID().uuidString).m4a"
        return audioDir.appendingPathComponent(filename).path
    }
    
    static func generatePhotoPath() -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photoDir = documentsPath.appendingPathComponent("Photos")
        try? FileManager.default.createDirectory(at: photoDir, withIntermediateDirectories: true)
        let filename = "\(UUID().uuidString).jpg"
        return photoDir.appendingPathComponent(filename).path
    }
}
