//
//  CoreDataManager.swift
//  BananaClock
//
//  Core Data stack with CloudKit sync
//

import Foundation
import CoreData
import CloudKit
import SwiftUI

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    // MARK: - Core Data Stack
    
    lazy var persistentContainer: NSPersistentCloudKitContainer = {
        let container = NSPersistentCloudKitContainer(name: "BananaClock")
        
        // Configure for CloudKit
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Configure CloudKit
            storeDescription.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.ai.bananaintelligence.BananaClock"
            )
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("Core Data failed to load: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Save Context
    
    func save() {
        guard viewContext.hasChanges else { return }
        
        do {
            try viewContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    // MARK: - Alarm Operations
    
    func createAlarm(_ alarm: Alarm) throws -> CDAlarm {
        let cdAlarm = CDAlarm(context: viewContext)
        cdAlarm.id = alarm.id
        cdAlarm.time = alarm.time
        cdAlarm.label = alarm.label
        cdAlarm.isEnabled = alarm.isEnabled
        cdAlarm.isAIEnabled = alarm.isAIEnabled
        cdAlarm.soundIdentifier = alarm.soundIdentifier
        cdAlarm.snoozeLength = Int16(alarm.snoozeLength ?? 9)
        cdAlarm.repeatDays = try JSONEncoder().encode(alarm.repeatDays)
        cdAlarm.volume = alarm.volume

        // Note: isWakeUpAlarm and lastUsedAt are not in Core Data model yet
        // For now, we'll use a workaround by checking the label
        cdAlarm.createdAt = alarm.createdAt
        cdAlarm.updatedAt = alarm.updatedAt
        
        save()
        return cdAlarm
    }
    
    func fetchAlarms() throws -> [Alarm] {
        let request = CDAlarm.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "time", ascending: true)]
        
        let cdAlarms = try viewContext.fetch(request)
        return cdAlarms.compactMap { cdAlarm in
            guard let id = cdAlarm.id,
                  let time = cdAlarm.time,
                  let label = cdAlarm.label,
                  let soundIdentifier = cdAlarm.soundIdentifier,
                  let createdAt = cdAlarm.createdAt,
                  let updatedAt = cdAlarm.updatedAt else { return nil }
            
            let repeatDays = (try? JSONDecoder().decode([Alarm.Weekday].self, from: cdAlarm.repeatDays ?? Data())) ?? []
            
            // Workaround: Check if this is the wake-up alarm by label
            let isWakeUpAlarm = label == "Wake Up"
            
            return Alarm(
                id: id,
                time: time,
                label: label,
                isEnabled: cdAlarm.isEnabled,
                isAIEnabled: cdAlarm.isAIEnabled,
                soundIdentifier: soundIdentifier,
                snoozeLength: cdAlarm.snoozeLength == 0 ? nil : Int(cdAlarm.snoozeLength),
                repeatDays: repeatDays,
                volume: cdAlarm.volume,
                isWakeUpAlarm: isWakeUpAlarm,

                lastUsedAt: updatedAt, // Use updatedAt as fallback for lastUsedAt
                createdAt: createdAt,
                updatedAt: updatedAt
            )
        }
    }
    
    func updateAlarm(_ alarm: Alarm) throws {
        let request = CDAlarm.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", alarm.id as CVarArg)
        
        guard let cdAlarm = try viewContext.fetch(request).first else {
            throw CoreDataError.notFound
        }
        
        cdAlarm.time = alarm.time
        cdAlarm.label = alarm.label
        cdAlarm.isEnabled = alarm.isEnabled
        cdAlarm.isAIEnabled = alarm.isAIEnabled
        cdAlarm.soundIdentifier = alarm.soundIdentifier
        cdAlarm.snoozeLength = Int16(alarm.snoozeLength ?? 9)
        cdAlarm.repeatDays = try JSONEncoder().encode(alarm.repeatDays)
        cdAlarm.volume = alarm.volume

        cdAlarm.updatedAt = Date()
        // Note: isWakeUpAlarm and lastUsedAt updates are not handled in Core Data yet
        
        save()
    }
    
    func deleteAlarm(_ alarmId: UUID) throws {
        let request = CDAlarm.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", alarmId as CVarArg)
        
        guard let cdAlarm = try viewContext.fetch(request).first else {
            throw CoreDataError.notFound
        }
        
        viewContext.delete(cdAlarm)
        save()
    }
    
    // MARK: - Timer Operations
    
    func createTimer(_ timer: Timer) throws -> CDTimer {
        let cdTimer = CDTimer(context: viewContext)
        cdTimer.id = timer.id
        cdTimer.label = timer.label
        cdTimer.duration = timer.duration
        cdTimer.remainingTime = timer.remainingTime
        cdTimer.state = timer.state.rawValue
        cdTimer.soundIdentifier = timer.soundIdentifier
        cdTimer.createdAt = timer.createdAt
        cdTimer.isPreset = timer.isPreset
        cdTimer.presetOrder = Int16(timer.presetOrder)
        
        save()
        return cdTimer
    }
    
    func fetchTimers() throws -> [Timer] {
        let request = CDTimer.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let cdTimers = try viewContext.fetch(request)
        return cdTimers.compactMap { cdTimer in
            guard let id = cdTimer.id,
                  let label = cdTimer.label,
                  let state = cdTimer.state,
                  let soundIdentifier = cdTimer.soundIdentifier,
                  let createdAt = cdTimer.createdAt,
                  let timerState = Timer.TimerState(rawValue: state) else { return nil }
            
            return Timer(
                id: id,
                label: label,
                duration: cdTimer.duration,
                remainingTime: cdTimer.remainingTime,
                state: timerState,
                soundIdentifier: soundIdentifier,
                createdAt: createdAt,
                startedAt: cdTimer.startedAt,
                pausedAt: cdTimer.pausedAt,
                finishedAt: cdTimer.finishedAt,
                isPreset: cdTimer.isPreset,
                presetOrder: Int(cdTimer.presetOrder)
            )
        }
    }
    
    // MARK: - World Clock Operations
    
    func createWorldClock(_ worldClock: WorldClock) throws -> CDWorldClock {
        let cdWorldClock = CDWorldClock(context: viewContext)
        cdWorldClock.id = worldClock.id
        cdWorldClock.cityName = worldClock.cityName
        cdWorldClock.timeZoneIdentifier = worldClock.timeZoneIdentifier
        cdWorldClock.displayOrder = Int16(worldClock.displayOrder)
        cdWorldClock.createdAt = worldClock.createdAt
        
        save()
        return cdWorldClock
    }
    
    func fetchWorldClocks() throws -> [WorldClock] {
        let request = CDWorldClock.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "displayOrder", ascending: true)]
        
        let cdWorldClocks = try viewContext.fetch(request)
        var worldClocks: [WorldClock] = []
        
        for cdWorldClock in cdWorldClocks {
            guard let id = cdWorldClock.id,
                  let cityName = cdWorldClock.cityName,
                  let timeZoneIdentifier = cdWorldClock.timeZoneIdentifier,
                  let createdAt = cdWorldClock.createdAt else { 
                continue
            }
            
            let worldClock = WorldClock(
                id: id,
                cityName: cityName,
                timeZoneIdentifier: timeZoneIdentifier,
                displayOrder: Int(cdWorldClock.displayOrder),
                createdAt: createdAt
            )
            worldClocks.append(worldClock)
        }
        
        return worldClocks
    }
    
    // MARK: - User Preferences
    
    func saveUserPreferences(_ preferences: UserPreferences) throws {
        let request = CDUserPreferences.fetchRequest()
        request.fetchLimit = 1
        
        let cdPreferences = try viewContext.fetch(request).first ?? CDUserPreferences(context: viewContext)
        
        cdPreferences.id = preferences.id
        cdPreferences.timezone = preferences.timezone
        cdPreferences.locationZip = preferences.locationZip
        cdPreferences.name = preferences.name
        cdPreferences.city = preferences.city
        cdPreferences.state = preferences.state
        cdPreferences.voice = preferences.voice.rawValue
        cdPreferences.wakeUpTime = preferences.wakeUpTime
        cdPreferences.contentPreferences = try JSONEncoder().encode(preferences.contentPreferences)
        cdPreferences.updatedAt = Date()
        
        save()
    }
    
    func fetchUserPreferences() throws -> UserPreferences? {
        let request = CDUserPreferences.fetchRequest()
        request.fetchLimit = 1
        
        guard let cdPreferences = try viewContext.fetch(request).first,
              let id = cdPreferences.id,
              let timezone = cdPreferences.timezone,
              let voice = cdPreferences.voice,
              let updatedAt = cdPreferences.updatedAt else { return nil }
        
        let contentPrefs = (try? JSONDecoder().decode(
            UserPreferences.ContentPreferences.self,
            from: cdPreferences.contentPreferences ?? Data()
        )) ?? UserPreferences.ContentPreferences()
        
        return UserPreferences(
            id: id,
            timezone: timezone,
            locationZip: cdPreferences.locationZip,
            name: cdPreferences.name,
            city: cdPreferences.city,
            state: cdPreferences.state,
            voice: AIVoiceOption(rawValue: voice) ?? .voice1,
            wakeUpTime: cdPreferences.wakeUpTime,
            contentPreferences: contentPrefs,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Error Types
enum CoreDataError: LocalizedError {
    case notFound
    case saveFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Data not found"
        case .saveFailed:
            return "Failed to save data"
        case .invalidData:
            return "Invalid data format"
        }
    }
}