//
//  LeBronifyWidgetyExtensionBundle.swift
//  LeBronifyWidgetyExtension
//
//  Created by Robert Wiscount on 5/15/25.
//

import WidgetKit
import SwiftUI

@main
struct LeBronifyWidgetyExtensionBundle: WidgetBundle {
    var body: some Widget {
        LeBronifyWidgetyExtension()
        LeBronifyWidgetyExtensionLiveActivity()
    }
}
