import Foundation

extension DateFormatter {
    static let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
    
    static let timelineFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

extension Date {
    func relativeString() -> String {
        DateFormatter.relativeFormatter.localizedString(for: self, relativeTo: Date())
    }
    
    func timelineString() -> String {
        DateFormatter.timelineFormatter.string(from: self)
    }
}
