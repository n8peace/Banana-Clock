//
//  AlarmKitService.swift
//  BananaClock
//
//  AlarmKit integration for iOS 26+ native alarm system
//

import Foundation
import AlarmKit
import SwiftUI
import AppIntents

// Type aliases to avoid conflicts  
typealias BananaClockAlarm = BananaClock.Alarm

@MainActor
class AlarmKitService: ObservableObject {
    static let shared = AlarmKitService()
    
    private let alarmManager = AlarmManager.shared
    
    @Published var authorizationState: AlarmManager.AuthorizationState = .notDetermined
    @Published var alarms: [AlarmKit.Alarm] = []
    @Published var isObservingUpdates = false
    
    private init() {
        // Initialize authorization state
        authorizationState = alarmManager.authorizationState
        
        // Start observing alarm updates
        startObservingAlarmUpdates()
        startObservingAuthorizationUpdates()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        do {
            let state = try await alarmManager.requestAuthorization()
            authorizationState = state
            print("✅ AlarmKit authorization result: \(state)")
            return state == .authorized
        } catch {
            print("❌ AlarmKit authorization failed: \(error)")
            return false
        }
    }
    
    var isAuthorized: Bool {
        authorizationState == .authorized
    }
    
    // MARK: - Alarm Scheduling
    
    func scheduleAIWakeUpAlarm(
        id: UUID = UUID(),
        time: Date,
        weekdays: Set<Int> = [],
        musicSelection: String,
        voicePreference: String,
        customMessage: String? = nil
    ) async throws -> AlarmKit.Alarm {
        guard isAuthorized else {
            throw AlarmKitError.notAuthorized
        }
        
        // Create schedule
        let schedule = createSchedule(time: time, weekdays: weekdays)
        
        // Create metadata
        let metadata = BananaClockMetadata.aiWakeUp(
            musicSelection: musicSelection,
            voicePreference: voicePreference,
            customMessage: customMessage
        )
        
        // Create presentation
        let presentation = createAIWakeUpPresentation(
            title: customMessage ?? "AI Wake-Up",
            metadata: metadata
        )
        
        // Create attributes
        let attributes = AlarmAttributes<BananaClockMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color.bananaYellow
        )
        
        // Create App Intents for alarm actions
        let stopIntent = ImAwakeIntent()
        stopIntent.alarmID = id.uuidString
        stopIntent.alarmType = "ai_wakeup"
        
        let snoozeIntent = Snooze10Intent() // Default to 10 minute snooze
        snoozeIntent.alarmID = id.uuidString
        
        // Create configuration
        let configuration = AlarmManager.AlarmConfiguration<BananaClockMetadata>(
            countdownDuration: nil,
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: snoozeIntent,
            sound: .default
        )
        
        // Schedule the alarm
        let alarm = try await alarmManager.schedule(id: id, configuration: configuration)
        print("✅ Scheduled AI wake-up alarm: \(alarm.id)")
        
        return alarm
    }
    
    func scheduleRegularAlarm(
        id: UUID = UUID(),
        time: Date,
        weekdays: Set<Int> = [],
        title: String = "Alarm"
    ) async throws -> AlarmKit.Alarm {
        guard isAuthorized else {
            throw AlarmKitError.notAuthorized
        }
        
        // Create schedule
        let schedule = createSchedule(time: time, weekdays: weekdays)
        
        // Create metadata
        let metadata = BananaClockMetadata.regular()
        
        // Create presentation
        let presentation = createRegularAlarmPresentation(title: title)
        
        // Create attributes
        let attributes = AlarmAttributes<BananaClockMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color.bananaYellow
        )
        
        // Create App Intents for alarm actions
        let stopIntent = ImAwakeIntent()
        stopIntent.alarmID = id.uuidString
        stopIntent.alarmType = "regular"
        
        let snoozeIntent = Snooze10Intent() // Default to 10 minute snooze
        snoozeIntent.alarmID = id.uuidString
        
        // Create configuration
        let configuration = AlarmManager.AlarmConfiguration<BananaClockMetadata>(
            countdownDuration: nil,
            schedule: schedule,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: snoozeIntent,
            sound: .default
        )
        
        // Schedule the alarm
        let alarm = try await alarmManager.schedule(id: id, configuration: configuration)
        print("✅ Scheduled regular alarm: \(alarm.id)")
        
        return alarm
    }
    
    func scheduleTimer(
        id: UUID = UUID(),
        duration: TimeInterval,
        title: String = "Timer"
    ) async throws -> AlarmKit.Alarm {
        guard isAuthorized else {
            throw AlarmKitError.notAuthorized
        }
        
        // Create countdown duration
        let countdownDuration = AlarmKit.Alarm.CountdownDuration(
            preAlert: duration,
            postAlert: nil
        )
        
        // Create metadata
        let metadata = BananaClockMetadata.timer()
        
        // Create presentation
        let presentation = createTimerPresentation(title: title)
        
        // Create attributes
        let attributes = AlarmAttributes<BananaClockMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: Color.bananaYellow
        )
        
        // Create App Intents for timer actions
        let stopIntent = StopTimerIntent()
        stopIntent.timerID = id.uuidString
        
        let repeatIntent = RepeatTimerIntent()
        repeatIntent.timerID = id.uuidString
        repeatIntent.duration = duration
        repeatIntent.title = title
        
        // Create configuration
        let configuration = AlarmManager.AlarmConfiguration<BananaClockMetadata>(
            countdownDuration: countdownDuration,
            schedule: nil,
            attributes: attributes,
            stopIntent: stopIntent,
            secondaryIntent: repeatIntent,
            sound: .default // Note: Custom sounds API changed in iOS 26+, using default for now
        )
        
        // Schedule the timer
        let alarm = try await alarmManager.schedule(id: id, configuration: configuration)
        print("✅ Scheduled timer: \(alarm.id)")
        
        return alarm
    }
    
    // MARK: - Alarm Management
    
    // MARK: - Legacy Compatibility Methods (for AlarmsViewModel)
    
    /// Schedule an alarm using the legacy Alarm model - wrapper for scheduleAIWakeUpAlarm
    func scheduleAlarm(_ alarm: BananaClockAlarm) async throws {
        guard alarm.isEnabled else { return }
        
        // Extract weekdays from alarm model
        let weekdays = Set(alarm.repeatDays.map { $0.rawValue })
        
        if alarm.isAIEnabled {
            _ = try await scheduleAIWakeUpAlarm(
                time: alarm.time,
                weekdays: weekdays,
                musicSelection: alarm.soundIdentifier,
                voicePreference: alarm.aiVoice.rawValue,
                customMessage: alarm.label
            )
        } else {
            _ = try await scheduleRegularAlarm(
                time: alarm.time,
                weekdays: weekdays,
                title: alarm.label
            )
        }
    }
    
    /// Cancel alarm with legacy parameter name
    func cancelAlarm(withId id: UUID) throws {
        try cancelAlarm(id: id)
    }
    
    func cancelAlarm(id: UUID) throws {
        try alarmManager.cancel(id: id)
        print("🗑️ Cancelled alarm: \(id)")
    }
    
    func stopAlarm(id: UUID) throws {
        try alarmManager.stop(id: id)
        print("⏹️ Stopped alarm: \(id)")
    }
    
    func pauseAlarm(id: UUID) throws {
        try alarmManager.pause(id: id)
        print("⏸️ Paused alarm: \(id)")
    }
    
    func resumeAlarm(id: UUID) throws {
        try alarmManager.resume(id: id)
        print("▶️ Resumed alarm: \(id)")
    }
    
    // MARK: - Observation
    
    private func startObservingAlarmUpdates() {
        guard !isObservingUpdates else { return }
        
        Task {
            isObservingUpdates = true
            print("👀 Starting to observe AlarmKit updates")
            
            for await incomingAlarms in alarmManager.alarmUpdates {
                await MainActor.run {
                    self.alarms = incomingAlarms
                    print("🔄 Received \(incomingAlarms.count) alarm updates")
                }
            }
        }
    }
    
    private func startObservingAuthorizationUpdates() {
        Task {
            for await authState in alarmManager.authorizationUpdates {
                await MainActor.run {
                    self.authorizationState = authState
                    print("🔐 Authorization state changed: \(authState)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createSchedule(time: Date, weekdays: Set<Int>) -> AlarmKit.Alarm.Schedule {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let hour = components.hour ?? 0
        let minute = components.minute ?? 0
        
        let alarmTime = AlarmKit.Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        
        let recurrence: AlarmKit.Alarm.Schedule.Relative.Recurrence
        if weekdays.isEmpty {
            recurrence = .never
        } else {
            // Convert Int to Locale.Weekday (1=Sunday, 2=Monday, etc.)
            let localeWeekdays = weekdays.compactMap { weekdayInt in
                switch weekdayInt {
                case 1: return Locale.Weekday.sunday
                case 2: return Locale.Weekday.monday  
                case 3: return Locale.Weekday.tuesday
                case 4: return Locale.Weekday.wednesday
                case 5: return Locale.Weekday.thursday
                case 6: return Locale.Weekday.friday
                case 7: return Locale.Weekday.saturday
                default: return nil
                }
            }
            // Create weekly recurrence
            recurrence = .weekly(localeWeekdays)
        }
        
        return .relative(.init(time: alarmTime, repeats: recurrence))
    }
    
    private func createAIWakeUpPresentation(title: String, metadata: BananaClockMetadata) -> AlarmPresentation {
        let stopButton = AlarmButton(
            text: LocalizedStringResource("I'm Awake!"),
            textColor: .white,
            systemImageName: "sun.max.fill"
        )
        
        let snoozeButton = AlarmButton(
            text: LocalizedStringResource("+10 min"),
            textColor: .bananaYellow,
            systemImageName: "clock.arrow.circlepath"
        )
        
        let alertContent = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: stopButton,
            secondaryButton: snoozeButton,
            secondaryButtonBehavior: .countdown
        )
        
        return AlarmPresentation(alert: alertContent)
    }
    
    private func createRegularAlarmPresentation(title: String) -> AlarmPresentation {
        let stopButton = AlarmButton(
            text: LocalizedStringResource("I'm Awake!"),
            textColor: .white,
            systemImageName: "sun.max.fill"
        )
        
        let snoozeButton = AlarmButton(
            text: LocalizedStringResource("+10 min"),
            textColor: .bananaYellow,
            systemImageName: "clock.arrow.circlepath"
        )
        
        let alertContent = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: stopButton,
            secondaryButton: snoozeButton,
            secondaryButtonBehavior: .countdown
        )
        
        return AlarmPresentation(alert: alertContent)
    }
    
    private func createTimerPresentation(title: String) -> AlarmPresentation {
        let stopButton = AlarmButton(
            text: LocalizedStringResource("Stop"),
            textColor: .white,
            systemImageName: "stop.circle.fill"
        )
        
        let repeatButton = AlarmButton(
            text: LocalizedStringResource("Repeat"),
            textColor: .bananaYellow,
            systemImageName: "arrow.clockwise"
        )
        
        let pauseButton = AlarmButton(
            text: LocalizedStringResource("Pause"),
            textColor: .bananaYellow,
            systemImageName: "pause.circle"
        )
        
        let resumeButton = AlarmButton(
            text: LocalizedStringResource("Resume"),
            textColor: .bananaYellow,
            systemImageName: "play.circle"
        )
        
        let alertContent = AlarmPresentation.Alert(
            title: LocalizedStringResource(stringLiteral: title),
            stopButton: stopButton,
            secondaryButton: repeatButton,
            secondaryButtonBehavior: .custom
        )
        
        let countdownContent = AlarmPresentation.Countdown(
            title: LocalizedStringResource(stringLiteral: title),
            pauseButton: pauseButton
        )
        
        let pausedContent = AlarmPresentation.Paused(
            title: LocalizedStringResource("Timer Paused"),
            resumeButton: resumeButton
        )
        
        return AlarmPresentation(
            alert: alertContent,
            countdown: countdownContent,
            paused: pausedContent
        )
    }
}

// MARK: - Error Types

enum AlarmKitError: LocalizedError {
    case notAuthorized
    case schedulingFailed(String)
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "AlarmKit authorization required"
        case .schedulingFailed(let message):
            return "Failed to schedule alarm: \(message)"
        case .invalidConfiguration:
            return "Invalid alarm configuration"
        }
    }
}

