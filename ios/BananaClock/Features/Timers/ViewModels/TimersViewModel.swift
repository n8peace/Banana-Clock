//
//  TimersViewModel.swift
//  BananaClock
//
//  ViewModel for managing timer state and operations with enhanced functionality
//

import Foundation
import SwiftUI
import Combine

// MARK: - Timer Preset Model
struct TimerPreset {
    let label: String
    let duration: TimeInterval
    let defaultLabel: String
    
    static let defaults = [
        TimerPreset(label: "1 min", duration: 60, defaultLabel: "1 Min Timer"),
        TimerPreset(label: "5 min", duration: 300, defaultLabel: "5 Min Timer"),
        TimerPreset(label: "10 min", duration: 600, defaultLabel: "10 Min Timer")
    ]
}

// MARK: - Timers ViewModel
@MainActor
class TimersViewModel: ObservableObject {
    @Published var timers: [BananaTimer] = []
    @Published var selectedTimers: Set<UUID> = []
    private var timerTasks: [UUID: Task<Void, Never>] = [:]
    
    private let timersKey = "SavedTimers"
    private var liveActivityService = LiveActivityService.shared
    
    var navigationTitle: String { "⏲️ Timers" }
    
    var activeTimers: [BananaTimer] {
        timers.filter { $0.state == .running || $0.state == .paused }
            .sorted { timer1, timer2 in
                // First sort by end time (running timers first, then paused)
                let timer1EndTime = timer1.state == .running ? (timer1.endTime ?? Date.distantFuture) : Date.distantFuture
                let timer2EndTime = timer2.state == .running ? (timer2.endTime ?? Date.distantFuture) : Date.distantFuture
                
                if timer1EndTime != timer2EndTime {
                    return timer1EndTime < timer2EndTime
                }
                
                // If end times are the same (both paused), sort by remaining time
                return timer1.remainingTime < timer2.remainingTime
            }
    }
    
    var recentTimers: [BananaTimer] {
        let inactiveTimers = timers.filter { $0.state == .finished || $0.state == .ready }
        
        // Group by duration and label, keeping only the most recent one
        var uniqueTimers: [BananaTimer] = []
        var seenCombinations: Set<String> = []
        
        // Sort by lastUsedAt descending to process most recent first
        let sortedTimers = inactiveTimers.sorted { $0.lastUsedAt > $1.lastUsedAt }
        
        for timer in sortedTimers {
            let combination = "\(timer.duration)_\(timer.label)"
            if !seenCombinations.contains(combination) {
                seenCombinations.insert(combination)
                uniqueTimers.append(timer)
            }
        }
        
        return uniqueTimers
    }
    
    // Computed properties for selection mode
    var isSelectionMode: Bool {
        !selectedTimers.isEmpty
    }
    
    var selectedTimersCount: Int {
        selectedTimers.count
    }
    
    var selectableTimers: [BananaTimer] {
        timers // All timers can be selected
    }
    
    init() {
        loadTimers()
    }
    
    func canAddTimer(isPremium: Bool) -> Bool {
        return true
    }
    
    func startTimer(duration: TimeInterval, label: String, soundIdentifier: String) {
        let timer = BananaTimer(
            label: label,
            duration: duration,
            state: .running,
            startedAt: Date(),
            lastUsedAt: Date(),
            soundIdentifier: soundIdentifier
        )
        timers.append(timer)
        startTimerTask(for: timer)
        saveTimers()
        
        // Start Live Activity
        Task {
            await startTimerLiveActivity(timer)
        }
        
        HapticManager.shared.impact(.medium)
    }
    
    func startTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        // Only start if timer is in ready state
        guard timers[index].state == .ready else { return }
        
        timers[index].state = .running
        timers[index].startedAt = Date()
        timers[index].lastUsedAt = Date()
        
        startTimerTask(for: timers[index])
        saveTimers()
        
        // Start Live Activity
        Task {
            await startTimerLiveActivity(timers[index])
        }
        
        HapticManager.shared.impact(.medium)
    }
    
    func pauseTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        // Only pause if timer is running
        guard timers[index].state == .running else { return }
        
        timers[index].state = .paused
        timers[index].pausedAt = Date()
        
        cancelTimerTask(for: timer.id)
        saveTimers()
        
        // Update Live Activity
        Task {
            await updateTimerLiveActivity(timers[index])
        }
        
        HapticManager.shared.impact(.light)
    }
    
    func resumeTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        // Only resume if timer is paused
        guard timers[index].state == .paused else { return }
        
        timers[index].state = .running
        timers[index].startedAt = Date()
        timers[index].pausedAt = nil
        timers[index].lastUsedAt = Date()
        
        startTimerTask(for: timers[index])
        saveTimers()
        
        // Update Live Activity
        Task {
            await updateTimerLiveActivity(timers[index])
        }
        
        HapticManager.shared.impact(.light)
    }
    
    func repeatTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        timers[index].state = .running
        timers[index].remainingTime = timer.duration
        timers[index].startedAt = Date()
        timers[index].pausedAt = nil
        timers[index].lastUsedAt = Date()
        
        startTimerTask(for: timers[index])
        saveTimers()
        
        // Start Live Activity
        Task {
            await startTimerLiveActivity(timers[index])
        }
        
        HapticManager.shared.impact(.medium)
    }
    
    func cancelTimer(_ timer: BananaTimer) {
        guard let index = timers.firstIndex(where: { $0.id == timer.id }) else { return }
        
        cancelTimerTask(for: timer.id)
        
        // End Live Activity
        Task {
            await endTimerLiveActivity(timer.id)
        }
        
        timers[index].state = .finished
        timers[index].remainingTime = timer.duration
        timers[index].lastUsedAt = Date()
        saveTimers()
        HapticManager.shared.impact(.light)
        
        // Force UI update
        objectWillChange.send()
    }
    
    func deleteTimers(at offsets: IndexSet, from sourceArray: [BananaTimer]) {
        for index in offsets {
            let timer = sourceArray[index]
            cancelTimerTask(for: timer.id)
            
            // End Live Activity if running
            if timer.state == .running || timer.state == .paused {
                Task {
                    await endTimerLiveActivity(timer.id)
                }
            }
            
            timers.removeAll { $0.id == timer.id }
        }
        saveTimers()
        HapticManager.shared.impact(.light)
    }
    
    func cleanupOldTimers() {
        let oneWeekAgo = Date().addingTimeInterval(-10 * 24 * 60 * 60)
        let oldTimerCount = timers.count
        
        timers.removeAll { timer in
            timer.lastUsedAt < oneWeekAgo && 
            (timer.state == .finished || timer.state == .ready)
        }
        
        if timers.count != oldTimerCount {
            saveTimers()
        }
    }
    
    // MARK: - Selection Management
    
    func toggleSelection(for timer: BananaTimer) {
        if selectedTimers.contains(timer.id) {
            selectedTimers.remove(timer.id)
        } else {
            selectedTimers.insert(timer.id)
        }
    }
    
    func selectAll() {
        selectedTimers = Set(selectableTimers.map { $0.id })
    }
    
    func deselectAll() {
        selectedTimers.removeAll()
    }
    
    func isSelected(_ timer: BananaTimer) -> Bool {
        selectedTimers.contains(timer.id)
    }
    
    // MARK: - Bulk Operations
    
    func deleteSelectedTimers() {
        let timersToDelete = timers.filter { selectedTimers.contains($0.id) }
        
        for timer in timersToDelete {
            cancelTimerTask(for: timer.id)
            
            // End Live Activity if running
            if timer.state == .running || timer.state == .paused {
                Task {
                    await endTimerLiveActivity(timer.id)
                }
            }
        }
        
        timers.removeAll { selectedTimers.contains($0.id) }
        selectedTimers.removeAll()
        saveTimers()
        HapticManager.shared.impact(.light)
    }
    
    private func startTimerTask(for timer: BananaTimer) {
        cancelTimerTask(for: timer.id)
        
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                
                await MainActor.run {
                    self?.updateTimer(timer.id)
                }
            }
        }
        
        timerTasks[timer.id] = task
    }
    
    private func cancelTimerTask(for timerId: UUID) {
        timerTasks[timerId]?.cancel()
        timerTasks[timerId] = nil
    }
    
    private func updateTimer(_ timerId: UUID) {
        guard let index = timers.firstIndex(where: { $0.id == timerId }),
              timers[index].state == .running else { return }
        
        timers[index].remainingTime -= 0.1
        
        if timers[index].remainingTime <= 0 {
            timers[index].remainingTime = 0
            timers[index].state = .finished
            cancelTimerTask(for: timerId)
            
            // Play sound and haptic
            let soundIdentifier = timers[index].soundIdentifier
            print("⏰ Timer completed! Playing sound: '\(soundIdentifier)' for timer: \(timers[index].label)")
            AudioService.shared.playSound(soundIdentifier)
            HapticManager.shared.notification(.success)
            
            // End Live Activity
            Task {
                await endTimerLiveActivity(timerId)
            }
            
            saveTimers()
        }
    }
    
    // MARK: - Live Activities
    
    private func startTimerLiveActivity(_ timer: BananaTimer) async {
        do {
            try await liveActivityService.startTimerActivity(
                timerID: timer.id,
                duration: timer.duration,
                title: timer.label,
                soundIdentifier: timer.soundIdentifier
            )
        } catch {
            print("❌ Failed to start timer Live Activity: \(error)")
        }
    }
    
    private func updateTimerLiveActivity(_ timer: BananaTimer) async {
        await liveActivityService.updateTimerActivity(
            timerID: timer.id,
            remainingTime: timer.remainingTime,
            isRunning: timer.state == .running,
            isPaused: timer.state == .paused
        )
    }
    
    private func endTimerLiveActivity(_ timerID: UUID) async {
        await liveActivityService.endTimerActivity(timerID: timerID)
    }
    
    // MARK: - Persistence
    private func saveTimers() {
        // Clean up duplicate inactive timers before saving
        cleanupDuplicateInactiveTimers()
        
        if let encoded = try? JSONEncoder().encode(timers) {
            UserDefaults.standard.set(encoded, forKey: timersKey)
        }
    }
    
    private func cleanupDuplicateInactiveTimers() {
        let inactiveTimers = timers.filter { $0.state == .finished || $0.state == .ready }
        let activeTimers = timers.filter { $0.state == .running || $0.state == .paused }
        
        // Group inactive timers by duration and label, keeping only the most recent one
        var uniqueInactiveTimers: [BananaTimer] = []
        var seenCombinations: Set<String> = []
        
        // Sort by lastUsedAt descending to process most recent first
        let sortedInactiveTimers = inactiveTimers.sorted { $0.lastUsedAt > $1.lastUsedAt }
        
        for timer in sortedInactiveTimers {
            let combination = "\(timer.duration)_\(timer.label)"
            if !seenCombinations.contains(combination) {
                seenCombinations.insert(combination)
                uniqueInactiveTimers.append(timer)
            }
        }
        
        // Reconstruct timers array with active timers + deduplicated inactive timers
        timers = activeTimers + uniqueInactiveTimers
    }
    
    private func loadTimers() {
        guard let data = UserDefaults.standard.data(forKey: timersKey),
              let decoded = try? JSONDecoder().decode([BananaTimer].self, from: data) else {
            return
        }
        
        timers = decoded
        
        // Restart any running timers
        for timer in timers where timer.state == .running {
            startTimerTask(for: timer)
        }
        
        // Clean up old timers on load
        cleanupOldTimers()
    }
    
    deinit {
        // Cancel all timer tasks
        for task in timerTasks.values {
            task.cancel()
        }
    }
}