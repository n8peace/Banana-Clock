//
//  AIContentFallbackManager.swift
//  BananaClock
//
//  Manages multi-layer fallback strategy for AI wake-up content
//  Ensures alarms always work, even without connectivity or content
//

import Foundation
import AVFoundation
import SwiftUI

@MainActor
class AIContentFallbackManager: ObservableObject {
    static let shared = AIContentFallbackManager()
    
    // MARK: - Fallback Levels
    
    enum FallbackLevel: Int, CaseIterable {
        case personalizedCached = 0    // Best: Personalized content from cache
        case personalizedFetch = 1     // Good: Fetch personalized content now
        case genericCached = 2         // OK: Generic content from cache
        case bundledGeneric = 3        // Fallback: Bundled generic audio
        case standardAlarm = 4         // Last resort: Standard alarm sound
        
        var description: String {
            switch self {
            case .personalizedCached: return "Personalized (Cached)"
            case .personalizedFetch: return "Personalized (Live)"
            case .genericCached: return "Generic (Cached)"
            case .bundledGeneric: return "Generic (Bundled)"
            case .standardAlarm: return "Standard Alarm"
            }
        }
        
        var analyticsName: String {
            switch self {
            case .personalizedCached: return "personalized_cached"
            case .personalizedFetch: return "personalized_fetch"
            case .genericCached: return "generic_cached"
            case .bundledGeneric: return "bundled_generic"
            case .standardAlarm: return "standard_alarm"
            }
        }
    }
    
    // MARK: - Properties
    
    @Published var lastFallbackLevel: FallbackLevel?
    @Published var fallbackStats: [FallbackLevel: Int] = [:]
    
    private let maxFetchTimeout: TimeInterval = 5.0  // 5 seconds max for live fetch
    private let audioVerificationTimeout: TimeInterval = 2.0
    
    private init() {
        // Initialize stats
        for level in FallbackLevel.allCases {
            fallbackStats[level] = 0
        }
    }
    
    // MARK: - Main Content Retrieval
    
    /// Get AI content with multi-layer fallback
    func getAIContent(
        for alarmId: UUID,
        date: Date,
        voice: String,
        timeout: TimeInterval? = nil
    ) async -> (audioURL: URL?, content: String?, fallbackLevel: FallbackLevel) {
        
        let effectiveTimeout = timeout ?? maxFetchTimeout
        
        // Level 0: Check for cached personalized content
        if let cachedContent = await checkCachedPersonalizedContent(alarmId: alarmId, date: date) {
            recordFallbackUsage(.personalizedCached)
            return cachedContent
        }
        
        // Level 1: Try to fetch personalized content (with timeout)
        if NetworkMonitor.shared.isConnected {
            if let fetchedContent = await fetchPersonalizedContent(
                alarmId: alarmId, 
                date: date, 
                timeout: effectiveTimeout
            ) {
                recordFallbackUsage(.personalizedFetch)
                return fetchedContent
            }
        }
        
        // Level 2: Check for cached generic content
        if let genericContent = await checkCachedGenericContent(voice: voice, date: date) {
            recordFallbackUsage(.genericCached)
            return genericContent
        }
        
        // Level 3: Use bundled generic audio
        if let bundledURL = getBundledGenericAudio(voice: voice) {
            recordFallbackUsage(.bundledGeneric)
            return (bundledURL, getGenericScript(voice: voice), .bundledGeneric)
        }
        
        // Level 4: Return nil - will use standard alarm
        recordFallbackUsage(.standardAlarm)
        return (nil, nil, .standardAlarm)
    }
    
    // MARK: - Level 0: Cached Personalized Content
    
    private func checkCachedPersonalizedContent(
        alarmId: UUID, 
        date: Date
    ) async -> (audioURL: URL?, content: String?, fallbackLevel: FallbackLevel)? {
        
        // Get content block from cache
        guard let contentBlock = await ContentCacheManager.shared.getContentBlock(
            for: alarmId, 
            date: date
        ) else {
            print("🔍 No cached content block found for alarm \(alarmId)")
            return nil
        }
        
        // Verify content is ready
        guard contentBlock.isReady && contentBlock.hasAudio else {
            print("⚠️ Content block not ready or missing audio")
            return nil
        }
        
        // Check if audio is downloaded
        guard let localURL = AudioDownloadManager.shared.getCachedAudio(
            for: contentBlock.id
        ) else {
            print("⚠️ Audio not downloaded for content block \(contentBlock.id)")
            return nil
        }
        
        // Verify file exists and is playable
        guard FileManager.default.fileExists(atPath: localURL.path) else {
            print("⚠️ Audio file missing at path: \(localURL.path)")
            return nil
        }
        
        // Verify audio is playable
        guard await verifyAudioPlayable(localURL) else {
            print("⚠️ Audio file exists but is not playable")
            return nil
        }
        
        print("✅ Found cached personalized content for alarm \(alarmId)")
        return (localURL, contentBlock.script, .personalizedCached)
    }
    
    // MARK: - Level 1: Fetch Personalized Content
    
    private func fetchPersonalizedContent(
        alarmId: UUID,
        date: Date,
        timeout: TimeInterval
    ) async -> (audioURL: URL?, content: String?, fallbackLevel: FallbackLevel)? {
        
        print("🔄 Attempting to fetch personalized content with \(timeout)s timeout")
        
        // Create a task with timeout
        let fetchTask = Task { () -> (audioURL: URL?, content: String?, fallbackLevel: FallbackLevel)? in
            // Try to trigger content generation if needed
            if let contentBlock = await ContentCacheManager.shared.getContentBlock(for: alarmId, date: date) {
                if contentBlock.hasAudio, let audioUrl = contentBlock.audioUrl {
                    do {
                        let localURL = try await AudioDownloadManager.shared.downloadAudio(
                            for: contentBlock.id,
                            audioUrl: audioUrl
                        )
                        
                        if await verifyAudioPlayable(localURL) {
                            print("✅ Successfully fetched personalized content")
                            return (localURL, contentBlock.script, .personalizedFetch)
                        }
                    } catch {
                        print("⚠️ Failed to download personalized audio: \(error)")
                    }
                }
            }
            return nil
        }
        
        // Wait for fetch or timeout
        do {
            let result = try await withTimeout(seconds: timeout) {
                await fetchTask.value
            }
            return result
        } catch {
            print("⏱️ Personalized content fetch timed out after \(timeout)s")
            fetchTask.cancel()
            return nil
        }
    }
    
    // MARK: - Level 2: Cached Generic Content
    
    private func checkCachedGenericContent(
        voice: String,
        date: Date
    ) async -> (audioURL: URL?, content: String?, fallbackLevel: FallbackLevel)? {
        
        // Check for date-based generic audio cache
        let audioService = AudioService.shared
        if let cachedURL = audioService.getCachedAudioURL(for: date, voice: voice) {
            if await verifyAudioPlayable(cachedURL) {
                print("✅ Found cached generic content for voice \(voice)")
                return (cachedURL, getGenericScript(voice: voice), .genericCached)
            }
        }
        
        return nil
    }
    
    // MARK: - Level 3: Bundled Generic Audio
    
    private func getBundledGenericAudio(voice: String) -> URL? {
        // Map voice preference to bundled audio files
        let voiceFileMap: [String: String] = [
            "voice1": "ai_wakeup_generic_voice1",
            "voice2": "ai_wakeup_generic_voice2",
            "voice3": "ai_wakeup_generic_voice3",
            "male": "ai_wakeup_generic_voice1",
            "female": "ai_wakeup_generic_voice2",
            "neutral": "ai_wakeup_generic_voice3"
        ]
        
        let fileName = voiceFileMap[voice] ?? "ai_wakeup_generic_voice1"
        
        // Try multiple extensions
        let extensions = ["aac", "mp3", "m4a"]
        for ext in extensions {
            if let url = Bundle.main.url(forResource: fileName, withExtension: ext) {
                print("✅ Using bundled generic audio: \(fileName).\(ext)")
                return url
            }
        }
        
        print("⚠️ No bundled audio found for voice \(voice)")
        return nil
    }
    
    // MARK: - Helper Methods
    
    private func verifyAudioPlayable(_ url: URL) async -> Bool {
        do {
            let asset = AVAsset(url: url)
            
            // Check if asset is playable
            let isPlayable = try await asset.load(.isPlayable)
            guard isPlayable else {
                print("⚠️ Audio asset is not playable")
                return false
            }
            
            // Check duration
            let duration = try await asset.load(.duration)
            guard duration.seconds > 0 else {
                print("⚠️ Audio asset has zero duration")
                return false
            }
            
            print("✅ Audio verified: \(String(format: "%.1f", duration.seconds))s duration")
            return true
            
        } catch {
            print("❌ Audio verification failed: \(error)")
            return false
        }
    }
    
    private func getGenericScript(voice: String) -> String {
        // Generic wake-up scripts based on voice preference
        let scripts: [String: String] = [
            "voice1": "Good morning! It's time to wake up and start your amazing day. The world is waiting for you!",
            "voice2": "Rise and shine! Today is full of possibilities. Let's make it a great one!",
            "voice3": "Good morning! Your alarm is going off. Time to get up and embrace the day ahead!",
            "male": "Good morning! It's time to wake up and start your amazing day. The world is waiting for you!",
            "female": "Rise and shine! Today is full of possibilities. Let's make it a great one!",
            "neutral": "Good morning! Your alarm is going off. Time to get up and embrace the day ahead!"
        ]
        
        return scripts[voice] ?? "Good morning! Time to wake up!"
    }
    
    private func recordFallbackUsage(_ level: FallbackLevel) {
        lastFallbackLevel = level
        fallbackStats[level, default: 0] += 1
        
        // Log analytics
        print("📊 Fallback level used: \(level.description)")
        
        // TODO: Send to analytics service
        // AnalyticsService.shared.track(event: "ai_wakeup_fallback", properties: [
        //     "level": level.analyticsName,
        //     "level_index": level.rawValue
        // ])
    }
    
    // MARK: - Timeout Helper
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Statistics
    
    /// Get fallback usage statistics
    func getFallbackStatistics() -> [(level: FallbackLevel, count: Int, percentage: Double)] {
        let total = fallbackStats.values.reduce(0, +)
        guard total > 0 else { return [] }
        
        return FallbackLevel.allCases.map { level in
            let count = fallbackStats[level, default: 0]
            let percentage = Double(count) / Double(total) * 100
            return (level: level, count: count, percentage: percentage)
        }
    }
    
    /// Reset fallback statistics
    func resetStatistics() {
        for level in FallbackLevel.allCases {
            fallbackStats[level] = 0
        }
        lastFallbackLevel = nil
    }
}

// MARK: - Errors

private struct TimeoutError: Error {
    var localizedDescription: String {
        return "Operation timed out"
    }
}