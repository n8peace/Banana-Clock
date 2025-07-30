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
        do {
            // Save to CoreData
            try CoreDataManager.shared.updateAlarm(schedule)
            
            // Reload
            await loadWakeUpAlarms()
            
            // Reschedule with AlarmKit
            await scheduleAlarmKitAlarms()
        } catch {
            self.error = error
            print("Failed to update wake-up schedule: \(error)")
        }
    }
    
    func deleteSchedule(_ schedule: Alarm) async {
        do {
            // Delete from CoreData
            try CoreDataManager.shared.deleteAlarm(schedule.id)
            
            // Reload
            await loadWakeUpAlarms()
            
            // Reschedule with AlarmKit
            await scheduleAlarmKitAlarms()
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
        
        // Find all wake-up alarms (including disabled ones)
        let allAlarms = wakeUpSchedules
        
        // Find the next alarm
        let nextAlarm = allAlarms
            .map { alarm -> (alarm: Alarm, fireDate: Date) in
                (alarm, alarm.nextFireDate)
            }
            .sorted { $0.fireDate < $1.fireDate }
            .first
        
        guard let next = nextAlarm else {
            nextVisibleWakeUpAlarm = nil
            return
        }
        
        // Check if today's alarm has already fired
        let calendar = Calendar.current
        let todaysAlarms = allAlarms.filter { alarm in
            let alarmDays = alarm.wakeUpDays ?? Set(alarm.repeatDays)
            let todayWeekday = calendar.component(.weekday, from: now)
            guard let todayDay = Alarm.Weekday(rawValue: todayWeekday) else { return false }
            return alarmDays.contains(todayDay)
        }
        
        if let todaysAlarm = todaysAlarms.first {
            let todayFireDate = calendar.date(bySettingHour: calendar.component(.hour, from: todaysAlarm.time),
                                            minute: calendar.component(.minute, from: todaysAlarm.time),
                                            second: 0,
                                            of: now) ?? now
            
            let hoursSinceAlarm = now.timeIntervalSince(todayFireDate) / 3600
            
            // If less than 6 hours since today's alarm, don't show next
            if hoursSinceAlarm >= 0 && hoursSinceAlarm < 6 {
                nextVisibleWakeUpAlarm = nil
                return
            }
        }
        
        // Check if next alarm is within 18 hours
        let hoursUntilAlarm = next.fireDate.timeIntervalSince(now) / 3600
        
        if hoursUntilAlarm <= 18 {
            nextVisibleWakeUpAlarm = next.alarm
        } else {
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
        
        // Find the next wake-up alarm
        let nextAlarm = wakeUpSchedules
            .map { alarm -> (alarm: Alarm, fireDate: Date) in
                let fireDate = alarm.nextFireDate
                print("DEBUG: Alarm \(alarm.label) at \(alarm.time) -> nextFireDate: \(fireDate)")
                return (alarm, fireDate)
            }
            .sorted { $0.fireDate < $1.fireDate }
            .first
        
        guard let next = nextAlarm else {
            print("DEBUG: No next alarm found, setting noAlarms state")
            nextAlarmState = .noAlarms
            tomorrowsAlarmText = "No alarm"
            return
        }
        
        let hoursUntilAlarm = next.fireDate.timeIntervalSince(now) / 3600
        print("DEBUG: Next alarm: \(next.alarm.label) at \(next.fireDate), hours until: \(hoursUntilAlarm)")
        
        // Check if this alarm has already fired today
        let calendar = Calendar.current
        let todayFireDate = calendar.date(bySettingHour: calendar.component(.hour, from: next.alarm.time),
                                        minute: calendar.component(.minute, from: next.alarm.time),
                                        second: 0,
                                        of: now) ?? now
        
        let hoursSinceTodayAlarm = now.timeIntervalSince(todayFireDate) / 3600
        print("DEBUG: Hours since today's alarm: \(hoursSinceTodayAlarm)")
        
        // Determine state based on whether alarm has fired today
        if hoursSinceTodayAlarm >= 0 && hoursSinceTodayAlarm < 6 {
            // Alarm fired today within last 6 hours - show as previous
            print("DEBUG: Alarm fired today, setting previousAlarm state")
            nextAlarmState = .previousAlarm(next.alarm)
        } else {
            // Alarm hasn't fired today or fired more than 6 hours ago - show as next
            print("DEBUG: Alarm hasn't fired today or fired long ago, setting nextAlarm state")
            nextAlarmState = .nextAlarm(next.alarm)
        }
        
        // Update tomorrow's alarm text
        updateTomorrowsAlarmText()
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
        // This will be implemented when AlarmKit service is integrated
        // For now, just log
        print("Would schedule \(wakeUpSchedules.count) wake-up alarms with AlarmKit")
    }
}

// MARK: - Next Alarm State

enum NextAlarmState {
    case nextAlarm(Alarm) // Within 12 hours
    case previousAlarm(Alarm) // Beyond 12 hours
    case noAlarms // No wake-up alarm configured
}