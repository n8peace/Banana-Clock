//
//  Alarm.swift
//  BananaClock
//
//  Core alarm model
//

import Foundation
import SwiftUI

struct Alarm: Identifiable, Codable, Equatable {
    let id: UUID
    var time: Date
    var label: String
    var isEnabled: Bool
    var isAIEnabled: Bool
    var soundIdentifier: String
    var snoozeLength: Int? // minutes (1-15), nil means snooze is disabled
    var repeatDays: [Weekday]
    var volume: Float // 0.0-1.0
    var isWakeUpAlarm: Bool

    var lastUsedAt: Date
    let createdAt: Date
    var updatedAt: Date
    
    // Computed properties
    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: time)
    }
    
    var nextFireDate: Date {
        calculateNextFireDate()
    }
    
    var repeatDescription: String {
        if repeatDays.isEmpty {
            return "Once"
        } else if repeatDays.count == 7 {
            return "Every day"
        } else if repeatDays.count == 5 && 
                  !repeatDays.contains(.saturday) && 
                  !repeatDays.contains(.sunday) {
            return "Weekdays"
        } else if repeatDays.count == 2 && 
                  repeatDays.contains(.saturday) && 
                  repeatDays.contains(.sunday) {
            return "Weekends"
        } else {
            return repeatDays.map { $0.shortName }.joined(separator: ", ")
        }
    }
    
    // Initialization
    init(
        id: UUID = UUID(),
        time: Date,
        label: String = "Alarm",
        isEnabled: Bool = true,
        isAIEnabled: Bool = false,
        soundIdentifier: String = AlarmSound.default.rawValue,
        snoozeLength: Int? = 9,
        repeatDays: [Weekday]? = nil,
        volume: Float = 0.7,
        isWakeUpAlarm: Bool = false,

        lastUsedAt: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        // Set default repeat days based on alarm type
        let defaultRepeatDays: [Weekday]
        if let repeatDays = repeatDays {
            defaultRepeatDays = repeatDays
        } else if isWakeUpAlarm {
            defaultRepeatDays = [.monday, .tuesday, .wednesday, .thursday, .friday] // Weekdays for wake-up alarms
        } else {
            defaultRepeatDays = [] // No repeat for regular alarms
        }
        self.id = id
        self.time = time
        self.label = label
        self.isEnabled = isEnabled
        self.isAIEnabled = isAIEnabled
        self.soundIdentifier = soundIdentifier
        self.snoozeLength = snoozeLength.map { max(1, min(15, $0)) }
        self.repeatDays = defaultRepeatDays
        self.volume = max(0, min(1, volume))
        self.isWakeUpAlarm = isWakeUpAlarm

        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Methods
    private func calculateNextFireDate() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Get time components
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        // If no repeat, find next occurrence
        if repeatDays.isEmpty {
            var nextDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                       minute: timeComponents.minute ?? 0,
                                       second: 0,
                                       of: now) ?? now
            
            // If time has passed today, set for tomorrow
            if nextDate <= now {
                nextDate = calendar.date(byAdding: .day, value: 1, to: nextDate) ?? nextDate
            }
            
            return nextDate
        }
        
        // For repeating alarms, find next matching day
        for dayOffset in 0..<8 {
            let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: now) ?? now
            let weekday = calendar.component(.weekday, from: checkDate)
            
            if let matchingDay = Weekday(rawValue: weekday),
               repeatDays.contains(matchingDay) {
                
                let nextDate = calendar.date(bySettingHour: timeComponents.hour ?? 0,
                                           minute: timeComponents.minute ?? 0,
                                           second: 0,
                                           of: checkDate) ?? checkDate
                
                // If it's today but time has passed, skip to next occurrence
                if dayOffset == 0 && nextDate <= now {
                    continue
                }
                
                return nextDate
            }
        }
        
        return now
    }
}

// MARK: - Weekday
extension Alarm {
    enum Weekday: Int, CaseIterable, Codable {
        case sunday = 1
        case monday = 2
        case tuesday = 3
        case wednesday = 4
        case thursday = 5
        case friday = 6
        case saturday = 7
        
        var shortName: String {
            switch self {
            case .sunday: return "Sun"
            case .monday: return "Mon"
            case .tuesday: return "Tue"
            case .wednesday: return "Wed"
            case .thursday: return "Thu"
            case .friday: return "Fri"
            case .saturday: return "Sat"
            }
        }
        
        var fullName: String {
            switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
            }
        }
    }
}

// MARK: - Alarm Sound
// Note: AlarmSound is defined in alarm-sound-model.swift as an enum

// MARK: - AI Voice Options
enum AIVoiceOption: String, CaseIterable, Codable {
    case voice1 = "voice_1"
    case voice2 = "voice_2"
    case voice3 = "voice_3"
    
    var displayName: String {
        switch self {
        case .voice1: return "Zen Master"
        case .voice2: return "Sergeant"
        case .voice3: return "Guide"
        }
    }
    
    var description: String {
        switch self {
        case .voice1: return "Calm and peaceful morning guidance"
        case .voice2: return "Energetic motivation to start your day"
        case .voice3: return "Friendly companion for your morning"
        }
    }
}