//
//  AlarmsViewModel.swift
//  BananaClock
//
//  Updated to use Core Data instead of Supabase for alarm storage
//

import SwiftUI
import CoreData
import Foundation

@MainActor
class AlarmsViewModel: ObservableObject {
    @Published var alarms: [Alarm] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedAlarms: Set<UUID> = []
    
    // Wake-up alarm management
    let wakeUpViewModel = WakeUpAlarmsViewModel()
    
    init() {
        print("DEBUG: AlarmsViewModel - created SHARED wakeUpViewModel instance: \(ObjectIdentifier(wakeUpViewModel))")
    }
    
    var navigationTitle: String { "⏰ Alarms" }
    
    // Computed properties for sections
    var wakeUpAlarm: Alarm? {
        alarms.first { $0.isWakeUpAlarm }
    }
    
    var otherAlarms: [Alarm] {
        alarms.filter { !$0.isWakeUpAlarm }
    }
    
    // Computed properties for selection mode
    var isSelectionMode: Bool {
        !selectedAlarms.isEmpty
    }
    
    var selectedAlarmsCount: Int {
        selectedAlarms.count
    }
    
    var selectableAlarms: [Alarm] {
        otherAlarms // Only other alarms can be selected (not wake-up alarm)
    }
    
    // Next alarm state from wake-up view model
    var nextAlarmState: NextAlarmState {
        wakeUpViewModel.nextAlarmState
    }
    
    var tomorrowsAlarmText: String {
        wakeUpViewModel.tomorrowsAlarmText
    }
    

    
    private let coreDataManager = CoreDataManager.shared
    private let alarmService = AlarmKitService.shared
    private let supabaseService = SupabaseService.shared
    
    func loadAlarms() async {
        await loadAlarms(refreshWakeUpAlarms: true)
    }
    
    func loadAlarms(refreshWakeUpAlarms: Bool = true) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load from Core Data (local + iCloud synced)
            alarms = try coreDataManager.fetchAlarms()
            
            // Clean up old alarms
            cleanupOldAlarms()
            
            // Only refresh wake-up alarms if requested (prevents cross-contamination)
            if refreshWakeUpAlarms {
                await wakeUpViewModel.loadWakeUpAlarms()
            }
            
            // Note: Removed blanket alarm rescheduling to prevent cross-contamination
            // Individual alarms are scheduled when specifically modified
            
            // Trigger AI content generation for enabled AI alarms
            // let aiAlarms = alarms.filter { $0.isAIEnabled && $0.isEnabled }
            // for alarm in aiAlarms {
            //     Task {
            //         try? await supabaseService.triggerAIContentGeneration(for: alarm)
            //     }
            // }
        } catch {
            self.error = error
            print("Failed to load alarms: \(error)")
        }
    }

    
    private func cleanupOldAlarms() {
        let tenDaysAgo = Date().addingTimeInterval(-10 * 24 * 60 * 60)
        let oldAlarmCount = alarms.count
        
        alarms.removeAll { alarm in
            !alarm.isWakeUpAlarm && alarm.lastUsedAt < tenDaysAgo
        }
        
        if alarms.count != oldAlarmCount {
            // Save changes to Core Data
            coreDataManager.save()
        }
    }
    
    func addAlarm(_ alarm: Alarm) async {
        do {
            // Check permissions first (but don't fail if not authorized)
            let hasPermission = await alarmService.requestAuthorization()
            
            // For non-wake-up alarms, check for duplicates and delete old ones
            if !alarm.isWakeUpAlarm {
                await removeDuplicateAlarms(name: alarm.label, time: alarm.time)
            }
            
            // Save to Core Data
            _ = try coreDataManager.createAlarm(alarm)
            
            // Schedule with AlarmKit if enabled (but don't fail if it doesn't work)
            if alarm.isEnabled && hasPermission {
                do {
                    try await alarmService.scheduleAlarm(alarm)
                } catch {
                    print("AlarmKit scheduling failed (continuing with Core Data save): \(error)")
                    // Continue with the operation even if AlarmKit fails
                }
            }
            
            // Trigger AI content generation if needed
            // if alarm.isAIEnabled && alarm.isEnabled {
            //     try await supabaseService.triggerAIContentGeneration(for: alarm)
            // }
            
            // Reload alarms (refresh wake-up alarms only if this is a wake-up alarm)
            await loadAlarms(refreshWakeUpAlarms: alarm.isWakeUpAlarm)
            
            HapticManager.shared.notification(.success)
        } catch {
            self.error = error
            print("Failed to add alarm: \(error)")
            HapticManager.shared.notification(.error)
        }
    }
    
    func updateAlarm(_ alarm: Alarm) async {
        do {
            // Update lastUsedAt for non-wake-up alarms
            var updatedAlarm = alarm
            if !alarm.isWakeUpAlarm {
                updatedAlarm.lastUsedAt = Date()
            }
            
            // Update in Core Data
            try coreDataManager.updateAlarm(updatedAlarm)
            
            // Update AlarmKit (but don't fail if it doesn't work)
            do {
                try await alarmService.cancelAlarm(withId: alarm.id)
                if alarm.isEnabled {
                    try await alarmService.scheduleAlarm(updatedAlarm)
                }
            } catch {
                print("AlarmKit update failed (continuing with Core Data update): \(error)")
                // Continue with the operation even if AlarmKit fails
            }
            
            // Update AI content generation
            // if alarm.isAIEnabled && alarm.isEnabled {
            //     try await supabaseService.triggerAIContentGeneration(for: alarm)
            // }
            
            // Reload alarms (refresh wake-up alarms only if this is a wake-up alarm)  
            await loadAlarms(refreshWakeUpAlarms: alarm.isWakeUpAlarm)
            
            HapticManager.shared.impact(.light)
        } catch {
            self.error = error
            print("Failed to update alarm: \(error)")
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) async {
        // Prevent deletion of wake-up alarm
        guard !alarm.isWakeUpAlarm else {
            print("Cannot delete wake-up alarm")
            return
        }
        
        do {
            // Delete from Core Data
            try coreDataManager.deleteAlarm(alarm.id)
            
            // Cancel in AlarmKit
            try await alarmService.cancelAlarm(withId: alarm.id)
            
            // Reload alarms (no need to refresh wake-up alarms since this is only for non-wake-up alarms)
            await loadAlarms(refreshWakeUpAlarms: false)
            
            HapticManager.shared.notification(.success)
        } catch {
            self.error = error
            print("Failed to delete alarm: \(error)")
        }
    }
    
    func toggleAlarm(_ alarm: Alarm, isEnabled: Bool) async {
        print("DEBUG: AlarmsViewModel.toggleAlarm called for alarm \(alarm.id), isWakeUp: \(alarm.isWakeUpAlarm), newEnabled: \(isEnabled)")
        var updatedAlarm = alarm
        updatedAlarm.isEnabled = isEnabled
        
        if alarm.isWakeUpAlarm {
            // Use wake-up view model for wake-up alarms
            print("DEBUG: AlarmsViewModel delegating to SHARED wakeUpViewModel instance: \(ObjectIdentifier(wakeUpViewModel))")
            await wakeUpViewModel.toggleAlarm(alarm, isEnabled: isEnabled)
            
            // Sync the updated alarm back to the main alarms array
            await syncWakeUpAlarmToMainArray(alarmId: alarm.id)
        } else {
            // Update lastUsedAt for non-wake-up alarms
            updatedAlarm.lastUsedAt = Date()
            await updateAlarm(updatedAlarm)
        }
    }
    
    // MARK: - Synchronization Helper
    
    private func syncWakeUpAlarmToMainArray(alarmId: UUID) async {
        do {
            // Fetch the updated alarm from CoreData
            let updatedAlarms = try coreDataManager.fetchAlarms()
            
            // Find the specific updated alarm
            if let updatedAlarm = updatedAlarms.first(where: { $0.id == alarmId }) {
                // Update just this alarm in the main array
                if let index = alarms.firstIndex(where: { $0.id == alarmId }) {
                    alarms[index] = updatedAlarm
                    print("DEBUG: Synchronized wake-up alarm \(alarmId) in main alarms array")
                }
            }
        } catch {
            print("ERROR: Failed to sync wake-up alarm to main array: \(error)")
        }
    }
    
    func deleteAlarms(at offsets: IndexSet) async {
        let alarmsToDelete = offsets.map { otherAlarms[$0] }
        
        for alarm in alarmsToDelete {
            await deleteAlarm(alarm)
        }
    }
    
    // MARK: - Selection Management
    
    func toggleSelection(for alarm: Alarm) {
        guard !alarm.isWakeUpAlarm else { return } // Wake-up alarms cannot be selected
        
        if selectedAlarms.contains(alarm.id) {
            selectedAlarms.remove(alarm.id)
        } else {
            selectedAlarms.insert(alarm.id)
        }
    }
    
    func selectAll() {
        selectedAlarms = Set(selectableAlarms.map { $0.id })
    }
    
    func deselectAll() {
        selectedAlarms.removeAll()
    }
    
    func isSelected(_ alarm: Alarm) -> Bool {
        selectedAlarms.contains(alarm.id)
    }
    
    // MARK: - Bulk Operations
    
    func deleteSelectedAlarms() async {
        let alarmsToDelete = alarms.filter { selectedAlarms.contains($0.id) }
        
        for alarm in alarmsToDelete {
            await deleteAlarm(alarm)
        }
        
        // Clear selection after deletion
        selectedAlarms.removeAll()
    }
    
    // MARK: - Duplicate Prevention
    
    private func removeDuplicateAlarms(name: String, time: Date) async {
        // Find existing alarms with the same name and time (excluding wake-up alarms)
        let duplicateAlarms = alarms.filter { alarm in
            !alarm.isWakeUpAlarm && 
            alarm.label == name && 
            Calendar.current.compare(alarm.time, to: time, toGranularity: .minute) == .orderedSame
        }
        
        // Delete all duplicate alarms
        for duplicateAlarm in duplicateAlarms {
            do {
                // Delete from Core Data
                try coreDataManager.deleteAlarm(duplicateAlarm.id)
                
                // Cancel in AlarmKit
                try await alarmService.cancelAlarm(withId: duplicateAlarm.id)
                
                print("Deleted duplicate alarm: \(duplicateAlarm.label) at \(duplicateAlarm.formattedTime)")
            } catch {
                print("Failed to delete duplicate alarm: \(error)")
            }
        }
    }
}