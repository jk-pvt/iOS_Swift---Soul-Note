import Foundation
import UserNotifications

class LetterNotificationService: NSObject {
    static let shared = LetterNotificationService()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    var onNotificationTap: ((UUID) -> Void)?
    
    private override init() {
        super.init()
        notificationCenter.delegate = self
    }
    
    // MARK: - Permission Management
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    func checkPermissionStatus(completion: @escaping (Bool) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus == .authorized)
            }
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleDeliveryNotification(for letter: Letter) {
        guard let deliveryDate = letter.deliveryDate else { return }
        
        guard deliveryDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "A letter has arrived."
        content.body = "A memory written for you is ready to be opened."
        content.sound = .default
        content.badge = 1
        
        content.userInfo = ["letterId": letter.id.uuidString]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: deliveryDate)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: notificationIdentifier(for: letter.id),
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }
    
    func cancelNotification(for letterId: UUID) {
        let identifier = notificationIdentifier(for: letterId)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Helpers
    
    private func notificationIdentifier(for letterId: UUID) -> String {
        return "letter_delivery_\(letterId.uuidString)"
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        notificationCenter.getPendingNotificationRequests { requests in
            DispatchQueue.main.async {
                completion(requests)
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension LetterNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let letterIdString = userInfo["letterId"] as? String,
           let letterId = UUID(uuidString: letterIdString) {
            DispatchQueue.main.async {
                self.onNotificationTap?(letterId)
            }
        }
        
        completionHandler()
    }
}
