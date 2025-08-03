//
//  ContentMetricsTests.swift
//  BananaClockTests
//
//  Comprehensive tests for metrics tracking and performance monitoring
//  Validates all metric calculations and thresholds
//

import XCTest
@testable import BananaClock

final class ContentMetricsTests: XCTestCase {
    
    // MARK: - ContentFetchMetrics Tests
    
    func testContentFetchMetricsInitialization() {
        let userId = UUID()
        let metrics = ContentFetchMetrics(
            userId: userId,
            contentType: "banana",
            cacheHit: false,
            networkType: .wifi
        )
        
        XCTAssertEqual(metrics.userId, userId)
        XCTAssertEqual(metrics.contentType, "banana")
        XCTAssertFalse(metrics.cacheHit)
        XCTAssertEqual(metrics.networkType, .wifi)
        XCTAssertFalse(metrics.success)
        XCTAssertEqual(metrics.retryCount, 0)
        XCTAssertNil(metrics.endTime)
        XCTAssertNil(metrics.duration)
    }
    
    func testContentFetchMetricsDuration() {
        let userId = UUID()
        var metrics = ContentFetchMetrics(
            userId: userId,
            contentType: "banana"
        )
        
        // Initially no duration
        XCTAssertNil(metrics.duration)
        XCTAssertFalse(metrics.isWithinSLA)
        
        // Simulate completed operation
        let startTime = Date()
        metrics = ContentFetchMetrics(
            requestId: metrics.requestId,
            userId: userId,
            contentType: "banana",
            startTime: startTime,
            endTime: startTime.addingTimeInterval(5.0),
            success: true,
            errorType: nil,
            errorMessage: nil,
            httpStatusCode: 200,
            responseSize: 1024,
            cacheHit: false,
            retryCount: 0,
            networkType: .wifi
        )
        
        XCTAssertEqual(metrics.duration, 5.0, accuracy: 0.1)
        XCTAssertTrue(metrics.isWithinSLA) // 5 seconds is within 30 second SLA
        
        // Test SLA violation
        let slowMetrics = ContentFetchMetrics(
            requestId: metrics.requestId,
            userId: userId,
            contentType: "banana",
            startTime: startTime,
            endTime: startTime.addingTimeInterval(35.0),
            success: true,
            errorType: nil,
            errorMessage: nil,
            httpStatusCode: 200,
            responseSize: 1024,
            cacheHit: false,
            retryCount: 0,
            networkType: .cellular
        )
        
        XCTAssertFalse(slowMetrics.isWithinSLA) // 35 seconds violates 30 second SLA
    }
    
    // MARK: - AudioDownloadMetrics Tests
    
    func testAudioDownloadMetricsInitialization() {
        let metrics = AudioDownloadMetrics(
            audioUrl: "https://example.com/audio.aac",
            connectionType: .wifi
        )
        
        XCTAssertEqual(metrics.audioUrl, "https://example.com/audio.aac")
        XCTAssertEqual(metrics.connectionType, .wifi)
        XCTAssertFalse(metrics.success)
        XCTAssertEqual(metrics.retryAttempts, 0)
        XCTAssertFalse(metrics.timeoutOccurred)
        XCTAssertNil(metrics.endTime)
        XCTAssertNil(metrics.duration)
    }
    
    func testAudioDownloadMetricsPerformanceCalculations() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(10.0)
        let fileSizeBytes = 1024 * 1024 * 5 // 5MB
        
        let metrics = AudioDownloadMetrics(
            downloadId: UUID(),
            audioUrl: "https://example.com/audio.aac",
            startTime: startTime,
            endTime: endTime,
            success: true,
            fileSizeBytes: fileSizeBytes,
            downloadSpeedBytesPerSecond: Double(fileSizeBytes) / 10.0,
            errorType: nil,
            httpStatusCode: 200,
            timeoutOccurred: false,
            retryAttempts: 0,
            connectionType: .wifi
        )
        
        XCTAssertEqual(metrics.duration, 10.0, accuracy: 0.1)
        XCTAssertTrue(metrics.isWithinSLA) // 10 seconds is within 30 second SLA
        
        // Test download speed calculation
        let expectedSpeedMBps = 5.0 / 10.0 // 5MB in 10 seconds = 0.5 MB/s
        XCTAssertEqual(metrics.downloadSpeedMBps, expectedSpeedMBps, accuracy: 0.01)
        
        // Test SLA violation
        let slowMetrics = AudioDownloadMetrics(
            downloadId: UUID(),
            audioUrl: "https://example.com/audio.aac",
            startTime: startTime,
            endTime: startTime.addingTimeInterval(35.0),
            success: true,
            fileSizeBytes: fileSizeBytes,
            downloadSpeedBytesPerSecond: Double(fileSizeBytes) / 35.0,
            errorType: nil,
            httpStatusCode: 200,
            timeoutOccurred: false,
            retryAttempts: 1,
            connectionType: .cellular4G
        )
        
        XCTAssertFalse(slowMetrics.isWithinSLA) // 35 seconds violates SLA
    }
    
    // MARK: - CachePerformanceMetrics Tests
    
    func testCachePerformanceMetricsInitialization() {
        let metrics = CachePerformanceMetrics(
            operationType: .read,
            cacheKey: "test-key",
            cacheLocation: .documents
        )
        
        XCTAssertEqual(metrics.operationType, .read)
        XCTAssertEqual(metrics.cacheKey, "test-key")
        XCTAssertEqual(metrics.cacheLocation, .documents)
        XCTAssertFalse(metrics.success)
        XCTAssertNil(metrics.endTime)
        XCTAssertNil(metrics.durationMs)
    }
    
    func testCachePerformanceMetricsDuration() {
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(0.1) // 100ms
        
        let metrics = CachePerformanceMetrics(
            operationType: .read,
            cacheKey: "test-key",
            startTime: startTime,
            endTime: endTime,
            success: true,
            fileSizeBytes: 1024,
            errorType: nil,
            cacheLocation: .documents
        )
        
        XCTAssertEqual(metrics.durationMs, 100.0, accuracy: 1.0)
        XCTAssertTrue(metrics.isWithinSLA) // 100ms is within 500ms SLA
        
        // Test SLA violation
        let slowMetrics = CachePerformanceMetrics(
            operationType: .write,
            cacheKey: "test-key",
            startTime: startTime,
            endTime: startTime.addingTimeInterval(0.6), // 600ms
            success: true,
            fileSizeBytes: 1024,
            errorType: nil,
            cacheLocation: .temp
        )
        
        XCTAssertFalse(slowMetrics.isWithinSLA) // 600ms violates 500ms SLA
    }
    
    // MARK: - PushNotificationMetrics Tests
    
    func testPushNotificationMetricsInitialization() {
        let userId = UUID()
        let metrics = PushNotificationMetrics(
            userId: userId,
            appState: .background
        )
        
        XCTAssertEqual(metrics.userId, userId)
        XCTAssertEqual(metrics.appState, .background)
        XCTAssertFalse(metrics.success)
        XCTAssertFalse(metrics.contentPrefetched)
        XCTAssertNil(metrics.processedAt)
        XCTAssertNil(metrics.processingDuration)
    }
    
    func testPushNotificationMetricsProcessing() {
        let userId = UUID()
        let receivedAt = Date()
        let processedAt = receivedAt.addingTimeInterval(5.0)
        
        let metrics = PushNotificationMetrics(
            notificationId: UUID(),
            userId: userId,
            receivedAt: receivedAt,
            processedAt: processedAt,
            success: true,
            backgroundTimeAvailable: 30.0,
            backgroundTimeUsed: 5.0,
            contentPrefetched: true,
            errorType: nil,
            appState: .background
        )
        
        XCTAssertEqual(metrics.processingDuration, 5.0, accuracy: 0.1)
        XCTAssertTrue(metrics.completedWithinBackgroundLimit)
        
        // Test background time limit exceeded
        let timeoutMetrics = PushNotificationMetrics(
            notificationId: UUID(),
            userId: userId,
            receivedAt: receivedAt,
            processedAt: receivedAt.addingTimeInterval(35.0),
            success: false,
            backgroundTimeAvailable: 30.0,
            backgroundTimeUsed: 30.0,
            contentPrefetched: false,
            errorType: "timeout",
            appState: .background
        )
        
        XCTAssertFalse(timeoutMetrics.completedWithinBackgroundLimit)
    }
    
    // MARK: - AlarmPlaybackMetrics Tests
    
    func testAlarmPlaybackMetricsInitialization() {
        let alarmId = UUID()
        let userId = UUID()
        let scheduledTime = Date()
        
        let metrics = AlarmPlaybackMetrics(
            alarmId: alarmId,
            userId: userId,
            scheduledTime: scheduledTime
        )
        
        XCTAssertEqual(metrics.alarmId, alarmId)
        XCTAssertEqual(metrics.userId, userId)
        XCTAssertEqual(metrics.scheduledTime, scheduledTime)
        XCTAssertEqual(metrics.playbackType, .aiWakeUp)
        XCTAssertEqual(metrics.audioSource, .cached)
        XCTAssertFalse(metrics.success)
        XCTAssertFalse(metrics.fallbackUsed)
    }
    
    func testAlarmPlaybackMetricsTiming() {
        let alarmId = UUID()
        let userId = UUID()
        let scheduledTime = Date()
        let actualTriggerTime = scheduledTime.addingTimeInterval(2.0) // 2 second delay
        let playbackStartTime = actualTriggerTime.addingTimeInterval(0.5) // 500ms latency
        
        let metrics = AlarmPlaybackMetrics(
            alarmId: alarmId,
            userId: userId,
            scheduledTime: scheduledTime,
            actualTriggerTime: actualTriggerTime,
            playbackStartTime: playbackStartTime,
            playbackType: .aiWakeUp,
            audioSource: .cached,
            success: true,
            fallbackUsed: false,
            fallbackReason: nil,
            audioMixingSuccess: true,
            volumeLevel: 0.8,
            errorType: nil
        )
        
        XCTAssertEqual(metrics.triggerDelay, 2.0, accuracy: 0.1)
        XCTAssertEqual(metrics.playbackLatency, 0.5, accuracy: 0.1)
        XCTAssertTrue(metrics.triggeredOnTime) // 2 seconds is within 5 second tolerance
        
        // Test late trigger
        let lateMetrics = AlarmPlaybackMetrics(
            alarmId: alarmId,
            userId: userId,
            scheduledTime: scheduledTime,
            actualTriggerTime: scheduledTime.addingTimeInterval(10.0) // 10 second delay
        )
        
        XCTAssertFalse(lateMetrics.triggeredOnTime) // 10 seconds exceeds 5 second tolerance
    }
    
    // MARK: - AggregatedMetrics Tests
    
    func testAggregatedMetricsCalculations() {
        let metrics = AggregatedMetrics(
            timeRange: .last24Hours,
            totalContentRequests: 100,
            successfulContentFetches: 95,
            averageContentFetchDuration: 2.5,
            cacheHitRate: 0.8,
            totalAudioDownloads: 80,
            successfulAudioDownloads: 75,
            averageDownloadSpeed: 2.5,
            totalAlarmTriggers: 90,
            successfulAlarmPlaybacks: 88,
            fallbackUsageRate: 0.05,
            averageAlarmLatency: 0.3
        )
        
        XCTAssertEqual(metrics.contentFetchSuccessRate, 95.0, accuracy: 0.1)
        XCTAssertEqual(metrics.audioDownloadSuccessRate, 93.75, accuracy: 0.1)
        XCTAssertEqual(metrics.alarmPlaybackSuccessRate, 97.78, accuracy: 0.1)
        
        // Health score calculation: 95*0.3 + 93.75*0.3 + 97.78*0.4 = 95.737
        XCTAssertEqual(metrics.healthScore, 95.737, accuracy: 0.1)
    }
    
    func testAggregatedMetricsEdgeCases() {
        // Test zero totals
        let zeroMetrics = AggregatedMetrics(
            timeRange: .last7Days,
            totalContentRequests: 0,
            successfulContentFetches: 0,
            averageContentFetchDuration: 0,
            cacheHitRate: 0,
            totalAudioDownloads: 0,
            successfulAudioDownloads: 0,
            averageDownloadSpeed: 0,
            totalAlarmTriggers: 0,
            successfulAlarmPlaybacks: 0,
            fallbackUsageRate: 0,
            averageAlarmLatency: 0
        )
        
        XCTAssertEqual(zeroMetrics.contentFetchSuccessRate, 0.0)
        XCTAssertEqual(zeroMetrics.audioDownloadSuccessRate, 0.0)
        XCTAssertEqual(zeroMetrics.alarmPlaybackSuccessRate, 0.0)
        XCTAssertEqual(zeroMetrics.healthScore, 0.0)
    }
    
    // MARK: - PerformanceThresholds Tests
    
    func testPerformanceThresholdsValidation() {
        // Test metrics that meet all thresholds
        let goodMetrics = AggregatedMetrics(
            timeRange: .last24Hours,
            totalContentRequests: 100,
            successfulContentFetches: 96,
            averageContentFetchDuration: 2.0,
            cacheHitRate: 0.9,
            totalAudioDownloads: 80,
            successfulAudioDownloads: 77,
            averageDownloadSpeed: 3.0,
            totalAlarmTriggers: 90,
            successfulAlarmPlaybacks: 87,
            fallbackUsageRate: 0.05,
            averageAlarmLatency: 0.2
        )
        
        let issues = PerformanceThresholds.validateMetrics(goodMetrics)
        XCTAssertTrue(issues.isEmpty)
        
        // Test metrics that violate thresholds
        let badMetrics = AggregatedMetrics(
            timeRange: .last24Hours,
            totalContentRequests: 100,
            successfulContentFetches: 90, // Below 95% threshold
            averageContentFetchDuration: 2.0,
            cacheHitRate: 0.9,
            totalAudioDownloads: 80,
            successfulAudioDownloads: 70, // Below 95% threshold
            averageDownloadSpeed: 3.0,
            totalAlarmTriggers: 90,
            successfulAlarmPlaybacks: 80, // Below 95% threshold
            fallbackUsageRate: 0.15, // Above 10% threshold
            averageAlarmLatency: 0.2
        )
        
        let badIssues = PerformanceThresholds.validateMetrics(badMetrics)
        XCTAssertEqual(badIssues.count, 4) // Should have 4 issues
        
        XCTAssertTrue(badIssues.contains { $0.contains("Content fetch success rate") })
        XCTAssertTrue(badIssues.contains { $0.contains("Audio download success rate") })
        XCTAssertTrue(badIssues.contains { $0.contains("Alarm playback success rate") })
        XCTAssertTrue(badIssues.contains { $0.contains("Fallback usage rate") })
    }
    
    // MARK: - Enum Tests
    
    func testNetworkTypeEnum() {
        let allCases = NetworkType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.wifi))
        XCTAssertTrue(allCases.contains(.cellular))
        XCTAssertTrue(allCases.contains(.ethernet))
        XCTAssertTrue(allCases.contains(.unknown))
    }
    
    func testConnectionTypeEnum() {
        let allCases = ConnectionType.allCases
        XCTAssertEqual(allCases.count, 6)
        XCTAssertTrue(allCases.contains(.wifi))
        XCTAssertTrue(allCases.contains(.cellular4G))
        XCTAssertTrue(allCases.contains(.cellular5G))
        XCTAssertTrue(allCases.contains(.cellularLTE))
        XCTAssertTrue(allCases.contains(.cellularEdge))
        XCTAssertTrue(allCases.contains(.unknown))
    }
    
    func testCacheOperationEnum() {
        let allCases = CacheOperation.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.read))
        XCTAssertTrue(allCases.contains(.write))
        XCTAssertTrue(allCases.contains(.delete))
        XCTAssertTrue(allCases.contains(.cleanup))
    }
    
    func testAIAppStateEnum() {
        let allCases = AIAppState.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.active))
        XCTAssertTrue(allCases.contains(.inactive))
        XCTAssertTrue(allCases.contains(.background))
        XCTAssertTrue(allCases.contains(.terminated))
    }
    
    func testPlaybackTypeEnum() {
        let allCases = PlaybackType.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.aiWakeUp))
        XCTAssertTrue(allCases.contains(.generic))
        XCTAssertTrue(allCases.contains(.standard))
    }
    
    func testAudioSourceEnum() {
        let allCases = AudioSource.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.cached))
        XCTAssertTrue(allCases.contains(.downloaded))
        XCTAssertTrue(allCases.contains(.fallback))
        XCTAssertTrue(allCases.contains(.bundle))
    }
    
    func testTimeRangeEnum() {
        let allCases = TimeRange.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.last24Hours))
        XCTAssertTrue(allCases.contains(.last7Days))
        XCTAssertTrue(allCases.contains(.last30Days))
        XCTAssertTrue(allCases.contains(.allTime))
    }
    
    // MARK: - Sendable Conformance Tests
    
    func testMetricsSendableConformance() async {
        let userId = UUID()
        let fetchMetrics = ContentFetchMetrics(userId: userId, contentType: "banana")
        let downloadMetrics = AudioDownloadMetrics(audioUrl: "https://example.com/audio.aac")
        let cacheMetrics = CachePerformanceMetrics(operationType: .read, cacheKey: "test")
        let pushMetrics = PushNotificationMetrics(userId: userId, appState: .background)
        let alarmMetrics = AlarmPlaybackMetrics(alarmId: UUID(), userId: userId, scheduledTime: Date())
        
        // Test that all metrics can be safely passed across concurrency boundaries
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = fetchMetrics.userId
            }
            group.addTask {
                _ = downloadMetrics.audioUrl
            }
            group.addTask {
                _ = cacheMetrics.operationType
            }
            group.addTask {
                _ = pushMetrics.appState
            }
            group.addTask {
                _ = alarmMetrics.alarmId
            }
        }
    }
}