//
//  ContentMetrics.swift
//  BananaClock
//
//  Analytics and performance tracking for AI wake-up content system
//  Provides comprehensive metrics for monitoring and optimization
//

import Foundation

// MARK: - Content Fetch Metrics

/// Metrics for tracking content fetching performance
struct ContentFetchMetrics: Codable, Sendable {
    let requestId: UUID
    let userId: UUID
    let contentType: String
    let startTime: Date
    let endTime: Date?
    let success: Bool
    let errorType: String?
    let errorMessage: String?
    let httpStatusCode: Int?
    let responseSize: Int?
    let cacheHit: Bool
    let retryCount: Int
    let networkType: NetworkType?
    
    /// Duration of the fetch operation in seconds
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// Whether the operation completed within acceptable time limits
    var isWithinSLA: Bool {
        guard let duration = duration else { return false }
        return duration <= 30.0 // 30 second SLA for content fetching
    }
    
    init(
        requestId: UUID = UUID(),
        userId: UUID,
        contentType: String,
        startTime: Date = Date(),
        cacheHit: Bool = false,
        networkType: NetworkType? = nil
    ) {
        self.requestId = requestId
        self.userId = userId
        self.contentType = contentType
        self.startTime = startTime
        self.endTime = nil
        self.success = false
        self.errorType = nil
        self.errorMessage = nil
        self.httpStatusCode = nil
        self.responseSize = nil
        self.cacheHit = cacheHit
        self.retryCount = 0
        self.networkType = networkType
    }
}

// MARK: - Audio Download Metrics

/// Metrics for tracking audio download performance
struct AudioDownloadMetrics: Codable, Sendable {
    let downloadId: UUID
    let audioUrl: String
    let startTime: Date
    let endTime: Date?
    let success: Bool
    let fileSizeBytes: Int?
    let downloadSpeedBytesPerSecond: Double?
    let errorType: String?
    let httpStatusCode: Int?
    let timeoutOccurred: Bool
    let retryAttempts: Int
    let connectionType: ConnectionType?
    
    /// Duration of the download in seconds
    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
    
    /// Download speed in MB/s
    var downloadSpeedMBps: Double? {
        guard let speed = downloadSpeedBytesPerSecond else { return nil }
        return speed / (1024 * 1024)
    }
    
    /// Whether download completed within SLA (30 seconds)
    var isWithinSLA: Bool {
        guard let duration = duration else { return false }
        return duration <= 30.0
    }
    
    init(
        downloadId: UUID = UUID(),
        audioUrl: String,
        startTime: Date = Date(),
        connectionType: ConnectionType? = nil
    ) {
        self.downloadId = downloadId
        self.audioUrl = audioUrl
        self.startTime = startTime
        self.endTime = nil
        self.success = false
        self.fileSizeBytes = nil
        self.downloadSpeedBytesPerSecond = nil
        self.errorType = nil
        self.httpStatusCode = nil
        self.timeoutOccurred = false
        self.retryAttempts = 0
        self.connectionType = connectionType
    }
}

// MARK: - Cache Performance Metrics

/// Metrics for tracking cache performance
struct CachePerformanceMetrics: Codable, Sendable {
    let operationType: CacheOperation
    let cacheKey: String
    let startTime: Date
    let endTime: Date?
    let success: Bool
    let fileSizeBytes: Int?
    let errorType: String?
    let cacheLocation: CacheLocation
    
    /// Duration of cache operation in milliseconds
    var durationMs: Double? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime) * 1000
    }
    
    /// Whether operation completed within SLA (500ms)
    var isWithinSLA: Bool {
        guard let durationMs = durationMs else { return false }
        return durationMs <= 500.0
    }
    
    init(
        operationType: CacheOperation,
        cacheKey: String,
        startTime: Date = Date(),
        cacheLocation: CacheLocation = .documents
    ) {
        self.operationType = operationType
        self.cacheKey = cacheKey
        self.startTime = startTime
        self.endTime = nil
        self.success = false
        self.fileSizeBytes = nil
        self.errorType = nil
        self.cacheLocation = cacheLocation
    }
}

// MARK: - Push Notification Metrics

/// Metrics for tracking push notification handling
struct PushNotificationMetrics: Codable, Sendable {
    let notificationId: UUID
    let userId: UUID
    let receivedAt: Date
    let processedAt: Date?
    let success: Bool
    let backgroundTimeAvailable: TimeInterval?
    let backgroundTimeUsed: TimeInterval?
    let contentPrefetched: Bool
    let errorType: String?
    let appState: AIAppState
    
    /// Processing duration in seconds
    var processingDuration: TimeInterval? {
        guard let processedAt = processedAt else { return nil }
        return processedAt.timeIntervalSince(receivedAt)
    }
    
    /// Whether processing completed within background time limit
    var completedWithinBackgroundLimit: Bool {
        guard let duration = processingDuration,
              let available = backgroundTimeAvailable else { return false }
        return duration <= available
    }
    
    init(
        notificationId: UUID = UUID(),
        userId: UUID,
        receivedAt: Date = Date(),
        appState: AIAppState
    ) {
        self.notificationId = notificationId
        self.userId = userId
        self.receivedAt = receivedAt
        self.processedAt = nil
        self.success = false
        self.backgroundTimeAvailable = nil
        self.backgroundTimeUsed = nil
        self.contentPrefetched = false
        self.errorType = nil
        self.appState = appState
    }
}

// MARK: - Alarm Playback Metrics

/// Metrics for tracking alarm playback success and fallbacks
struct AlarmPlaybackMetrics: Codable, Sendable {
    let alarmId: UUID
    let userId: UUID
    let scheduledTime: Date
    let actualTriggerTime: Date
    let playbackStartTime: Date?
    let playbackType: PlaybackType
    let audioSource: AudioSource
    let success: Bool
    let fallbackUsed: Bool
    let fallbackReason: String?
    let audioMixingSuccess: Bool?
    let volumeLevel: Float?
    let errorType: String?
    
    /// Delay between scheduled and actual trigger time
    var triggerDelay: TimeInterval {
        return actualTriggerTime.timeIntervalSince(scheduledTime)
    }
    
    /// Time from trigger to playback start
    var playbackLatency: TimeInterval? {
        guard let playbackStart = playbackStartTime else { return nil }
        return playbackStart.timeIntervalSince(actualTriggerTime)
    }
    
    /// Whether alarm triggered within acceptable delay (5 seconds)
    var triggeredOnTime: Bool {
        return abs(triggerDelay) <= 5.0
    }
    
    init(
        alarmId: UUID,
        userId: UUID,
        scheduledTime: Date,
        actualTriggerTime: Date = Date()
    ) {
        self.alarmId = alarmId
        self.userId = userId
        self.scheduledTime = scheduledTime
        self.actualTriggerTime = actualTriggerTime
        self.playbackStartTime = nil
        self.playbackType = .aiWakeUp
        self.audioSource = .cached
        self.success = false
        self.fallbackUsed = false
        self.fallbackReason = nil
        self.audioMixingSuccess = nil
        self.volumeLevel = nil
        self.errorType = nil
    }
}

// MARK: - Supporting Enums

enum NetworkType: String, Codable, CaseIterable, Sendable {
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case unknown = "unknown"
}

enum ConnectionType: String, Codable, CaseIterable, Sendable {
    case wifi = "wifi"
    case cellular4G = "4g"
    case cellular5G = "5g"
    case cellularLTE = "lte"
    case cellularEdge = "edge"
    case unknown = "unknown"
}

enum CacheOperation: String, Codable, CaseIterable, Sendable {
    case read = "read"
    case write = "write"
    case delete = "delete"
    case cleanup = "cleanup"
}

enum CacheLocation: String, Codable, CaseIterable, Sendable {
    case documents = "documents"
    case temp = "temp"
    case caches = "caches"
}

enum AIAppState: String, Codable, CaseIterable, Sendable {
    case active = "active"
    case inactive = "inactive"
    case background = "background"
    case terminated = "terminated"
}

enum PlaybackType: String, Codable, CaseIterable, Sendable {
    case aiWakeUp = "ai_wakeup"
    case generic = "generic"
    case standard = "standard"
}

enum AudioSource: String, Codable, CaseIterable, Sendable {
    case cached = "cached"
    case downloaded = "downloaded"
    case fallback = "fallback"
    case bundle = "bundle"
}

// MARK: - Aggregated Metrics

/// Aggregated metrics for dashboard display
struct AggregatedMetrics: Codable, Sendable {
    let timeRange: TimeRange
    let totalContentRequests: Int
    let successfulContentFetches: Int
    let averageContentFetchDuration: TimeInterval
    let cacheHitRate: Double
    let totalAudioDownloads: Int
    let successfulAudioDownloads: Int
    let averageDownloadSpeed: Double
    let totalAlarmTriggers: Int
    let successfulAlarmPlaybacks: Int
    let fallbackUsageRate: Double
    let averageAlarmLatency: TimeInterval
    
    /// Content fetch success rate as percentage
    var contentFetchSuccessRate: Double {
        guard totalContentRequests > 0 else { return 0.0 }
        return Double(successfulContentFetches) / Double(totalContentRequests) * 100.0
    }
    
    /// Audio download success rate as percentage
    var audioDownloadSuccessRate: Double {
        guard totalAudioDownloads > 0 else { return 0.0 }
        return Double(successfulAudioDownloads) / Double(totalAudioDownloads) * 100.0
    }
    
    /// Alarm playback success rate as percentage
    var alarmPlaybackSuccessRate: Double {
        guard totalAlarmTriggers > 0 else { return 0.0 }
        return Double(successfulAlarmPlaybacks) / Double(totalAlarmTriggers) * 100.0
    }
    
    /// Overall system health score (0-100)
    var healthScore: Double {
        let contentScore = contentFetchSuccessRate * 0.3
        let downloadScore = audioDownloadSuccessRate * 0.3
        let playbackScore = alarmPlaybackSuccessRate * 0.4
        return contentScore + downloadScore + playbackScore
    }
}

enum TimeRange: String, Codable, CaseIterable, Sendable {
    case last24Hours = "24h"
    case last7Days = "7d"
    case last30Days = "30d"
    case allTime = "all"
}

// MARK: - Metrics Collection Protocol

/// Protocol for collecting and reporting metrics
protocol MetricsCollector: Sendable {
    func recordContentFetchMetrics(_ metrics: ContentFetchMetrics) async
    func recordAudioDownloadMetrics(_ metrics: AudioDownloadMetrics) async
    func recordCacheMetrics(_ metrics: CachePerformanceMetrics) async
    func recordPushNotificationMetrics(_ metrics: PushNotificationMetrics) async
    func recordAlarmPlaybackMetrics(_ metrics: AlarmPlaybackMetrics) async
    func getAggregatedMetrics(for timeRange: TimeRange) async -> AggregatedMetrics?
}

// MARK: - Performance Thresholds

/// Performance thresholds for monitoring and alerting
struct PerformanceThresholds {
    static let contentFetchTimeout: TimeInterval = 30.0
    static let audioDownloadTimeout: TimeInterval = 30.0
    static let cacheOperationTimeout: TimeInterval = 0.5
    static let alarmTriggerTolerance: TimeInterval = 5.0
    static let minimumSuccessRate: Double = 95.0
    static let minimumHealthScore: Double = 90.0
    static let maximumFallbackRate: Double = 10.0
    
    /// Check if metrics meet performance requirements
    static func validateMetrics(_ metrics: AggregatedMetrics) -> [String] {
        var issues: [String] = []
        
        if metrics.contentFetchSuccessRate < minimumSuccessRate {
            issues.append("Content fetch success rate below threshold: \(metrics.contentFetchSuccessRate)%")
        }
        
        if metrics.audioDownloadSuccessRate < minimumSuccessRate {
            issues.append("Audio download success rate below threshold: \(metrics.audioDownloadSuccessRate)%")
        }
        
        if metrics.alarmPlaybackSuccessRate < minimumSuccessRate {
            issues.append("Alarm playback success rate below threshold: \(metrics.alarmPlaybackSuccessRate)%")
        }
        
        if metrics.fallbackUsageRate > maximumFallbackRate {
            issues.append("Fallback usage rate above threshold: \(metrics.fallbackUsageRate)%")
        }
        
        if metrics.healthScore < minimumHealthScore {
            issues.append("Overall health score below threshold: \(metrics.healthScore)")
        }
        
        return issues
    }
}