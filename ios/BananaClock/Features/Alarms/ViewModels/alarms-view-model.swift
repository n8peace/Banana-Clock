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
    
    var navigationTitle: String { "Alarms" }
    
    private let coreDataManager = CoreDataManager.shared
    private let alarmService = AlarmKitService.shared
    private let supabaseService = SupabaseService.shared
    
    func loadAlarms() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load from Core Data (local + iCloud synced)
            alarms = try coreDataManager.fetchAlarms()
            
            // Sync with AlarmKit
            for alarm in alarms where alarm.isEnabled {
                try await alarmService.scheduleAlarm(alarm)
            }
            
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
    
    func addAlarm(_ alarm: Alarm) async {
        do {
            // Check permissions first (but don't fail if not authorized)
            let hasPermission = await alarmService.requestAuthorization()
            
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
            
            // Reload alarms
            await loadAlarms()
            
            HapticManager.shared.notification(.success)
        } catch {
            self.error = error
            print("Failed to add alarm: \(error)")
            HapticManager.shared.notification(.error)
        }
    }
    
    func updateAlarm(_ alarm: Alarm) async {
        do {
            // Update in Core Data
            try coreDataManager.updateAlarm(alarm)
            
            // Update AlarmKit (but don't fail if it doesn't work)
            do {
                try await alarmService.cancelAlarm(withId: alarm.id)
                if alarm.isEnabled {
                    try await alarmService.scheduleAlarm(alarm)
                }
            } catch {
                print("AlarmKit update failed (continuing with Core Data update): \(error)")
                // Continue with the operation even if AlarmKit fails
            }
            
            // Update AI content generation
            // if alarm.isAIEnabled && alarm.isEnabled {
            //     try await supabaseService.triggerAIContentGeneration(for: alarm)
            // }
            
            // Reload alarms
            await loadAlarms()
            
            HapticManager.shared.impact(.light)
        } catch {
            self.error = error
            print("Failed to update alarm: \(error)")
        }
    }
    
    func deleteAlarm(_ alarm: Alarm) async {
        do {
            // Delete from Core Data
            try coreDataManager.deleteAlarm(alarm.id)
            
            // Cancel in AlarmKit
            try await alarmService.cancelAlarm(withId: alarm.id)
            
            // Reload alarms
            await loadAlarms()
            
            HapticManager.shared.notification(.success)
        } catch {
            self.error = error
            print("Failed to delete alarm: \(error)")
        }
    }
    
    func toggleAlarm(_ alarm: Alarm, isEnabled: Bool) async {
        var updatedAlarm = alarm
        updatedAlarm.isEnabled = isEnabled
        await updateAlarm(updatedAlarm)
    }
    
    func deleteAlarms(at offsets: IndexSet) async {
        for index in offsets {
            let alarm = alarms[index]
            await deleteAlarm(alarm)
        }
    }
}