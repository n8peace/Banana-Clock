//
//  WidgetModels.swift
//  BananaClockWidgets
//
//  Essential models for Widget Extension - duplicated from main app for access
//

import Foundation
import ActivityKit
import AppIntents

// MARK: - Timer Live Activity Attributes

struct TimerActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic properties
        let remainingTime: TimeInterval
        let isRunning: Bool
        let isPaused: Bool
        let totalDuration: TimeInterval
        let startTime: Date
        let statusText: String
        let progress: Double
        
        // Computed properties for UI
        var formattedTime: String {
            let totalSeconds = Int(remainingTime)
            let hours = totalSeconds / 3600
            let minutes = (totalSeconds % 3600) / 60
            let seconds = totalSeconds % 60
            
            if hours > 0 {
                return String(format: "%d:%02d:%02d", hours, minutes, seconds)
            } else {
                return String(format: "%d:%02d", minutes, seconds)
            }
        }
    }
    
    // Static properties
    let timerID: UUID
    let title: String
    let soundIdentifier: String
    let totalDuration: TimeInterval
    
    // Computed properties for attributes
    var formattedDuration: String {
        let totalSeconds = Int(totalDuration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Stopwatch Live Activity Attributes

struct StopwatchActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic properties
        let elapsedTime: TimeInterval
        let isRunning: Bool
        let lapCount: Int
        let lastLapTime: TimeInterval?
        let statusText: String
        
        // Computed properties for UI
        var formattedTime: String {
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            let hundredths = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
        }
        
        var compactFormattedTime: String {
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            if minutes > 0 {
                return String(format: "%d:%02d", minutes, seconds)
            } else {
                return String(format: "%02d", seconds)
            }
        }
        
        var formattedLastLapTime: String? {
            guard let lastLapTime = lastLapTime else { return nil }
            let minutes = Int(lastLapTime) / 60
            let seconds = Int(lastLapTime) % 60
            let hundredths = Int((lastLapTime.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
        }
    }
    
    // Static properties
    let stopwatchID: UUID
}

// MARK: - Alarm Live Activity Attributes

enum AlarmState: String, Codable, CaseIterable {
    case ringing = "ringing"
    case snoozed = "snoozed"
    case dismissed = "dismissed"
    case aiWakeUpPlaying = "ai_wakeup_playing"
}

enum AlarmType: String, Codable {
    case regular = "regular"
    case aiWakeUp = "ai_wakeup"
}

struct AlarmActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic properties
        let alarmState: AlarmState
        let currentTime: Date
        let snoozeEndTime: Date?
        let wakeUpContent: String?
        let statusMessage: String
        let snoozeProgress: Double
        
        // Computed properties for UI
        var formattedCurrentTime: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: currentTime)
        }
        
        var formattedSnoozeTime: String? {
            guard let snoozeEndTime = snoozeEndTime else { return nil }
            let timeInterval = snoozeEndTime.timeIntervalSince(Date())
            guard timeInterval > 0 else { return nil }
            
            let minutes = Int(timeInterval) / 60
            let seconds = Int(timeInterval) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    // Static properties
    let alarmID: UUID
    let alarmTitle: String
    let scheduledTime: Date
    let isAIWakeUp: Bool
    let alarmType: AlarmType
    
    // Computed properties for attributes
    var formattedScheduledTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledTime)
    }
}

// MARK: - App Intents for Widget Extension

// Timer Intents
struct ResumeTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Resume"
    static var description = IntentDescription("Resume the paused timer")
    
    @Parameter(title: "Timer ID")
    var timerID: String
    
    @Parameter(title: "Remaining Time")
    var remainingTime: Double
    
    func perform() async throws -> some IntentResult {
        // Intent implementation will be handled by main app
        return .result(dialog: "Timer resumed ▶️")
    }
}

struct PauseTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Pause"
    static var description = IntentDescription("Pause the running timer")
    
    @Parameter(title: "Timer ID")
    var timerID: String
    
    @Parameter(title: "Remaining Time")
    var remainingTime: Double
    
    func perform() async throws -> some IntentResult {
        return .result(dialog: "Timer paused ⏸️")
    }
}

struct CancelTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Cancel"
    static var description = IntentDescription("Cancel the timer completely")
    
    @Parameter(title: "Timer ID")
    var timerID: String
    
    func perform() async throws -> some IntentResult {
        return .result(dialog: "Timer cancelled 🚫")
    }
}

// Stopwatch Intents
struct LapStopwatchIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Lap"
    static var description = IntentDescription("Record a lap time")
    
    @Parameter(title: "Stopwatch ID")
    var stopwatchID: String
    
    @Parameter(title: "Elapsed Time")
    var elapsedTime: Double
    
    @Parameter(title: "Lap Count")
    var lapCount: Int
    
    func perform() async throws -> some IntentResult {
        return .result(dialog: "Lap recorded 🏃‍♂️")
    }
}

struct StopStopwatchIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop the running stopwatch")
    
    @Parameter(title: "Stopwatch ID")
    var stopwatchID: String
    
    @Parameter(title: "Elapsed Time")
    var elapsedTime: Double
    
    @Parameter(title: "Lap Count")
    var lapCount: Int
    
    func perform() async throws -> some IntentResult {
        return .result(dialog: "Stopwatch stopped ⏹️")
    }
}

struct ResetStopwatchIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Reset"
    static var description = IntentDescription("Reset the stopwatch to zero")
    
    @Parameter(title: "Stopwatch ID")
    var stopwatchID: String
    
    func perform() async throws -> some IntentResult {
        return .result(dialog: "Stopwatch reset 🔄")
    }
}

// Alarm Intents
struct ImAwakeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "I'm Awake!"
    static var description = IntentDescription("Dismiss the alarm and mark yourself as awake")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    @Parameter(title: "Alarm Type")
    var alarmType: String
    
    func perform() async throws -> some IntentResult {
        return .result(dialog: "Good morning! Have a great day! 🌅")
    }
}

struct Snooze10Intent: LiveActivityIntent {
    static var title: LocalizedStringResource = "+10 minutes"
    static var description = IntentDescription("Snooze alarm for 10 minutes")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    func perform() async throws -> some IntentResult {
        return .result(dialog: "Snoozed for 10 minutes. Rest up! 😴")
    }
}