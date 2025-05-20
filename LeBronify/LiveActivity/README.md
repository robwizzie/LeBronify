# LeBronify Dynamic Island Integration

This implementation adds support for Dynamic Island on iPhone 14 Pro and newer models. The Dynamic Island will display the currently playing song with playback controls and progress information.

## Setup Instructions

1. **Add the Widget Extension Target**:

    - In Xcode, go to File > New > Target
    - Choose "Widget Extension"
    - Name it "LeBronifyWidgetExtension"
    - Make sure "Include Live Activity" is checked
    - Complete the wizard

2. **Copy Implementation Files**:

    - Copy `LeBronifyLiveActivityAttributes.swift` to both the main app and widget extension targets
    - Copy `LeBronifyLiveActivityWidget.swift` to the widget extension target
    - Keep `LiveActivityManager.swift` only in the main app target

3. **Configure Entitlements**:

    - Make sure both the main app and widget extension have the "Push Notifications" entitlement enabled
    - For the main app, enable the "Live Activities" capability in the Signing & Capabilities tab

4. **Update Project Settings**:

    - In build settings, make sure both targets have the same deployment target (iOS 16.1 or later)
    - Ensure both targets use the same team for code signing

5. **Running the App**:
    - Build and run the app on a compatible device (iPhone 14 Pro or newer)
    - Start playing music to see the Dynamic Island integration

## How It Works

1. When a song starts playing, the `LiveActivityManager` starts a new Live Activity
2. The Live Activity appears in the Dynamic Island with album art, song information, and playback controls
3. As playback progresses, the activity updates with the current time and progress
4. When a song ends or the user switches songs, the current activity ends and a new one begins

## Troubleshooting

-   If the Dynamic Island doesn't appear, check that Live Activities are enabled in Settings > Face ID & Passcode > Live Activities
-   Ensure your test device is running iOS 16.1 or later
-   Check that the app's Info.plist contains the `NSSupportsLiveActivities` key set to `true`

## Customizing the Dynamic Island

You can customize the appearance of the Dynamic Island by modifying the `LeBronifyLiveActivityWidget.swift` file:

-   Edit the compact, minimal, and expanded views to match your app's design
-   Change colors, fonts, and layout as needed
-   Add additional interactive elements

Remember that the Dynamic Island has specific sizing constraints, so keep your UI elements appropriately sized.
