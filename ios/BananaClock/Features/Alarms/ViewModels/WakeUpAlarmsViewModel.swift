//
//  WakeUpAlarmsViewModel.swift
//  BananaClock
//
//  View model for wake-up alarm management
//

import SwiftUI
import Foundation
import Combine

@MainActor
class WakeUpAlarmsViewModel: ObservableObject {
    @Published var wakeUpSchedules: [Alarm] = []
    @Published var nextVisibleWakeUpAlarm: Alarm?
    @Published var userPreferences: UserPreferences?
    @Published var isLoading = false
    @Published var error: Error?
    
    // Next Alarm State
    @Published var nextAlarmState: NextAlarmState = .noAlarms
    @Published var tomorrowsAlarmText: String = "No alarm"
    
    private var refreshTimer: Foundation.Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Computed properties
    var occupiedDays: Set<Alarm.Weekday> {
        wakeUpSchedules.flatMap { $0.wakeUpDays ?? [] }.reduce(into: Set<Alarm.Weekday>()) { $0.insert($1) }
    }
    
    func getOccupiedDays(excluding alarm: Alarm) -> Set<Alarm.Weekday> {
        wakeUpSchedules
            .filter { $0.id != alarm.id }
            .flatMap { $0.wakeUpDays ?? [] }
            .reduce(into: Set<Alarm.Weekday>()) { $0.insert($1) }
    }
    
    init() {
        // Set up timer to refresh next alarm visibility
        startRefreshTimer()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    
    func loadWakeUpAlarms() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load wake-up alarms from CoreData
            let alarms = try CoreDataManager.shared.fetchAlarms()
            print("DEBUG: Total alarms loaded: \(alarms.count)")
            print("DEBUG: All alarms: \(alarms.map { "\($0.label) (isWakeUp: \($0.isWakeUpAlarm))" })")
            
            wakeUpSchedules = alarms.filter { $0.isWakeUpAlarm }
            print("DEBUG: Wake-up schedules found: \(wakeUpSchedules.count)")
            print("DEBUG: Wake-up schedules: \(wakeUpSchedules.map { "\($0.label) at \($0.time)" })")
            
            // Load user preferences
            userPreferences = try? CoreDataManager.shared.fetchUserPreferences()
            
            // Update next visible alarm
            updateNextVisibleAlarm()
            
            // Update next alarm state
            updateNextAlarmState()
        } catch {
            self.error = error
            print("Failed to load wake-up alarms: \(error)")
        }
    }
    
    func addSchedule(_ schedule: Alarm) async {
        do {
            // Ensure it's marked as wake-up alarm
            var newSchedule = schedule
            newSchedule.isWakeUpAlarm = true
            newSchedule.label = "Wake Up"
            
            // Save to CoreData
            _ = try CoreDataManager.shared.createAlarm(newSchedule)
            
            // Reload
            await loadWakeUpAlarms()
            
            // Schedule with AlarmKit
            await scheduleAlarmKitAlarms()
        } catch {
            self.error = error
            print("Failed to add wake-up schedule: \(error)")
        }
    }
    
    func updateSchedule(_ schedule: Alarm) async {
        print("DEBUG: WakeUpAlarmsViewModel.updateSchedule - starting update for alarm \(schedule.id)")
        print("DEBUG: - isEnabled: \(schedule.isEnabled)")
        print("DEBUG: - isAIEnabled: \(schedule.isAIEnabled)")
        print("DEBUG: - time: \(schedule.time)")
        print("DEBUG: - soundIdentifier: \(schedule.soundIdentifier)")
        print("DEBUG: - snoozeLength: \(schedule.snoozeLength?.description ?? "nil")")
        print("DEBUG: - volume: \(schedule.volume)")
        
        do {
            // Save to CoreData
            try CoreDataManager.shared.updateAlarm(schedule)
            print("DEBUG: WakeUpAlarmsViewModel.updateSchedule - CoreData update successful")
            
            // Reload
            await loadWakeUpAlarms()
            print("DEBUG: WakeUpAlarmsViewModel.updateSchedule - reload completed")
            
            // Reschedule only this specific alarm with AlarmKit
            await scheduleSpecificAlarm(schedule)
            print("DEBUG: WakeUpAlarmsViewModel.updateSchedule - AlarmKit scheduling completed")
        } catch {
            self.error = error
            print("ERROR: WakeUpAlarmsViewModel.updateSchedule - Failed to update wake-up schedule: \(error)")
        }
    }
    
    func deleteSchedule(_ schedule: Alarm) async {
        do {
            // Delete from CoreData
            try CoreDataManager.shared.deleteAlarm(schedule.id)
            
            // Reload
            await loadWakeUpAlarms()
            
            // Cancel the deleted alarm from AlarmKit
            try? AlarmKitService.shared.cancelAlarm(id: schedule.id)
        } catch {
            self.error = error
            print("Failed to delete wake-up schedule: \(error)")
        }
    }
    
    func deleteSchedules(at indexSet: IndexSet) async {
        for index in indexSet {
            if index < wakeUpSchedules.count {
                await deleteSchedule(wakeUpSchedules[index])
            }
        }
    }
    
    func toggleAlarm(_ alarm: Alarm, isEnabled: Bool) async {
        print("DEBUG: WakeUpAlarmsViewModel.toggleAlarm called for alarm \(alarm.id), newEnabled: \(isEnabled)")
        var updatedAlarm = alarm
        updatedAlarm.isEnabled = isEnabled
        await updateSchedule(updatedAlarm)
        print("DEBUG: WakeUpAlarmsViewModel.toggleAlarm completed")
    }
    
    func updateAISettings(_ preferences: UserPreferences) async {
        do {
            // Save preferences
            try CoreDataManager.shared.saveUserPreferences(preferences)
            
            // Update local copy
            self.userPreferences = preferences
            
            // Apply AI settings to all wake-up alarms
            for schedule in wakeUpSchedules {
                var updatedSchedule = schedule
                updatedSchedule.aiVoice = preferences.voice
                updatedSchedule.aiWeatherEnabled = preferences.weatherEnabled
                updatedSchedule.aiHeadlinesCategories = Set(preferences.headlinesCategories.compactMap { HeadlinesCategory(rawValue: $0) })
                updatedSchedule.aiSportsCategories = Set(preferences.sportsCategories.compactMap { SportsCategory(rawValue: $0) })
                updatedSchedule.aiPreferredName = preferences.name
                
                try CoreDataManager.shared.updateAlarm(updatedSchedule)
            }
            
            // Sync with Supabase
            if SupabaseService.shared.isAuthenticated {
                _ = try? await SupabaseService.shared.syncUserPreferences()
            }
            
            // Reload
            await loadWakeUpAlarms()
        } catch {
            self.error = error
            print("Failed to update AI settings: \(error)")
        }
    }
    
    // MARK: - Private Methods
    
    private func updateNextVisibleAlarm() {
        let now = Date()
        print("DEBUG: WakeUpAlarmsViewModel.updateNextVisibleAlarm - starting at \(now)")
        
        // Use same logic as updateNextAlarmState for consistency
        // nextVisibleWakeUpAlarm should align with what's shown on alarm page
        
        // If no wake-up alarms exist
        if wakeUpSchedules.isEmpty {
            print("DEBUG: WakeUpAlarmsViewModel.updateNextVisibleAlarm - no wake-up schedules found")
            nextVisibleWakeUpAlarm = nil
            return
        }
        
        // Get today's and tomorrow's alarms (consistent with nextAlarmState logic)
        let todaysAlarm = getTodaysAlarm()
        let tomorrowsAlarm = getTomorrowsAlarm()
        
        print("DEBUG: WakeUpAlarmsViewModel.updateNextVisibleAlarm - Today's alarm: \(todaysAlarm?.label ?? "none")")
        print("DEBUG: WakeUpAlarmsViewModel.updateNextVisibleAlarm - Tomorrow's alarm: \(tomorrowsAlarm?.label ?? "none")")
        
        // Determine which alarm should be visible for editing (matches display logic)
        if let todaysAlarm = todaysAlarm {
            if !hasTodaysAlarmPassed(alarm: todaysAlarm) {
                // Today's alarm hasn't passed - make it visible for editing
                print("DEBUG: WakeUpAlarmsViewModel.updateNextVisibleAlarm - Today's alarm is next, setting as visible")
                nextVisibleWakeUpAlarm = todaysAlarm
            } else {
                // Today's alarm has passed - check tomorrow's with 24-hour constraint
                if let tomorrowsAlarm = tomorrowsAlarm, isAlarmWithin24Hours(tomorrowsAlarm) {
                    print("DEBUG: WakeUpAlarmsViewModel.updateNextVisibleAlarm - Today's alarm passed, showing tomorrow's for editing (within 24h)")
                    nextVisibleWakeUpAlarm = tomorrowsAlarm
                } else {
                    // No tomorrow alarm or beyond 24h, keep today's visible for editing
                    print("DEBUG: WakeUpAlarmsViewModel.updateNextVisibleAlarm - Today's alarm passed, no tomorrow alarm within 24h, keeping today's for editing")
                    nextVisibleWakeUpAlarm = todaysAlarm
                }
            }
        } else if let tomorrowsAlarm = tomorrowsAlarm, isAlarmWithin24Hours(tomorrowsAlarm) {
            // No today alarm, show tomorrow's if within 24 hours
            print("DEBUG: WakeUpAlarmsViewModel.updateNextVisibleAlarm - No today alarm, showing tomorrow's (within 24h)")
            nextVisibleWakeUpAlarm = tomorrowsAlarm
        } else {
            // No alarms today or tomorrow
            print("DEBUG: WakeUpAlarmsViewModel.updateNextVisibleAlarm - No alarms today or tomorrow")
            nextVisibleWakeUpAlarm = nil
        }
    }
    
    private func updateNextAlarmState() {
        let now = Date()
        print("DEBUG: updateNextAlarmState - wakeUpSchedules count: \(wakeUpSchedules.count)")
        
        // If no wake-up alarms exist
        if wakeUpSchedules.isEmpty {
            print("DEBUG: No wake-up schedules found, setting noAlarms state")
            nextAlarmState = .noAlarms
            tomorrowsAlarmText = "No alarm"
            return
        }
        
        // Get today's and tomorrow's alarms
        let todaysAlarm = getTodaysAlarm()
        let tomorrowsAlarm = getTomorrowsAlarm()
        
        print("DEBUG: Today's alarm: \(todaysAlarm?.label ?? "none")")
        print("DEBUG: Tomorrow's alarm: \(tomorrowsAlarm?.label ?? "none")")
        
        // Determine next alarm state based on today/tomorrow only
        if let todaysAlarm = todaysAlarm {
            if !hasTodaysAlarmPassed(alarm: todaysAlarm) {
                // Today's alarm hasn't passed - show it as next
                print("DEBUG: Today's alarm hasn't passed, setting as nextAlarm")
                nextAlarmState = .nextAlarm(todaysAlarm)
            } else {
                // Today's alarm has passed - check tomorrow's alarm with 24-hour constraint
                if let tomorrowsAlarm = tomorrowsAlarm {
                    if isAlarmWithin24Hours(tomorrowsAlarm) {
                        // Show tomorrow's alarm (within 24 hours)
                        print("DEBUG: Today's alarm has passed, showing tomorrow's alarm as next (within 24h)")
                        nextAlarmState = .nextAlarm(tomorrowsAlarm)
                    } else {
                        // Tomorrow's alarm exists but is more than 24 hours away
                        print("DEBUG: Today's alarm has passed, tomorrow's alarm beyond 24h - showing No Alarm")
                        nextAlarmState = .noAlarms
                    }
                } else {
                    // No tomorrow alarm
                    print("DEBUG: Today's alarm has passed, no tomorrow alarm - showing No Alarm")
                    nextAlarmState = .noAlarms
                }
            }
        } else if let tomorrowsAlarm = tomorrowsAlarm {
            // No today alarm, check tomorrow's alarm with 24-hour constraint
            if isAlarmWithin24Hours(tomorrowsAlarm) {
                print("DEBUG: No today alarm, showing tomorrow's alarm as next (within 24h)")
                nextAlarmState = .nextAlarm(tomorrowsAlarm)
            } else {
                print("DEBUG: No today alarm, tomorrow's alarm beyond 24h - showing No Alarm")
                nextAlarmState = .noAlarms
            }
        } else {
            // No alarms today or tomorrow
            print("DEBUG: No alarms today or tomorrow")
            nextAlarmState = .noAlarms
        }
        
        // Update tomorrow's alarm text
        updateTomorrowsAlarmText()
    }
    
    // MARK: - Helper Methods for Today/Tomorrow Logic
    
    private func getTodaysAlarm() -> Alarm? {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        guard let todayDay = Alarm.Weekday(rawValue: todayWeekday) else { return nil }
        
        return wakeUpSchedules.first { alarm in
            let alarmDays = alarm.wakeUpDays ?? Set(alarm.repeatDays)
            return alarmDays.contains(todayDay)
        }
    }
    
    private func getTomorrowsAlarm() -> Alarm? {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)
        guard let tomorrowDay = Alarm.Weekday(rawValue: tomorrowWeekday) else { return nil }
        
        return wakeUpSchedules.first { alarm in
            let alarmDays = alarm.wakeUpDays ?? Set(alarm.repeatDays)
            return alarmDays.contains(tomorrowDay)
        }
    }
    
    private func hasTodaysAlarmPassed(alarm: Alarm) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        let todayAlarmTime = calendar.date(
            bySettingHour: calendar.component(.hour, from: alarm.time),
            minute: calendar.component(.minute, from: alarm.time),
            second: 0,
            of: now
        ) ?? now
        
        return now > todayAlarmTime
    }
    
    private func isAlarmWithin24Hours(_ alarm: Alarm) -> Bool {
        let calendar = Calendar.current
        let now = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        
        // Create tomorrow's alarm time
        let tomorrowAlarmTime = calendar.date(
            bySettingHour: calendar.component(.hour, from: alarm.time),
            minute: calendar.component(.minute, from: alarm.time),
            second: 0,
            of: tomorrow
        ) ?? tomorrow
        
        // Calculate hours until alarm
        let hoursUntilAlarm = tomorrowAlarmTime.timeIntervalSince(now) / 3600
        
        print("DEBUG: isAlarmWithin24Hours - Hours until tomorrow's alarm: \(hoursUntilAlarm)")
        
        // Return true if alarm is within 24 hours (23:59:59)
        return hoursUntilAlarm < 24.0
    }
    
    private func updateTomorrowsAlarmText() {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)
        
        guard let tomorrowDay = Alarm.Weekday(rawValue: tomorrowWeekday) else {
            tomorrowsAlarmText = "No alarm"
            return
        }
        
        // Find wake-up alarms scheduled for tomorrow
        let tomorrowsAlarms = wakeUpSchedules.filter { alarm in
            let alarmDays = alarm.wakeUpDays ?? Set(alarm.repeatDays)
            return alarmDays.contains(tomorrowDay)
        }
        
        if let tomorrowsAlarm = tomorrowsAlarms.first {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            tomorrowsAlarmText = formatter.string(from: tomorrowsAlarm.time)
        } else {
            tomorrowsAlarmText = "No alarm"
        }
    }
    
    private func startRefreshTimer() {
        // Update every minute to check alarm visibility
        refreshTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            Task { @MainActor in
                self.updateNextVisibleAlarm()
                self.updateNextAlarmState()
            }
        }
    }
    
    private func scheduleAlarmKitAlarms() async {
        print("DEBUG: WakeUpAlarmsViewModel.scheduleAlarmKitAlarms - starting")
        
        // First cancel any existing alarms
        for alarm in wakeUpSchedules {
            do {
                try AlarmKitService.shared.cancelAlarm(id: alarm.id)
            } catch {
                print("Warning: Failed to cancel existing alarm: \(error)")
                // Continue with scheduling - don't throw here
            }
        }
        
        // Then schedule enabled alarms
        for alarm in wakeUpSchedules where alarm.isEnabled {
            do {
                try await AlarmKitService.shared.scheduleAlarm(alarm)
                print("✅ Scheduled wake-up alarm: \(alarm.id)")
            } catch {
                print("❌ Failed to schedule wake-up alarm \(alarm.id): \(error)")
            }
        }
        
        print("DEBUG: WakeUpAlarmsViewModel.scheduleAlarmKitAlarms - completed")
    }
    
    private func scheduleSpecificAlarm(_ alarm: Alarm) async {
        print("DEBUG: WakeUpAlarmsViewModel.scheduleSpecificAlarm - scheduling alarm \(alarm.id)")
        
        // Cancel existing alarm first
        do {
            try AlarmKitService.shared.cancelAlarm(id: alarm.id)
        } catch {
            print("Warning: Failed to cancel existing alarm: \(error)")
            // Continue with scheduling - don't throw here
        }
        
        // Schedule if enabled
        if alarm.isEnabled {
            do {
                try await AlarmKitService.shared.scheduleAlarm(alarm)
                print("✅ Scheduled specific wake-up alarm: \(alarm.id)")
            } catch {
                print("❌ Failed to schedule specific wake-up alarm \(alarm.id): \(error)")
            }
        }
        
        print("DEBUG: WakeUpAlarmsViewModel.scheduleSpecificAlarm - completed")
    }
}

// MARK: - Next Alarm State

enum NextAlarmState {
    case nextAlarm(Alarm) // Today's upcoming alarm or tomorrow's alarm
    case previousAlarm(Alarm) // Legacy case - not used in current logic
    case noAlarms // No wake-up alarm configured for today or tomorrow
}