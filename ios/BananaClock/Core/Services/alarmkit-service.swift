//
//  AlarmKitService.swift
//  BananaClock
//
//  AlarmKit integration service
//

import Foundation
// import AlarmKit  // Temporarily disabled - using placeholder types
import AVFoundation
import SwiftUI

@MainActor
class AlarmKitService: ObservableObject {
    static let shared = AlarmKitService()
    
    @Published var isAuthorized = false
    private var scheduledAlarms: [UUID: AlarmKitAlarm] = [:]
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async -> Bool {
        // For development, always return true since we're using placeholder implementation
        // This will be properly implemented when AlarmKit is available
        isAuthorized = true
        return true
        // isAuthorized = try await AlarmManager.shared.requestAuthorization()
        // return isAuthorized
    }
    
    private func checkAuthorizationStatus() {
        Task {
            // For development, always set as authorized since we're using placeholder implementation
            isAuthorized = true
            // isAuthorized = await AlarmManager.shared.authorizationStatus == .authorized
        }
    }
    
    // MARK: - Alarm Management
    
    func scheduleAlarm(_ alarm: Alarm) async throws {
        // For now, skip authorization check since we're using placeholder implementation
        // This will be properly implemented when AlarmKit is available
        // guard isAuthorized else {
        //     throw AlarmKitError.notAuthorized
        // }
        
        // Cancel existing alarm if any
        if scheduledAlarms[alarm.id] != nil {
            try await cancelAlarm(withId: alarm.id)
        }
        
        // Create alarm configuration
        var configuration = AlarmConfiguration(
            id: alarm.id.uuidString,
            label: alarm.label,
            scheduledDate: alarm.nextFireDate,
            sound: AlarmSound(rawValue: alarm.soundIdentifier) ?? .default,
            volume: Double(alarm.volume),
            vibrationEnabled: true, // Always enabled
            snoozeLength: TimeInterval((alarm.snoozeLength ?? 9) * 60),
            repeatSchedule: createRepeatSchedule(from: alarm.isWakeUpAlarm ? (alarm.wakeUpDays?.map { $0 } ?? []) : alarm.repeatDays)
        )
        
        // Handle AI wake-up if enabled
        if alarm.isAIEnabled {
            configuration.metadata = [
                "isAIEnabled": true,
                "alarmId": alarm.id.uuidString
            ]
        }
        
        // Schedule with AlarmKit (placeholder implementation)
        let alarmKitAlarm = try await AlarmManager.shared.scheduleAlarm(configuration)
        scheduledAlarms[alarm.id] = alarmKitAlarm
        
        print("Scheduled alarm: \(alarm.label) at \(alarm.nextFireDate)")
    }
    
    func cancelAlarm(withId id: UUID) async throws {
        guard let alarmKitAlarm = scheduledAlarms[id] else { return }
        
        try await AlarmManager.shared.cancelAlarm(alarmKitAlarm)
        scheduledAlarms.removeValue(forKey: id)
        
        print("Cancelled alarm with id: \(id)")
    }
    
    func cancelAllAlarms() async throws {
        for (id, _) in scheduledAlarms {
            try await cancelAlarm(withId: id)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createRepeatSchedule(from weekdays: [Alarm.Weekday]) -> AlarmRepeatSchedule? {
        guard !weekdays.isEmpty else { return nil }
        
        let alarmWeekdays = weekdays.compactMap { weekday -> AlarmWeekday? in
            switch weekday {
            case .sunday: return .sunday
            case .monday: return .monday
            case .tuesday: return .tuesday
            case .wednesday: return .wednesday
            case .thursday: return .thursday
            case .friday: return .friday
            case .saturday: return .saturday
            }
        }
        
        return AlarmRepeatSchedule(weekdays: Set(alarmWeekdays))
    }
    
    // MARK: - AI Wake-Up Handler
    
    func handleAIWakeUpAlarm(_ alarmId: String) async {
        // This will be called when an AI-enabled alarm fires
        // The actual audio playback is handled by AlarmKit
        
        // Log for analytics
        // await SupabaseService.shared.logAlarmFired(
        //     alarmId: alarmId,
        //     type: "ai_wakeup"
        // )
    }
}

// MARK: - Error Types
enum AlarmKitError: LocalizedError {
    case notAuthorized
    case schedulingFailed
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Alarm permissions not granted"
        case .schedulingFailed:
            return "Failed to schedule alarm"
        case .invalidConfiguration:
            return "Invalid alarm configuration"
        }
    }
}

// MARK: - AlarmKit Extensions
// Note: convenience initializers are not allowed in structs
// This will be replaced with proper AlarmKit implementation

// Note: AlarmKit types are placeholders until the actual framework is available
// These will be replaced with the real AlarmKit imports

// MARK: - Placeholder Types (Remove when AlarmKit is available)
struct AlarmManager {
    static let shared = AlarmManager()
    
    enum AuthorizationStatus {
        case notDetermined, denied, authorized
    }
    
    var authorizationStatus: AuthorizationStatus { .notDetermined }
    
    func requestAuthorization() async throws -> Bool { true }
    func scheduleAlarm(_ configuration: AlarmConfiguration) async throws -> AlarmKitAlarm { AlarmKitAlarm() }
    func cancelAlarm(_ alarm: AlarmKitAlarm) async throws {}
}

struct AlarmConfiguration {
    let id: String
    let label: String
    let scheduledDate: Date
    var sound: AlarmSound?
    var volume: Double = 0.7
    var vibrationEnabled: Bool = true
    var snoozeLength: TimeInterval = 540
    var repeatSchedule: AlarmRepeatSchedule?
    var metadata: [String: Any] = [:]
}

struct AlarmKitAlarm {}
// Note: AlarmSound is defined in alarm-sound-model.swift
struct AlarmRepeatSchedule { let weekdays: Set<AlarmWeekday> }
enum AlarmWeekday { case sunday, monday, tuesday, wednesday, thursday, friday, saturday }