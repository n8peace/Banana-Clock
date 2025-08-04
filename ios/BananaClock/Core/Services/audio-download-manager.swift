//
//  AudioDownloadManager.swift
//  BananaClock
//
//  Manages downloading and caching of AI-generated audio content
//  Handles real-time audio fetching for alarms with proper fallback
//

import Foundation
import SwiftUI
import AVFoundation

@MainActor
class AudioDownloadManager: ObservableObject {
    static let shared = AudioDownloadManager()
    
    @Published var activeDownloads: [UUID: DownloadProgress] = [:]
    @Published var downloadHistory: [DownloadRecord] = []
    @Published var cacheSize: Int64 = 0
    
    private let cacheDirectory: URL
    private let maxCacheSize: Int64 = 500 * 1024 * 1024 // 500MB
    private let downloadTimeout: TimeInterval = 30 // 30 seconds
    
    // Performance monitoring
    private var downloadMetrics: [UUID: DownloadMetrics] = [:]
    
    private init() {
        // Create cache directory in Documents/AIAudio
        let documentsPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0]
        
        cacheDirectory = documentsPath.appendingPathComponent("AIAudio")
        
        setupCacheDirectory()
        calculateCacheSize()
    }
    
    // MARK: - Cache Directory Setup
    
    private func setupCacheDirectory() {
        do {
            try FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            print("✅ Audio cache directory created: \(cacheDirectory)")
        } catch {
            print("❌ Failed to create audio cache directory: \(error)")
        }
    }
    
    private func calculateCacheSize() {
        Task {
            do {
                let contents = try FileManager.default.contentsOfDirectory(
                    at: cacheDirectory,
                    includingPropertiesForKeys: [.fileSizeKey],
                    options: .skipsHiddenFiles
                )
                
                let totalSize = contents.reduce(Int64(0)) { size, url in
                    do {
                        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                        return size + Int64(resourceValues.fileSize ?? 0)
                    } catch {
                        return size
                    }
                }
                
                await MainActor.run {
                    cacheSize = totalSize
                }
                
                print("📊 Audio cache size: \(formatBytes(totalSize))")
                
            } catch {
                print("❌ Failed to calculate cache size: \(error)")
            }
        }
    }
    
    // MARK: - Audio Download
    
    /// Download audio for a content block with performance monitoring
    func downloadAudio(for contentBlockId: UUID, audioUrl: String) async throws -> URL {
        print("🔄 Starting audio download for content block \(contentBlockId)")
        
        let startTime = Date()
        let metrics = DownloadMetrics(
            contentBlockId: contentBlockId,
            startTime: startTime,
            url: audioUrl
        )
        
        // Update UI
        await MainActor.run {
            activeDownloads[contentBlockId] = DownloadProgress(
                contentBlockId: contentBlockId,
                progress: 0.0,
                startTime: startTime
            )
            downloadMetrics[contentBlockId] = metrics
        }
        
        do {
            let localURL = try await performDownload(
                contentBlockId: contentBlockId,
                audioUrl: audioUrl
            )
            
            // Record successful download
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)
            
            await recordDownloadSuccess(
                contentBlockId: contentBlockId,
                localURL: localURL,
                duration: duration,
                audioUrl: audioUrl
            )
            
            print("✅ Audio download completed in \(String(format: "%.2f", duration))s")
            return localURL
            
        } catch {
            // Record failed download
            await recordDownloadFailure(
                contentBlockId: contentBlockId,
                error: error,
                audioUrl: audioUrl
            )
            
            throw error
        }
    }
    
    private func performDownload(contentBlockId: UUID, audioUrl: String) async throws -> URL {
        guard let url = URL(string: audioUrl) else {
            throw AudioDownloadError.invalidURL
        }
        
        // Check if already cached
        let cachedURL = getCachedAudioURL(for: contentBlockId)
        if FileManager.default.fileExists(atPath: cachedURL.path) {
            print("✅ Audio already cached: \(cachedURL)")
            return cachedURL
        }
        
        // Create URLSession with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = downloadTimeout
        config.timeoutIntervalForResource = downloadTimeout * 2
        let session = URLSession(configuration: config)
        
        print("🌐 Downloading from: \(audioUrl)")
        
        // Perform download with progress tracking
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AudioDownloadError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw AudioDownloadError.httpError(httpResponse.statusCode)
        }
        
        // Validate audio data
        try validateAudioData(data)
        
        // Save to cache
        try data.write(to: cachedURL)
        
        // Update cache size
        await updateCacheSize(adding: Int64(data.count))
        
        // Validate audio file can be played
        try await validateAudioFile(cachedURL)
        
        return cachedURL
    }
    
    private func validateAudioData(_ data: Data) throws {
        // Check minimum file size (should be at least 1KB for valid audio)
        guard data.count >= 1024 else {
            throw AudioDownloadError.invalidAudioData("File too small: \(data.count) bytes")
        }
        
        // Check maximum file size (should not exceed 50MB)
        guard data.count <= 50 * 1024 * 1024 else {
            throw AudioDownloadError.invalidAudioData("File too large: \(formatBytes(Int64(data.count)))")
        }
        
        print("✅ Audio data validation passed: \(formatBytes(Int64(data.count)))")
    }
    
    private func validateAudioFile(_ url: URL) async throws {
        // Validate that AVPlayer can load the audio file
        let player = AVPlayer(url: url)
        
        do {
            let status = try await player.currentItem?.asset.load(.duration)
            guard let duration = status, duration.seconds > 0 else {
                throw AudioDownloadError.invalidAudioData("Audio file cannot be played")
            }
            
            print("✅ Audio file validation passed: \(String(format: "%.1f", duration.seconds))s duration")
        } catch {
            throw AudioDownloadError.invalidAudioData("Audio validation failed: \(error)")
        }
    }
    
    // MARK: - Cache Management
    
    private func getCachedAudioURL(for contentBlockId: UUID) -> URL {
        return cacheDirectory.appendingPathComponent("\(contentBlockId.uuidString).aac")
    }
    
    /// Get cached audio file if available and valid
    func getCachedAudio(for contentBlockId: UUID) -> URL? {
        let cachedURL = getCachedAudioURL(for: contentBlockId)
        
        guard FileManager.default.fileExists(atPath: cachedURL.path) else {
            return nil
        }
        
        // Check if file is still valid (not corrupted)
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: cachedURL.path)
            let fileSize = attributes[.size] as? Int64 ?? 0
            
            // Basic validation - file should be at least 1KB
            guard fileSize >= 1024 else {
                print("⚠️ Cached audio file is too small, removing: \(cachedURL)")
                try? FileManager.default.removeItem(at: cachedURL)
                return nil
            }
            
            return cachedURL
        } catch {
            print("❌ Error checking cached audio file: \(error)")
            return nil
        }
    }
    
    private func updateCacheSize(adding bytes: Int64) async {
        await MainActor.run {
            cacheSize += bytes
        }
        
        // Check if we need to clean up cache
        if cacheSize > maxCacheSize {
            await cleanupCache()
        }
    }
    
    private func cleanupCache() async {
        print("🧹 Cache size exceeded \(formatBytes(maxCacheSize)), cleaning up...")
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: .skipsHiddenFiles
            )
            
            // Sort by modification date (oldest first)
            let sortedContents = contents.sorted { url1, url2 in
                do {
                    let date1 = try url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                    let date2 = try url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate ?? Date.distantPast
                    return date1 < date2
                } catch {
                    return false
                }
            }
            
            var cleanedSize: Int64 = 0
            let targetCleanupSize = maxCacheSize / 4 // Clean up 25% of max size
            
            for url in sortedContents {
                if cleanedSize >= targetCleanupSize {
                    break
                }
                
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                    let fileSize = Int64(resourceValues.fileSize ?? 0)
                    
                    try FileManager.default.removeItem(at: url)
                    cleanedSize += fileSize
                    
                    print("🗑️ Removed cached file: \(url.lastPathComponent)")
                } catch {
                    print("❌ Failed to remove cached file: \(error)")
                }
            }
            
            await MainActor.run {
                cacheSize -= cleanedSize
            }
            
            print("✅ Cache cleanup completed, freed \(formatBytes(cleanedSize))")
            
        } catch {
            print("❌ Cache cleanup failed: \(error)")
        }
    }
    
    // MARK: - Progress Tracking
    
    private func updateDownloadProgress(_ contentBlockId: UUID, progress: Double) async {
        await MainActor.run {
            activeDownloads[contentBlockId]?.progress = progress
        }
    }
    
    private func recordDownloadSuccess(
        contentBlockId: UUID,
        localURL: URL,
        duration: TimeInterval,
        audioUrl: String
    ) async {
        await MainActor.run {
            activeDownloads.removeValue(forKey: contentBlockId)
            
            let record = DownloadRecord(
                contentBlockId: contentBlockId,
                status: .completed,
                downloadTime: duration,
                fileSize: getFileSize(localURL),
                audioUrl: audioUrl,
                localURL: localURL,
                timestamp: Date(),
                error: nil
            )
            
            downloadHistory.append(record)
            
            // Keep only last 100 records
            if downloadHistory.count > 100 {
                downloadHistory = Array(downloadHistory.suffix(100))
            }
        }
    }
    
    private func recordDownloadFailure(
        contentBlockId: UUID,
        error: Error,
        audioUrl: String
    ) async {
        await MainActor.run {
            activeDownloads.removeValue(forKey: contentBlockId)
            
            let record = DownloadRecord(
                contentBlockId: contentBlockId,
                status: .failed,
                downloadTime: 0,
                fileSize: 0,
                audioUrl: audioUrl,
                localURL: nil,
                timestamp: Date(),
                error: error
            )
            
            downloadHistory.append(record)
        }
    }
    
    // MARK: - Utilities
    
    private func getFileSize(_ url: URL) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Public Interface
    
    /// Check if audio is available for a content block
    func isAudioAvailable(for contentBlockId: UUID) -> Bool {
        return getCachedAudio(for: contentBlockId) != nil
    }
    
    /// Get download progress for a content block
    func getDownloadProgress(for contentBlockId: UUID) -> Double? {
        return activeDownloads[contentBlockId]?.progress
    }
    
    /// Clear all cached audio files
    public func clearCache() async {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            
            for url in contents {
                try FileManager.default.removeItem(at: url)
            }
            
            await MainActor.run {
                cacheSize = 0
                downloadHistory.removeAll()
            }
            
            print("✅ Audio cache cleared")
            
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
    }
}

// MARK: - Models

struct DownloadProgress {
    let contentBlockId: UUID
    var progress: Double
    let startTime: Date
}

struct DownloadRecord: Identifiable {
    let id = UUID()
    let contentBlockId: UUID
    let status: DownloadStatus
    let downloadTime: TimeInterval
    let fileSize: Int64
    let audioUrl: String
    let localURL: URL?
    let timestamp: Date
    let error: Error?
}

struct DownloadMetrics {
    let contentBlockId: UUID
    let startTime: Date
    let url: String
    var endTime: Date?
    var bytesDownloaded: Int64 = 0
    var error: Error?
}

enum DownloadStatus {
    case pending
    case downloading
    case completed
    case failed
}

enum AudioDownloadError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case invalidAudioData(String)
    case downloadTimeout
    case cacheError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid audio URL"
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .invalidAudioData(let reason):
            return "Invalid audio data: \(reason)"
        case .downloadTimeout:
            return "Download timeout"
        case .cacheError:
            return "Cache error"
        }
    }
}