//
//  DistributedNotificationExtension.swift
//  LeBronify
//
//  Created by Robert Wiscount on 5/15/25.
//

import Foundation

// Helper class for cross-process notifications
class CrossProcessNotificationCenter {
    static let shared = CrossProcessNotificationCenter()
    
    func post(name: NSNotification.Name, object: Any?) {
        // Use shared UserDefaults since distributed notifications have limitations on iOS
        let sharedDefaults = UserDefaults(suiteName: "group.com.robertwiscount.LeBronify")
        
        // Store the notification name and timestamp
        sharedDefaults?.set(name.rawValue, forKey: "latestNotificationName")
        sharedDefaults?.set(Date().timeIntervalSince1970, forKey: "latestNotificationTimestamp")
        
        // Also post locally for widgets that are currently active
        NotificationCenter.default.post(name: name, object: object)
    }
    
    func addObserver(_ observer: Any, selector: Selector, name: NSNotification.Name, object: Any?) {
        // Register with the regular notification center
        NotificationCenter.default.addObserver(observer, selector: selector, name: name, object: object)
    }
}

// Extension to mimic DistributedNotificationCenter on iOS
extension NotificationCenter {
    static func distributed() -> CrossProcessNotificationCenter {
        return CrossProcessNotificationCenter.shared
    }
} 