//
//  BananaClockWidgetBundle.swift
//  BananaClockWidgets
//
//  Widget Extension for Live Activities and Dynamic Island integration
//

import WidgetKit
import SwiftUI

@main
struct BananaClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerLiveActivity()
        StopwatchLiveActivity()
        AlarmLiveActivity()
    }
}