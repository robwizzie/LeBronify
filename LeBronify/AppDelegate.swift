import UIKit
import MediaPlayer
import AVFoundation

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Setup audio session
        setupAudioSession()
        
        // Set up remote command center
        setupRemoteCommandCenter()
        
        // Update app icon based on the day
        updateAppIconForCurrentDay()
        
        // Set up date monitoring to change the icon when the day changes
        setupDateChangeMonitoring()
        
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
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Remote Control Setup
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // Access the shared ViewModel instance from your SwiftUI app
        let viewModel = getSharedViewModel()
        
        // Play command
        commandCenter.playCommand.addTarget { [weak self] event in
            if let vm = viewModel, !vm.isPlaying {
                vm.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] event in
            if let vm = viewModel, vm.isPlaying {
                vm.togglePlayPause()
                return .success
            }
            return .commandFailed
        }
        
        // Next track command
        commandCenter.nextTrackCommand.addTarget { [weak self] event in
            if let vm = viewModel {
                vm.nextSong()
                return .success
            }
            return .commandFailed
        }
        
        // Previous track command
        commandCenter.previousTrackCommand.addTarget { [weak self] event in
            if let vm = viewModel {
                vm.previousSong()
                return .success
            }
            return .commandFailed
        }
        
        // Seeking commands
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
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
        commandCenter.skipForwardCommand.addTarget { [weak self] event in
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
        commandCenter.skipBackwardCommand.addTarget { [weak self] event in
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
        commandCenter.likeCommand.addTarget { [weak self] event in
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
        commandCenter.dislikeCommand.addTarget { [weak self] event in
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
}
