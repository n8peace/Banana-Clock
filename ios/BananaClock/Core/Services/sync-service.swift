//
//  SyncService.swift
//  BananaClock
//
//  User preferences sync service: iOS Core Data → Supabase
//  Only syncs user preferences needed for AI content generation
//

import Foundation
import CoreData
import SwiftUI

@MainActor
class SyncService: ObservableObject {
    static let shared = SyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    private let coreDataManager = CoreDataManager.shared
    private let supabaseService = SupabaseService.shared
    
    private let userDefaults = UserDefaults.standard
    private let lastSyncKey = "last_sync_date"
    private let syncQueueKey = "sync_queue"
    
    private init() {
        loadLastSyncDate()
    }
    
    // MARK: - Public Sync Methods
    
    /// Sync all data from iOS to Supabase
    func syncAll() async {
        guard supabaseService.isAuthenticated else {
            print("⚠️ Cannot sync: User not authenticated")
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            print("🔄 Starting full sync...")
            
            // Only sync user preferences (for AI content generation)
            try await syncUserPreferences()
            
            // Update last sync date
            lastSyncDate = Date()
            saveLastSyncDate()
            
            print("✅ Full sync completed successfully")
        } catch {
            syncError = error
            print("❌ Sync failed: \(error)")
        }
    }
    
    /// Sync only changed data since last sync
    func syncChanges() async {
        guard supabaseService.isAuthenticated else {
            print("⚠️ Cannot sync: User not authenticated")
            return
        }
        
        isSyncing = true
        defer { isSyncing = false }
        
        do {
            print("🔄 Starting incremental sync...")
            
            let lastSync = lastSyncDate ?? Date.distantPast
            
            // Only sync user preferences modified since last sync
            try await syncUserPreferences(since: lastSync)
            
            // Update last sync date
            lastSyncDate = Date()
            saveLastSyncDate()
            
            print("✅ Incremental sync completed successfully")
        } catch {
            syncError = error
            print("❌ Sync failed: \(error)")
        }
    }
    
    // MARK: - Individual Sync Methods
    
    private func syncUserPreferences(since date: Date = .distantPast) async throws {
        print("🔄 Syncing user preferences...")
        
        // Get user preferences from Core Data
        let preferences = try coreDataManager.fetchUserPreferences() as UserPreferences?
        
        // Only sync if preferences exist and were updated since last sync
        guard let preferences = preferences,
              preferences.updatedAt > date else {
            print("⏭️ User preferences up to date")
            return
        }
        
        // Update in Supabase directly with UserPreferences
        try await supabaseService.updateUserPreferences(preferences)
        
        print("✅ User preferences synced")
    }
    

    
    // MARK: - Conflict Resolution
    
    private func resolveConflict(local: Date, remote: Date) -> Date {
        // Simple "last write wins" strategy
        return local > remote ? local : remote
    }
    
    // MARK: - Offline Support
    
    private func queueForSync<T: Codable>(_ item: T, type: String) {
        var queue = getSyncQueue()
        
        // Encode the item to Data
        guard let encodedData = try? JSONEncoder().encode(item) else {
            print("⚠️ Failed to encode item for sync queue")
            return
        }
        
        let syncItem = SyncQueueItem(
            id: UUID(),
            type: type,
            data: encodedData,
            createdAt: Date()
        )
        queue.append(syncItem)
        saveSyncQueue(queue)
    }
    
    private func getSyncQueue() -> [SyncQueueItem] {
        guard let data = userDefaults.data(forKey: syncQueueKey),
              let queue = try? JSONDecoder().decode([SyncQueueItem].self, from: data) else {
            return []
        }
        return queue
    }
    
    private func saveSyncQueue(_ queue: [SyncQueueItem]) {
        if let data = try? JSONEncoder().encode(queue) {
            userDefaults.set(data, forKey: syncQueueKey)
        }
    }
    
    // MARK: - Private Helpers
    
    private func loadLastSyncDate() {
        if let date = userDefaults.object(forKey: lastSyncKey) as? Date {
            lastSyncDate = date
        }
    }
    
    private func saveLastSyncDate() {
        userDefaults.set(lastSyncDate, forKey: lastSyncKey)
    }
}

// MARK: - Supporting Types

struct SyncQueueItem: Codable {
    let id: UUID
    let type: String
    let data: Data // Encoded item data
    let createdAt: Date
}

 