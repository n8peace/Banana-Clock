//
//  AlarmIntents.swift
//  BananaClock
//
//  App Intents for AlarmKit integration - custom alarm actions
//

import Foundation
import AppIntents
import AlarmKit

// MARK: - Primary Alarm Action

/// Positive alarm dismissal intent - "I'm Awake!" button
struct ImAwakeIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "I'm Awake!"
    static var description = IntentDescription("Dismiss the alarm and mark yourself as awake")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    @Parameter(title: "Alarm Type")
    var alarmType: String
    
    func perform() async throws -> some IntentResult {
        // Stop the alarm in AlarmKit
        if let alarmUUID = UUID(uuidString: alarmID) {
            try AlarmManager.shared.stop(id: alarmUUID)
        }
        
        // Stop any playing audio
        await AudioService.shared.stopAIWakeUp()
        await MainActor.run {
            AudioService.shared.stopAllSounds()
        }
        
        // Track successful wake-up for analytics
        await MainActor.run {
            UserDefaults.standard.set(Date(), forKey: "lastSuccessfulWakeUp")
            let currentWakeUps = UserDefaults.standard.integer(forKey: "totalWakeUps")
            UserDefaults.standard.set(currentWakeUps + 1, forKey: "totalWakeUps")
        }
        
        return .result(dialog: "Good morning! Have a great day! 🌅")
    }
}

// MARK: - Snooze Intents

/// 5-minute snooze intent
struct Snooze5Intent: LiveActivityIntent {
    static var title: LocalizedStringResource = "+5 minutes"
    static var description = IntentDescription("Snooze alarm for 5 minutes")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    func perform() async throws -> some IntentResult {
        if let alarmUUID = UUID(uuidString: alarmID) {
            // Stop current alarm
            try AlarmManager.shared.stop(id: alarmUUID)
            
            // Stop audio
            await AudioService.shared.stopAIWakeUp()
            await MainActor.run {
                AudioService.shared.stopAllSounds()
            }
            
            // Schedule new alarm 5 minutes from now
            await scheduleSnoozeAlarm(originalID: alarmUUID, minutes: 5)
        }
        
        return .result(dialog: "Snoozed for 5 minutes. See you soon! 😴")
    }
}

/// 10-minute snooze intent
struct Snooze10Intent: LiveActivityIntent {
    static var title: LocalizedStringResource = "+10 minutes"
    static var description = IntentDescription("Snooze alarm for 10 minutes")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    func perform() async throws -> some IntentResult {
        if let alarmUUID = UUID(uuidString: alarmID) {
            try AlarmManager.shared.stop(id: alarmUUID)
            await AudioService.shared.stopAIWakeUp()
            await MainActor.run {
                AudioService.shared.stopAllSounds()
            }
            await scheduleSnoozeAlarm(originalID: alarmUUID, minutes: 10)
        }
        
        return .result(dialog: "Snoozed for 10 minutes. Rest up! 😴")
    }
}

/// 15-minute snooze intent
struct Snooze15Intent: LiveActivityIntent {
    static var title: LocalizedStringResource = "+15 minutes"
    static var description = IntentDescription("Snooze alarm for 15 minutes")
    
    @Parameter(title: "Alarm ID")
    var alarmID: String
    
    func perform() async throws -> some IntentResult {
        if let alarmUUID = UUID(uuidString: alarmID) {
            try AlarmManager.shared.stop(id: alarmUUID)
            await AudioService.shared.stopAIWakeUp()
            await MainActor.run {
                AudioService.shared.stopAllSounds()
            }
            await scheduleSnoozeAlarm(originalID: alarmUUID, minutes: 15)
        }
        
        return .result(dialog: "Snoozed for 15 minutes. Sweet dreams! 😴")
    }
}

// MARK: - Timer Intents

/// Stop timer intent
struct StopTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop the timer")
    
    @Parameter(title: "Timer ID")
    var timerID: String
    
    func perform() async throws -> some IntentResult {
        if let timerUUID = UUID(uuidString: timerID) {
            try AlarmManager.shared.stop(id: timerUUID)
        }
        
        await AudioService.shared.stopAIWakeUp()
        await MainActor.run {
            AudioService.shared.stopAllSounds()
        }
        
        return .result(dialog: "Timer stopped! ✅")
    }
}

/// Repeat timer intent
struct RepeatTimerIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Repeat"
    static var description = IntentDescription("Start the same timer again")
    
    @Parameter(title: "Timer ID")
    var timerID: String
    
    @Parameter(title: "Timer Duration")
    var duration: Double
    
    @Parameter(title: "Timer Title")
    var title: String
    
    func perform() async throws -> some IntentResult {
        // Stop current timer
        if let timerUUID = UUID(uuidString: timerID) {
            try AlarmManager.shared.stop(id: timerUUID)
        }
        
        await AudioService.shared.stopAIWakeUp()
        await MainActor.run {
            AudioService.shared.stopAllSounds()
        }
        
        // Start new timer with same duration
        _ = try await AlarmKitService.shared.scheduleTimer(
            duration: duration,
            title: title
        )
        
        let formattedDuration = formatDuration(duration)
        return .result(dialog: "Started new \(formattedDuration) timer! ⏱️")
    }
}

// MARK: - Helper Functions

/// Schedule a snooze alarm
private func scheduleSnoozeAlarm(originalID: UUID, minutes: Int) async {
    do {
        let snoozeTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        
        // Try to get original alarm metadata to preserve settings
        let metadata = BananaClockMetadata.regular() // Default for snooze
        
        _ = try await AlarmKitService.shared.scheduleRegularAlarm(
            time: snoozeTime,
            title: "Snooze Alarm"
        )
        
        print("✅ Scheduled snooze alarm for \(minutes) minutes from now")
    } catch {
        print("❌ Failed to schedule snooze alarm: \(error)")
    }
}

/// Format duration for user display
private func formatDuration(_ duration: Double) -> String {
    let minutes = Int(duration / 60)
    let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
    
    if minutes > 0 {
        return seconds > 0 ? "\(minutes)m \(seconds)s" : "\(minutes)m"
    } else {
        return "\(seconds)s"
    }
}

// MARK: - App Intents Registration

// App Intents are automatically discovered by the system
// No manual configuration needed - intents are registered when the app is built