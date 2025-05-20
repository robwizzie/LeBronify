import WidgetKit
import SwiftUI

@main
struct LeBronifyWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Include the Dynamic Island Live Activity widget
        LeBronifyLiveActivityWidget()
    }
} 