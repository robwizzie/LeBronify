//
//  AppDelegate.swift
//  LeBronify
//
//  Created by Robert Wiscount on 5/15/25.
//

import UIKit
import MediaPlayer
import AVFoundation
import BackgroundTasks
import WidgetKit
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

class AppDelegate: NSObject, UIApplicationDelegate {
    // App delegate needs to run any pending widget actions
    private var widgetCheckTimer: Timer?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Register for background processing
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.robertwiscount.LeBronify.widgetControl", using: nil) { task in
            self.handleWidgetControl(task: task as! BGProcessingTask)
        }
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        // Set up Darwin notification observers for widget intents
        setupWidgetControlNotifications()
        
        // Don't setup audio session during app launch
        // Will be initialized on-demand when audio playback is requested
        
        // Set up remote command center (without activating audio session)
        setupRemoteCommandCenter()
        
        // Update app icon based on the day
        updateAppIconForCurrentDay()
        
        // Set up date monitoring to change the icon when the day changes
        setupDateChangeMonitoring()
        
        // Start a timer to poll for widget actions
        startWidgetActionPolling()
        
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Check if this is a CarPlay session
        if connectingSceneSession.role == UISceneSession.Role.carTemplateApplication {
            let config = UISceneConfiguration(name: "CarPlay Configuration", sessionRole: connectingSceneSession.role)
            config.delegateClass = CarPlaySceneDelegate.self
            return config
        }
        
        // Return default configuration for non-CarPlay sessions
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    // MARK: - Audio Setup
    
    // Modified to be called on-demand and not during app initialization
    private func setupAudioSession() {
        // This has been moved to the AudioPlaybackManager and will be called
        // only when needed. We keep the method for compatibility with existing code
        // but it won't be called during app startup.
        print("AppDelegate: Audio session setup is handled by AudioPlaybackManager")
    }
    
    // MARK: - Remote Control Setup
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Access the shared ViewModel instance from your SwiftUI app
        let viewModel = getSharedViewModel()
        
        // Play command
        commandCenter.playCommand.addTarget { event in
            if let vm = viewModel, !vm.isPlaying {
                vm.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        // Pause command
        commandCenter.pauseCommand.addTarget { event in
            if let vm = viewModel, vm.isPlaying {
                vm.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        // Next track command
        commandCenter.nextTrackCommand.addTarget { event in
            if let vm = viewModel {
                vm.nextSong()
                return .success
            }
            return .commandFailed
        }
        
        // Previous track command
        commandCenter.previousTrackCommand.addTarget { event in
            if let vm = viewModel {
                vm.previousSong()
                return .success
            }
            return .commandFailed
        }
        
        // Seeking commands
        commandCenter.changePlaybackPositionCommand.addTarget { event in
            if let vm = viewModel,
               let positionEvent = event as? MPChangePlaybackPositionCommandEvent {
                vm.seek(to: positionEvent.positionTime)
                return .success
            }
            return .commandFailed
        }
        
        // Skip forward command
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [15] // 15 seconds
        commandCenter.skipForwardCommand.addTarget { event in
            if let vm = viewModel, let skipEvent = event as? MPSkipIntervalCommandEvent {
                let interval = skipEvent.interval
                vm.seek(to: min(vm.currentPlaybackTime + interval, vm.duration))
                return .success
            }
            return .commandFailed
        }
        
        // Skip backward command
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [15] // 15 seconds
        commandCenter.skipBackwardCommand.addTarget { event in
            if let vm = viewModel, let skipEvent = event as? MPSkipIntervalCommandEvent {
                let interval = skipEvent.interval
                vm.seek(to: max(vm.currentPlaybackTime - interval, 0))
                return .success
            }
            return .commandFailed
        }
        
        // Like/dislike commands (for favorite toggle)
        commandCenter.likeCommand.isEnabled = true
        commandCenter.likeCommand.localizedTitle = "Favorite"
        commandCenter.likeCommand.addTarget { event in
            if let vm = viewModel, let currentSong = vm.currentSong {
                // Only toggle to favorite if not already a favorite
                if !currentSong.isFavorite {
                    vm.toggleFavorite(for: currentSong.id)
                }
                return .success
            }
            return .commandFailed
        }
        
        commandCenter.dislikeCommand.isEnabled = true
        commandCenter.dislikeCommand.localizedTitle = "Remove Favorite"
        commandCenter.dislikeCommand.addTarget { event in
            if let vm = viewModel, let currentSong = vm.currentSong {
                // Only remove from favorites if it is a favorite
                if currentSong.isFavorite {
                    vm.toggleFavorite(for: currentSong.id)
                }
                return .success
            }
            return .commandFailed
        }
    }
    
    // MARK: - App Icon Management
    
    private let tacoTuesdayIconName = "TacoTuesdayIcon"
    private let defaultIconName: String? = nil // nil represents the primary app icon
    
    private func updateAppIconForCurrentDay() {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        
        // Use Taco Tuesday icon on Tuesdays
        if TacoTuesdayManager.shared.isTacoTuesday {
            setAppIcon(to: tacoTuesdayIconName)
        } else {
            // Use default icon on other days
            setAppIcon(to: defaultIconName)
        }
    }
    
    private func setAppIcon(to iconName: String?) {
        // Don't change if already using the requested icon
        if UIApplication.shared.alternateIconName == iconName {
            return
        }
        
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error = error {
                print("Error changing app icon: \(error.localizedDescription)")
            }
        }
    }
    
    private func setupDateChangeMonitoring() {
        // Monitor for date changes (midnight transitions)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDateChange),
            name: .NSCalendarDayChanged,
            object: nil
        )
        
        // Also check when app becomes active (covers cases where phone was off during day change)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    @objc private func handleDateChange() {
        updateAppIconForCurrentDay()
    }
    
    @objc private func handleAppBecameActive() {
        updateAppIconForCurrentDay()
    }
    
    // MARK: - Helper Methods
    
    private func getSharedViewModel() -> LeBronifyViewModel? {
        return LeBronifyApp.viewModel
    }
    
    func handleWidgetControl(task: BGProcessingTask) {
        // Schedule a new background task
        scheduleBackgroundProcessing()
        
        // Create a task request with a early termination handler
        task.expirationHandler = {
            // Handle early termination if needed
        }
        
        // Do any processing work
        // Check for pending widget actions
        processWidgetActions()
        
        // Mark the task complete
        task.setTaskCompleted(success: true)
    }
    
    func scheduleBackgroundProcessing() {
        let request = BGProcessingTaskRequest(identifier: "com.robertwiscount.LeBronify.widgetControl")
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule background task: \(error)")
        }
    }
    
    // Process any pending widget actions
    func processWidgetActions() {
        // Check if there are any pending actions stored in UserDefaults
        let sharedDefaults = UserDefaults(suiteName: "group.com.robertwiscount.LeBronify")
        
        // Check for direct action
        if let pendingAction = sharedDefaults?.string(forKey: "pendingWidgetAction") {
            // Process the action
            switch pendingAction {
            case "playPause":
                DispatchQueue.main.async {
                    LeBronifyApp.viewModel.togglePlayPause()
                    
                    // Also update remote control center status
                    let nowPlayingInfoCenter = MPNowPlayingInfoCenter.default()
                    if var nowPlayingInfo = nowPlayingInfoCenter.nowPlayingInfo {
                        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = LeBronifyApp.viewModel.isPlaying ? 1.0 : 0.0
                        nowPlayingInfoCenter.nowPlayingInfo = nowPlayingInfo
                    }
                }
            case "next":
                DispatchQueue.main.async {
                    LeBronifyApp.viewModel.nextSong()
                }
            case "previous":
                DispatchQueue.main.async {
                    LeBronifyApp.viewModel.previousSong()
                }
            default:
                break
            }
            
            // Clear the pending action
            sharedDefaults?.removeObject(forKey: "pendingWidgetAction")
        }
        
        // Also check for the last notification name and timestamp
        if let notificationName = sharedDefaults?.string(forKey: "latestNotificationName"),
           let timestamp = sharedDefaults?.double(forKey: "latestNotificationTimestamp") {
            
            // Only process recent notifications (within last 2 seconds)
            let now = Date().timeIntervalSince1970
            if now - timestamp < 2.0 {
                
                // Process the notification by name
                switch notificationName {
                case "com.robertwiscount.LeBronify.playPause":
                    DispatchQueue.main.async {
                        LeBronifyApp.viewModel.togglePlayPause()
                    }
                case "com.robertwiscount.LeBronify.previous":
                    DispatchQueue.main.async {
                        LeBronifyApp.viewModel.previousSong()
                    }
                case "com.robertwiscount.LeBronify.next":
                    DispatchQueue.main.async {
                        LeBronifyApp.viewModel.nextSong()
                    }
                default:
                    break
                }
                
                // Clear the notification info - mark as processed
                sharedDefaults?.removeObject(forKey: "latestNotificationName")
                sharedDefaults?.removeObject(forKey: "latestNotificationTimestamp")
            }
        }
    }
    
    // Set up notification observers
    private func setupWidgetControlNotifications() {
        // Make sure we're setup to listen for distributed notifications
        NotificationCenter.distributed().addObserver(
            self,
            selector: #selector(handleWidgetPlayPause),
            name: NSNotification.Name("com.robertwiscount.LeBronify.playPause"),
            object: nil as AnyObject?
        )
        
        NotificationCenter.distributed().addObserver(
            self,
            selector: #selector(handleWidgetPrevious),
            name: NSNotification.Name("com.robertwiscount.LeBronify.previous"),
            object: nil as AnyObject?
        )
        
        NotificationCenter.distributed().addObserver(
            self,
            selector: #selector(handleWidgetNext),
            name: NSNotification.Name("com.robertwiscount.LeBronify.next"),
            object: nil as AnyObject?
        )
    }
    
    @objc private func handleWidgetPlayPause() {
        DispatchQueue.main.async {
            LeBronifyApp.viewModel.togglePlayPause()
        }
    }
    
    @objc private func handleWidgetPrevious() {
        DispatchQueue.main.async {
            LeBronifyApp.viewModel.previousSong()
        }
    }
    
    @objc private func handleWidgetNext() {
        DispatchQueue.main.async {
            LeBronifyApp.viewModel.nextSong()
        }
    }
    
    private func startWidgetActionPolling() {
        // Cleanup any existing timer
        widgetCheckTimer?.invalidate()
        
        // Create a timer that runs every 0.5 seconds to check for widget actions
        widgetCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.processWidgetActions()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Process any pending widget actions immediately
        processWidgetActions()
        
        // Restart the polling timer
        startWidgetActionPolling()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Stop the polling timer to save resources
        widgetCheckTimer?.invalidate()
        widgetCheckTimer = nil
    }
}
