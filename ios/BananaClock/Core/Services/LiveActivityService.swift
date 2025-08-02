//
//  LiveActivityService.swift
//  BananaClock
//
//  Service for managing Live Activities across Dynamic Island and Lock Screen
//

import Foundation
import ActivityKit
import SwiftUI

@MainActor
class LiveActivityService: ObservableObject {
    static let shared = LiveActivityService()
    
    // Published properties for tracking active activities
    @Published var activeTimerActivities: [Activity<TimerActivityAttributes>] = []
    @Published var activeStopwatchActivities: [Activity<StopwatchActivityAttributes>] = []
    @Published var activeAlarmActivities: [Activity<AlarmActivityAttributes>] = []
    
    // Internal tracking
    private var timerUpdateTasks: [String: Task<Void, Never>] = [:]
    private var stopwatchUpdateTasks: [String: Task<Void, Never>] = [:]
    private var alarmUpdateTasks: [String: Task<Void, Never>] = [:]
    
    private init() {
        // Monitor activity state changes
        startMonitoringActivityUpdates()
    }
    
    // MARK: - Activity Availability
    
    var areActivitiesSupported: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    func requestActivityAuthorization() async -> Bool {
        let authInfo = ActivityAuthorizationInfo()
        return authInfo.areActivitiesEnabled
    }
    
    // MARK: - Timer Live Activities
    
    func startTimerActivity(
        timerID: UUID,
        duration: TimeInterval,
        title: String,
        soundIdentifier: String = "timer_complete"
    ) async throws {
        guard areActivitiesSupported else {
            print("⚠️ Live Activities not supported on this device")
            return
        }
        
        let timerIDString = timerID.uuidString
        
        // End any existing timer activity for this ID
        await endTimerActivity(timerID: timerID)
        
        let attributes = TimerActivityAttributes(
            timerID: timerIDString,
            originalDuration: duration,
            title: title,
            soundIdentifier: soundIdentifier
        )
        
        let initialState = TimerActivityAttributes.ContentState.running(
            remainingTime: duration,
            totalDuration: duration,
            startTime: Date()
        )
        
        do {
            let activity = try Activity<TimerActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            activeTimerActivities.append(activity)
            print("✅ Started timer Live Activity: \(timerIDString)")
            
            // Start automatic updates
            startTimerUpdates(activity: activity, startTime: Date(), totalDuration: duration)
            
        } catch {
            print("❌ Failed to start timer Live Activity: \(error)")
            throw LiveActivityError.failedToStart(error.localizedDescription)
        }
    }
    
    func updateTimerActivity(timerID: UUID, remainingTime: TimeInterval, isRunning: Bool, isPaused: Bool) async {
        let timerIDString = timerID.uuidString
        
        guard let activity = activeTimerActivities.first(where: { $0.attributes.timerID == timerIDString }) else {
            print("⚠️ No active timer activity found for ID: \(timerIDString)")
            return
        }
        
        let newState: TimerActivityAttributes.ContentState
        if isPaused {
            newState = TimerActivityAttributes.ContentState.paused(
                remainingTime: remainingTime,
                totalDuration: activity.attributes.originalDuration,
                startTime: activity.content.state.startTime
            )
        } else if isRunning {
            newState = TimerActivityAttributes.ContentState.running(
                remainingTime: remainingTime,
                totalDuration: activity.attributes.originalDuration,
                startTime: activity.content.state.startTime
            )
        } else {
            newState = TimerActivityAttributes.ContentState.completed(
                totalDuration: activity.attributes.originalDuration,
                startTime: activity.content.state.startTime
            )
        }
        
        await activity.update(.init(state: newState, staleDate: nil))
        
        // Update task management
        if isPaused || !isRunning {
            timerUpdateTasks[timerIDString]?.cancel()
            timerUpdateTasks.removeValue(forKey: timerIDString)
        }
    }
    
    func endTimerActivity(timerID: UUID) async {
        let timerIDString = timerID.uuidString
        
        // Cancel update task
        timerUpdateTasks[timerIDString]?.cancel()
        timerUpdateTasks.removeValue(forKey: timerIDString)
        
        // Find and end activity
        if let activityIndex = activeTimerActivities.firstIndex(where: { $0.attributes.timerID == timerIDString }) {
            let activity = activeTimerActivities[activityIndex]
            
            let finalState = TimerActivityAttributes.ContentState.completed(
                totalDuration: activity.attributes.originalDuration,
                startTime: activity.content.state.startTime
            )
            
            await activity.update(.init(state: finalState, staleDate: Date().addingTimeInterval(5)))
            
            activeTimerActivities.remove(at: activityIndex)
            print("✅ Ended timer Live Activity: \(timerIDString)")
        }
    }
    
    // MARK: - Stopwatch Live Activities
    
    func startStopwatchActivity(stopwatchID: UUID) async throws {
        guard areActivitiesSupported else {
            print("⚠️ Live Activities not supported on this device")
            return
        }
        
        let stopwatchIDString = stopwatchID.uuidString
        
        // End any existing stopwatch activity
        await endStopwatchActivity(stopwatchID: stopwatchID)
        
        let attributes = StopwatchActivityAttributes(
            stopwatchID: stopwatchIDString,
            sessionStartTime: Date()
        )
        
        let initialState = StopwatchActivityAttributes.ContentState.running(
            elapsedTime: 0,
            lapCount: 0,
            startTime: Date()
        )
        
        do {
            let activity = try Activity<StopwatchActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            activeStopwatchActivities.append(activity)
            print("✅ Started stopwatch Live Activity: \(stopwatchIDString)")
            
            // Start automatic updates
            startStopwatchUpdates(activity: activity, startTime: Date())
            
        } catch {
            print("❌ Failed to start stopwatch Live Activity: \(error)")
            throw LiveActivityError.failedToStart(error.localizedDescription)
        }
    }
    
    func updateStopwatchActivity(
        stopwatchID: UUID,
        elapsedTime: TimeInterval,
        isRunning: Bool,
        lapCount: Int,
        lastLapTime: TimeInterval? = nil
    ) async {
        let stopwatchIDString = stopwatchID.uuidString
        
        guard let activity = activeStopwatchActivities.first(where: { $0.attributes.stopwatchID == stopwatchIDString }) else {
            print("⚠️ No active stopwatch activity found for ID: \(stopwatchIDString)")
            return
        }
        
        let newState: StopwatchActivityAttributes.ContentState
        if isRunning {
            newState = StopwatchActivityAttributes.ContentState.running(
                elapsedTime: elapsedTime,
                lapCount: lapCount,
                lastLapTime: lastLapTime,
                startTime: activity.content.state.startTime
            )
        } else {
            newState = StopwatchActivityAttributes.ContentState.stopped(
                elapsedTime: elapsedTime,
                lapCount: lapCount,
                lastLapTime: lastLapTime,
                startTime: activity.content.state.startTime
            )
        }
        
        await activity.update(.init(state: newState, staleDate: nil))
        
        // Update task management
        if !isRunning {
            stopwatchUpdateTasks[stopwatchIDString]?.cancel()
            stopwatchUpdateTasks.removeValue(forKey: stopwatchIDString)
        }
    }
    
    func endStopwatchActivity(stopwatchID: UUID) async {
        let stopwatchIDString = stopwatchID.uuidString
        
        // Cancel update task
        stopwatchUpdateTasks[stopwatchIDString]?.cancel()
        stopwatchUpdateTasks.removeValue(forKey: stopwatchIDString)
        
        // Find and end activity
        if let activityIndex = activeStopwatchActivities.firstIndex(where: { $0.attributes.stopwatchID == stopwatchIDString }) {
            let activity = activeStopwatchActivities[activityIndex]
            
            let finalState = StopwatchActivityAttributes.ContentState.stopped(
                elapsedTime: activity.content.state.elapsedTime,
                lapCount: activity.content.state.lapCount,
                lastLapTime: activity.content.state.lastLapTime,
                startTime: activity.content.state.startTime
            )
            
            await activity.update(.init(state: finalState, staleDate: Date().addingTimeInterval(5)))
            
            activeStopwatchActivities.remove(at: activityIndex)
            print("✅ Ended stopwatch Live Activity: \(stopwatchIDString)")
        }
    }
    
    // MARK: - Alarm Live Activities
    
    func startAlarmActivity(
        alarmID: UUID,
        alarmType: AlarmType,
        scheduledTime: Date,
        title: String,
        musicSelection: String? = nil,
        voicePreference: String? = nil,
        wakeUpContent: String? = nil
    ) async throws {
        guard areActivitiesSupported else {
            print("⚠️ Live Activities not supported on this device")
            return
        }
        
        let alarmIDString = alarmID.uuidString
        
        // End any existing alarm activity
        await endAlarmActivity(alarmID: alarmID)
        
        let attributes = AlarmActivityAttributes(
            alarmID: alarmIDString,
            alarmType: alarmType,
            scheduledTime: scheduledTime,
            alarmTitle: title,
            musicSelection: musicSelection,
            voicePreference: voicePreference
        )
        
        let initialState: AlarmActivityAttributes.ContentState
        if alarmType == .aiWakeUp && wakeUpContent != nil {
            initialState = AlarmActivityAttributes.ContentState.aiWakeUpPlaying(
                wakeUpContent: wakeUpContent!
            )
        } else {
            initialState = AlarmActivityAttributes.ContentState.ringing()
        }
        
        do {
            let activity = try Activity<AlarmActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            
            activeAlarmActivities.append(activity)
            print("✅ Started alarm Live Activity: \(alarmIDString)")
            
        } catch {
            print("❌ Failed to start alarm Live Activity: \(error)")
            throw LiveActivityError.failedToStart(error.localizedDescription)
        }
    }
    
    func showSnoozeCountdown(alarmID: UUID, snoozeMinutes: Int, snoozeCount: Int = 1) async {
        let alarmIDString = alarmID.uuidString
        
        guard let activity = activeAlarmActivities.first(where: { $0.attributes.alarmID == alarmIDString }) else {
            print("⚠️ No active alarm activity found for ID: \(alarmIDString)")
            return
        }
        
        let snoozeTime = TimeInterval(snoozeMinutes * 60)
        let newState = AlarmActivityAttributes.ContentState.snoozed(
            snoozeTime: snoozeTime,
            snoozeCount: snoozeCount
        )
        
        await activity.update(.init(state: newState, staleDate: nil))
        
        // Start snooze countdown updates
        startSnoozeCountdown(activity: activity, totalSnoozeTime: snoozeTime)
    }
    
    func dismissAlarmActivity(alarmID: UUID) async {
        let alarmIDString = alarmID.uuidString
        
        guard let activity = activeAlarmActivities.first(where: { $0.attributes.alarmID == alarmIDString }) else {
            print("⚠️ No active alarm activity found for ID: \(alarmIDString)")
            return
        }
        
        let dismissedState = AlarmActivityAttributes.ContentState.dismissed()
        await activity.update(.init(state: dismissedState, staleDate: Date().addingTimeInterval(3)))
        
        // Remove from active activities after a delay
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            await endAlarmActivity(alarmID: alarmID)
        }
    }
    
    func endAlarmActivity(alarmID: UUID) async {
        let alarmIDString = alarmID.uuidString
        
        // Cancel update task
        alarmUpdateTasks[alarmIDString]?.cancel()
        alarmUpdateTasks.removeValue(forKey: alarmIDString)
        
        // Find and end activity
        if let activityIndex = activeAlarmActivities.firstIndex(where: { $0.attributes.alarmID == alarmIDString }) {
            let activity = activeAlarmActivities[activityIndex]
            await activity.end(activity.content, dismissalPolicy: .immediate)
            activeAlarmActivities.remove(at: activityIndex)
            print("✅ Ended alarm Live Activity: \(alarmIDString)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func startTimerUpdates(activity: Activity<TimerActivityAttributes>, startTime: Date, totalDuration: TimeInterval) {
        let timerID = activity.attributes.timerID
        
        timerUpdateTasks[timerID] = Task {
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, totalDuration - elapsed)
                
                if remaining <= 0 {
                    // Timer completed
                    let completedState = TimerActivityAttributes.ContentState.completed(
                        totalDuration: totalDuration,
                        startTime: startTime
                    )
                    await activity.update(.init(state: completedState, staleDate: Date().addingTimeInterval(5)))
                    break
                } else {
                    // Update remaining time
                    let runningState = TimerActivityAttributes.ContentState.running(
                        remainingTime: remaining,
                        totalDuration: totalDuration,
                        startTime: startTime
                    )
                    await activity.update(.init(state: runningState, staleDate: nil))
                }
                
                // Update every second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private func startStopwatchUpdates(activity: Activity<StopwatchActivityAttributes>, startTime: Date) {
        let stopwatchID = activity.attributes.stopwatchID
        
        stopwatchUpdateTasks[stopwatchID] = Task {
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                
                let runningState = StopwatchActivityAttributes.ContentState.running(
                    elapsedTime: elapsed,
                    lapCount: activity.content.state.lapCount,
                    lastLapTime: activity.content.state.lastLapTime,
                    startTime: startTime
                )
                
                await activity.update(.init(state: runningState, staleDate: nil))
                
                // Update every 0.1 seconds for centiseconds
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
    }
    
    private func startSnoozeCountdown(activity: Activity<AlarmActivityAttributes>, totalSnoozeTime: TimeInterval) {
        let alarmID = activity.attributes.alarmID
        let startTime = Date()
        
        alarmUpdateTasks[alarmID] = Task {
            while !Task.isCancelled {
                let elapsed = Date().timeIntervalSince(startTime)
                let remaining = max(0, totalSnoozeTime - elapsed)
                
                if remaining <= 0 {
                    // Snooze ended - should trigger alarm again
                    let ringingState = AlarmActivityAttributes.ContentState.ringing()
                    await activity.update(.init(state: ringingState, staleDate: nil))
                    break
                } else {
                    // Update snooze countdown
                    let snoozedState = AlarmActivityAttributes.ContentState.snoozed(
                        snoozeTime: remaining,
                        snoozeCount: activity.content.state.snoozeCount
                    )
                    await activity.update(.init(state: snoozedState, staleDate: nil))
                }
                
                // Update every second
                try? await Task.sleep(nanoseconds: 1_000_000_000)
            }
        }
    }
    
    private func startMonitoringActivityUpdates() {
        Task {
            for await activity in Activity<TimerActivityAttributes>.activityUpdates {
                await MainActor.run {
                    if let index = activeTimerActivities.firstIndex(where: { $0.id == activity.id }) {
                        activeTimerActivities[index] = activity
                    }
                }
            }
        }
        
        Task {
            for await activity in Activity<StopwatchActivityAttributes>.activityUpdates {
                await MainActor.run {
                    if let index = activeStopwatchActivities.firstIndex(where: { $0.id == activity.id }) {
                        activeStopwatchActivities[index] = activity
                    }
                }
            }
        }
        
        Task {
            for await activity in Activity<AlarmActivityAttributes>.activityUpdates {
                await MainActor.run {
                    if let index = activeAlarmActivities.firstIndex(where: { $0.id == activity.id }) {
                        activeAlarmActivities[index] = activity
                    }
                }
            }
        }
    }
    
    // MARK: - Utility Methods
    
    func endAllActivities() async {
        // End all timer activities
        for activity in activeTimerActivities {
            if let timerID = UUID(uuidString: activity.attributes.timerID) {
                await endTimerActivity(timerID: timerID)
            }
        }
        
        // End all stopwatch activities
        for activity in activeStopwatchActivities {
            if let stopwatchID = UUID(uuidString: activity.attributes.stopwatchID) {
                await endStopwatchActivity(stopwatchID: stopwatchID)
            }
        }
        
        // End all alarm activities
        for activity in activeAlarmActivities {
            if let alarmID = UUID(uuidString: activity.attributes.alarmID) {
                await endAlarmActivity(alarmID: alarmID)
            }
        }
    }
    
    func getActiveTimerActivity(for timerID: UUID) -> Activity<TimerActivityAttributes>? {
        return activeTimerActivities.first { $0.attributes.timerID == timerID.uuidString }
    }
    
    func getActiveStopwatchActivity(for stopwatchID: UUID) -> Activity<StopwatchActivityAttributes>? {
        return activeStopwatchActivities.first { $0.attributes.stopwatchID == stopwatchID.uuidString }
    }
    
    func getActiveAlarmActivity(for alarmID: UUID) -> Activity<AlarmActivityAttributes>? {
        return activeAlarmActivities.first { $0.attributes.alarmID == alarmID.uuidString }
    }
}

// MARK: - Error Types

enum LiveActivityError: LocalizedError {
    case failedToStart(String)
    case updateFailed(String)
    case notSupported
    
    var errorDescription: String? {
        switch self {
        case .failedToStart(let message):
            return "Failed to start Live Activity: \(message)"
        case .updateFailed(let message):
            return "Failed to update Live Activity: \(message)"
        case .notSupported:
            return "Live Activities are not supported on this device"
        }
    }
}