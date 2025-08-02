//
//  LiveActivityAttributes.swift
//  BananaClock
//
//  Live Activity attributes for Dynamic Island and Lock Screen integration
//

import Foundation
import ActivityKit
import SwiftUI

// MARK: - Supporting Enums

enum AlarmState: String, Codable, CaseIterable {
    case ringing = "ringing"
    case snoozed = "snoozed"  
    case dismissed = "dismissed"
    case aiWakeUpPlaying = "ai_wakeup_playing"
    
    var displayName: String {
        switch self {
        case .ringing: return "Ringing"
        case .snoozed: return "Snoozed"
        case .dismissed: return "Dismissed"
        case .aiWakeUpPlaying: return "AI Wake-Up"
        }
    }
    
    var icon: String {
        switch self {
        case .ringing: return "bell.fill"
        case .snoozed: return "clock.arrow.circlepath"
        case .dismissed: return "checkmark.circle.fill"
        case .aiWakeUpPlaying: return "brain.head.profile"
        }
    }
}

// MARK: - Timer Live Activity

struct TimerActivityAttributes: ActivityAttributes, Codable {
    struct ContentState: Codable, Hashable {
        let remainingTime: TimeInterval
        let isRunning: Bool
        let isPaused: Bool
        let totalDuration: TimeInterval
        let startTime: Date
        
        // Progress calculation
        var progress: Double {
            guard totalDuration > 0 else { return 0 }
            let elapsed = totalDuration - remainingTime
            return min(max(elapsed / totalDuration, 0), 1)
        }
        
        // Formatted time display
        var formattedTime: String {
            let minutes = Int(remainingTime) / 60
            let seconds = Int(remainingTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        // Status for UI
        var statusText: String {
            if isPaused {
                return "Timer Paused"
            } else if isRunning {
                return "Timer Running"
            } else {
                return "Timer Stopped"
            }
        }
    }
    
    let timerID: String
    let originalDuration: TimeInterval
    let title: String
    let soundIdentifier: String
    
    // Formatted duration for display
    var formattedDuration: String {
        let minutes = Int(originalDuration) / 60
        let seconds = Int(originalDuration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Stopwatch Live Activity  

struct StopwatchActivityAttributes: ActivityAttributes, Codable {
    struct ContentState: Codable, Hashable {
        let elapsedTime: TimeInterval
        let isRunning: Bool
        let lapCount: Int
        let lastLapTime: TimeInterval?
        let startTime: Date
        
        // Formatted elapsed time
        var formattedTime: String {
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            let centiseconds = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "%d:%02d.%02d", minutes, seconds, centiseconds)
        }
        
        // Formatted time without centiseconds for compact display
        var compactFormattedTime: String {
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        // Status for UI
        var statusText: String {
            if isRunning {
                return "Stopwatch Running"
            } else if elapsedTime > 0 {
                return "Stopwatch Stopped"
            } else {
                return "Stopwatch Ready"
            }
        }
        
        // Last lap formatted time
        var formattedLastLapTime: String? {
            guard let lastLapTime = lastLapTime else { return nil }
            let minutes = Int(lastLapTime) / 60
            let seconds = Int(lastLapTime) % 60
            let centiseconds = Int((lastLapTime.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "%d:%02d.%02d", minutes, seconds, centiseconds)
        }
    }
    
    let stopwatchID: String
    let sessionStartTime: Date
    
    // Session duration for reference
    var sessionDuration: TimeInterval {
        Date().timeIntervalSince(sessionStartTime)
    }
}

// MARK: - Alarm Live Activity

struct AlarmActivityAttributes: ActivityAttributes, Codable {
    struct ContentState: Codable, Hashable {
        let alarmState: AlarmState
        let snoozeTimeRemaining: TimeInterval?
        let wakeUpContent: String?
        let currentTime: Date
        let snoozeCount: Int
        
        // Formatted snooze countdown
        var formattedSnoozeTime: String? {
            guard let snoozeTime = snoozeTimeRemaining, snoozeTime > 0 else { return nil }
            let minutes = Int(snoozeTime) / 60
            let seconds = Int(snoozeTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        // Status message
        var statusMessage: String {
            switch alarmState {
            case .ringing:
                return "Alarm Ringing"
            case .snoozed:
                return "Snoozed (\(snoozeCount)/3)"
            case .dismissed:
                return "Good Morning!"
            case .aiWakeUpPlaying:
                return "AI Wake-Up"
            }
        }
        
        // Current time formatted
        var formattedCurrentTime: String {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: currentTime)
        }
        
        // Snooze progress (0-1) for visual indicator
        var snoozeProgress: Double {
            guard let snoozeTime = snoozeTimeRemaining, snoozeTime > 0 else { return 0 }
            // Assuming 10-minute snooze as default for progress calculation
            let totalSnoozeTime: TimeInterval = 10 * 60
            return max(0, min(1, (totalSnoozeTime - snoozeTime) / totalSnoozeTime))
        }
    }
    
    let alarmID: String
    let alarmType: AlarmType
    let scheduledTime: Date
    let alarmTitle: String
    let musicSelection: String?
    let voicePreference: String?
    
    // Formatted scheduled time
    var formattedScheduledTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: scheduledTime)
    }
    
    // Is AI wake-up alarm
    var isAIWakeUp: Bool {
        alarmType == AlarmType.aiWakeUp
    }
}



// MARK: - Extensions for Easy Creation

extension TimerActivityAttributes.ContentState {
    static func running(remainingTime: TimeInterval, totalDuration: TimeInterval, startTime: Date) -> TimerActivityAttributes.ContentState {
        return TimerActivityAttributes.ContentState(
            remainingTime: remainingTime,
            isRunning: true,
            isPaused: false,
            totalDuration: totalDuration,
            startTime: startTime
        )
    }
    
    static func paused(remainingTime: TimeInterval, totalDuration: TimeInterval, startTime: Date) -> TimerActivityAttributes.ContentState {
        return TimerActivityAttributes.ContentState(
            remainingTime: remainingTime,
            isRunning: false,
            isPaused: true,
            totalDuration: totalDuration,
            startTime: startTime
        )
    }
    
    static func completed(totalDuration: TimeInterval, startTime: Date) -> TimerActivityAttributes.ContentState {
        return TimerActivityAttributes.ContentState(
            remainingTime: 0,
            isRunning: false,
            isPaused: false,
            totalDuration: totalDuration,
            startTime: startTime
        )
    }
}

extension StopwatchActivityAttributes.ContentState {
    static func running(elapsedTime: TimeInterval, lapCount: Int, lastLapTime: TimeInterval? = nil, startTime: Date) -> StopwatchActivityAttributes.ContentState {
        return StopwatchActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            isRunning: true,
            lapCount: lapCount,
            lastLapTime: lastLapTime,
            startTime: startTime
        )
    }
    
    static func stopped(elapsedTime: TimeInterval, lapCount: Int, lastLapTime: TimeInterval? = nil, startTime: Date) -> StopwatchActivityAttributes.ContentState {
        return StopwatchActivityAttributes.ContentState(
            elapsedTime: elapsedTime,
            isRunning: false,
            lapCount: lapCount,
            lastLapTime: lastLapTime,
            startTime: startTime
        )
    }
}

extension AlarmActivityAttributes.ContentState {
    static func ringing(currentTime: Date = Date(), wakeUpContent: String? = nil) -> AlarmActivityAttributes.ContentState {
        return AlarmActivityAttributes.ContentState(
            alarmState: .ringing,
            snoozeTimeRemaining: nil,
            wakeUpContent: wakeUpContent,
            currentTime: currentTime,
            snoozeCount: 0
        )
    }
    
    static func snoozed(snoozeTime: TimeInterval, snoozeCount: Int, currentTime: Date = Date()) -> AlarmActivityAttributes.ContentState {
        return AlarmActivityAttributes.ContentState(
            alarmState: .snoozed,
            snoozeTimeRemaining: snoozeTime,
            wakeUpContent: nil,
            currentTime: currentTime,
            snoozeCount: snoozeCount
        )
    }
    
    static func aiWakeUpPlaying(wakeUpContent: String, currentTime: Date = Date()) -> AlarmActivityAttributes.ContentState {
        return AlarmActivityAttributes.ContentState(
            alarmState: .aiWakeUpPlaying,
            snoozeTimeRemaining: nil,
            wakeUpContent: wakeUpContent,
            currentTime: currentTime,
            snoozeCount: 0
        )
    }
    
    static func dismissed(currentTime: Date = Date()) -> AlarmActivityAttributes.ContentState {
        return AlarmActivityAttributes.ContentState(
            alarmState: .dismissed,
            snoozeTimeRemaining: nil,
            wakeUpContent: nil,
            currentTime: currentTime,
            snoozeCount: 0
        )
    }
}