//
//  AppIconManager.swift
//  LeBronify
//
//  Created by Robert Wiscount on 4/1/25.
//


import UIKit

class AppIconManager {
    static let shared = AppIconManager()
    
    private let tacoTuesdayIconName = "TacoTuesdayIcon"
    // Fix: Use an optional string properly
    private let defaultIconName: String? = nil // nil represents the primary app icon
    
    // Check if alternate icons are supported on this device
    var supportsAlternateIcons: Bool {
        return UIApplication.shared.supportsAlternateIcons
    }
    
    // Set the appropriate icon based on the day of week
    func updateAppIconForCurrentDay() {
        guard supportsAlternateIcons else { return }
        
        // Use Taco Tuesday icon on Tuesdays
        if TacoTuesdayManager.shared.isTacoTuesday {
            setAppIcon(to: tacoTuesdayIconName)
        } else {
            // Use default icon on other days
            setAppIcon(to: defaultIconName)
        }
    }
    
    // Set a specific app icon
    func setAppIcon(to iconName: String?) {
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
}
