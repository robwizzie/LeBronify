//
//  LiveActivityAppIntent.swift
//  LeBronify
//
//  Created by Robert Wiscount on 5/15/25.
//

import AppIntents
import WidgetKit
import ActivityKit
import Foundation

// Play/Pause intent
struct PlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play or Pause"
    static var description = IntentDescription("Toggles playback between play and pause")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Get current playback status from shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.robertwiscount.LeBronify")
        let isPlaying = sharedDefaults?.bool(forKey: "isPlaying") ?? false
        
        // Store the action in UserDefaults for the app to pick up
        sharedDefaults?.set("playPause", forKey: "pendingWidgetAction")
        
        // Post a notification to a Darwin notification center that can be observed across processes
        NotificationCenter.distributed().post(
            name: NSNotification.Name("com.robertwiscount.LeBronify.playPause"),
            object: nil as AnyObject?
        )
        
        // Post a local notification that the widget extension can observe
        NotificationCenter.default.post(
            name: Notification.Name("WidgetPlayPauseTapped"),
            object: nil,
            userInfo: ["isPlaying": isPlaying]
        )
        
        // Reload widget timelines to reflect changes soon
        WidgetCenter.shared.reloadAllTimelines()
        
        // Mark as handled so user stays in widget
        return .result(dialog: IntentDialog(isPlaying ? "Pausing" : "Playing"))
    }
}

// Previous track intent
struct PreviousTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Previous Track"
    static var description = IntentDescription("Go to the previous track")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Store action in shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.robertwiscount.LeBronify")
        sharedDefaults?.set("previous", forKey: "pendingWidgetAction")
        
        // Post to distributed notification center
        NotificationCenter.distributed().post(
            name: NSNotification.Name("com.robertwiscount.LeBronify.previous"),
            object: nil as AnyObject?
        )
        
        // Post local notification
        NotificationCenter.default.post(name: Notification.Name("WidgetPreviousTapped"), object: nil)
        
        // Reload widget timelines to reflect changes soon
        WidgetCenter.shared.reloadAllTimelines()
        
        // Mark as handled so user stays in widget
        return .result(dialog: IntentDialog("Previous track"))
    }
}

// Next track intent
struct NextTrackIntent: AppIntent {
    static var title: LocalizedStringResource = "Next Track"
    static var description = IntentDescription("Skip to the next track")
    
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Store action in shared UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.robertwiscount.LeBronify")
        sharedDefaults?.set("next", forKey: "pendingWidgetAction")
        
        // Post to distributed notification center
        NotificationCenter.distributed().post(
            name: NSNotification.Name("com.robertwiscount.LeBronify.next"),
            object: nil as AnyObject?
        )
        
        // Post local notification
        NotificationCenter.default.post(name: Notification.Name("WidgetNextTapped"), object: nil)
        
        // Reload widget timelines to reflect changes soon
        WidgetCenter.shared.reloadAllTimelines()
        
        // Mark as handled so user stays in widget
        return .result(dialog: IntentDialog("Next track"))
    }
} 