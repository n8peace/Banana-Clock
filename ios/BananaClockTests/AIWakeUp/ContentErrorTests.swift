//
//  ContentErrorTests.swift
//  BananaClockTests
//
//  Comprehensive tests for all error types and recovery strategies
//  Ensures proper error handling and user messaging
//

import XCTest
@testable import BananaClock

final class ContentErrorTests: XCTestCase {
    
    // MARK: - ContentFetchError Tests
    
    func testContentFetchErrorDescriptions() {
        let errors: [ContentFetchError] = [
            .networkUnavailable,
            .authenticationFailed,
            .invalidResponse(Data()),
            .contentNotFound,
            .contentNotReady,
            .downloadTimeout,
            .invalidURL("bad-url"),
            .storageError(underlying: NSError(domain: "test", code: 1)),
            .subscriptionRequired,
            .userNotFound,
            .rateLimitExceeded(retryAfter: 60),
            .serverError(statusCode: 500, message: "Internal Server Error"),
            .decodingError(underlying: NSError(domain: "test", code: 1))
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
            XCTAssertNotNil(error.failureReason)
            XCTAssertFalse(error.failureReason!.isEmpty)
        }
    }
    
    func testContentFetchErrorRecoveryActions() {
        XCTAssertEqual(ContentFetchError.networkUnavailable.recoveryAction.description, "Retry after 5 seconds")
        XCTAssertEqual(ContentFetchError.authenticationFailed.recoveryAction.description, "User intervention required")
        XCTAssertEqual(ContentFetchError.contentNotFound.recoveryAction.description, "Use fallback content")
        XCTAssertEqual(ContentFetchError.contentNotReady.recoveryAction.description, "Retry after 30 seconds")
        XCTAssertEqual(ContentFetchError.subscriptionRequired.recoveryAction.description, "User intervention required")
        
        // Test rate limit with retry after
        let rateLimitError = ContentFetchError.rateLimitExceeded(retryAfter: 120)
        if case .retryWithDelay(let delay) = rateLimitError.recoveryAction {
            XCTAssertEqual(delay, 120)
        } else {
            XCTFail("Expected retryWithDelay recovery action")
        }
        
        // Test rate limit without retry after
        let rateLimitErrorNoRetry = ContentFetchError.rateLimitExceeded(retryAfter: nil)
        if case .retryWithDelay(let delay) = rateLimitErrorNoRetry.recoveryAction {
            XCTAssertEqual(delay, 60.0)
        } else {
            XCTFail("Expected retryWithDelay recovery action with default delay")
        }
    }
    
    func testContentFetchErrorShouldUseFallback() {
        XCTAssertTrue(ContentFetchError.contentNotFound.shouldUseFallback)
        XCTAssertTrue(ContentFetchError.contentNotReady.shouldUseFallback)
        XCTAssertTrue(ContentFetchError.invalidURL("bad-url").shouldUseFallback)
        XCTAssertTrue(ContentFetchError.subscriptionRequired.shouldUseFallback)
        
        XCTAssertFalse(ContentFetchError.networkUnavailable.shouldUseFallback)
        XCTAssertFalse(ContentFetchError.downloadTimeout.shouldUseFallback)
        
        // Test server error codes
        XCTAssertFalse(ContentFetchError.serverError(statusCode: 500, message: nil).shouldUseFallback)
        XCTAssertTrue(ContentFetchError.serverError(statusCode: 400, message: nil).shouldUseFallback)
    }
    
    func testContentFetchErrorIsRecoverable() {
        XCTAssertTrue(ContentFetchError.networkUnavailable.isRecoverable)
        XCTAssertTrue(ContentFetchError.downloadTimeout.isRecoverable)
        XCTAssertTrue(ContentFetchError.contentNotReady.isRecoverable)
        XCTAssertTrue(ContentFetchError.rateLimitExceeded(retryAfter: 60).isRecoverable)
        
        XCTAssertFalse(ContentFetchError.authenticationFailed.isRecoverable)
        XCTAssertFalse(ContentFetchError.contentNotFound.isRecoverable)
        XCTAssertFalse(ContentFetchError.invalidURL("bad-url").isRecoverable)
        XCTAssertFalse(ContentFetchError.subscriptionRequired.isRecoverable)
        
        // Test server error codes
        XCTAssertTrue(ContentFetchError.serverError(statusCode: 500, message: nil).isRecoverable)
        XCTAssertFalse(ContentFetchError.serverError(statusCode: 404, message: nil).isRecoverable)
    }
    
    func testContentFetchErrorSpecificMessages() {
        let invalidUrlError = ContentFetchError.invalidURL("https://bad-url")
        XCTAssertTrue(invalidUrlError.errorDescription!.contains("https://bad-url"))
        
        let serverError = ContentFetchError.serverError(statusCode: 500, message: "Custom message")
        XCTAssertEqual(serverError.errorDescription, "Custom message")
        
        let serverErrorNoMessage = ContentFetchError.serverError(statusCode: 404, message: nil)
        XCTAssertEqual(serverErrorNoMessage.errorDescription, "Server error (404)")
        
        let rateLimitWithRetry = ContentFetchError.rateLimitExceeded(retryAfter: 30)
        XCTAssertTrue(rateLimitWithRetry.recoverySuggestion!.contains("30 seconds"))
    }
    
    // MARK: - ContentCacheError Tests
    
    func testContentCacheErrorDescriptions() {
        let errors: [ContentCacheError] = [
            .cacheDirectoryNotFound,
            .fileNotFound(path: "/path/to/file"),
            .corruptedFile(path: "/path/to/file"),
            .diskSpaceInsufficient,
            .permissionDenied,
            .cacheExpired(path: "/path/to/file"),
            .invalidCacheKey
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
        }
    }
    
    // MARK: - AudioProcessingError Tests
    
    func testAudioProcessingErrorDescriptions() {
        let errors: [AudioProcessingError] = [
            .unsupportedFormat(format: "mp3"),
            .fileCorrupted,
            .decodingFailed,
            .playbackFailed(underlying: NSError(domain: "test", code: 1)),
            .mixingFailed,
            .volumeAdjustmentFailed,
            .deviceUnavailable
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
        }
        
        let unsupportedFormatError = AudioProcessingError.unsupportedFormat(format: "wav")
        XCTAssertTrue(unsupportedFormatError.errorDescription!.contains("wav"))
    }
    
    // MARK: - PushNotificationError Tests
    
    func testPushNotificationErrorDescriptions() {
        let errors: [PushNotificationError] = [
            .permissionDenied,
            .tokenRegistrationFailed,
            .invalidPayload,
            .processingTimeout,
            .backgroundTaskFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
        }
    }
    
    // MARK: - ContentGenerationError Tests
    
    func testContentGenerationErrorDescriptions() {
        let errors: [ContentGenerationError] = [
            .scriptGenerationFailed,
            .audioSynthesisFailed,
            .weatherDataUnavailable,
            .headlinesUnavailable,
            .marketDataUnavailable,
            .voiceServiceUnavailable,
            .quotaExceeded,
            .configurationError
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
        }
    }
    
    // MARK: - ErrorRecoveryAction Tests
    
    func testErrorRecoveryActionDescriptions() {
        let actions: [ErrorRecoveryAction] = [
            .retry,
            .retryWithDelay(5.0),
            .useCache,
            .useFallback,
            .skipFeature,
            .requireUserAction,
            .automaticRetry(maxAttempts: 3)
        ]
        
        for action in actions {
            XCTAssertFalse(action.description.isEmpty)
        }
        
        XCTAssertEqual(ErrorRecoveryAction.retry.description, "Retry immediately")
        XCTAssertEqual(ErrorRecoveryAction.retryWithDelay(10).description, "Retry after 10 seconds")
        XCTAssertEqual(ErrorRecoveryAction.automaticRetry(maxAttempts: 5).description, "Automatic retry (max 5 attempts)")
    }
    
    // MARK: - Error Equality Tests
    
    func testContentFetchErrorEquality() {
        // Test that same error types are handled consistently
        let error1 = ContentFetchError.networkUnavailable
        let error2 = ContentFetchError.networkUnavailable
        
        XCTAssertEqual(error1.errorDescription, error2.errorDescription)
        XCTAssertEqual(error1.recoveryAction.description, error2.recoveryAction.description)
    }
    
    // MARK: - Sendable Conformance Tests
    
    func testErrorSendableConformance() async {
        let error = ContentFetchError.networkUnavailable
        
        // Test that errors can be safely passed across concurrency boundaries
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                _ = error.errorDescription
            }
            group.addTask {
                _ = error.recoveryAction
            }
        }
    }
    
    // MARK: - Comprehensive Error Coverage Tests
    
    func testAllErrorTypesHaveDescriptions() {
        // This test ensures we don't miss any error cases
        
        // Test all ContentFetchError cases
        let fetchErrors: [ContentFetchError] = [
            .networkUnavailable,
            .authenticationFailed,
            .invalidResponse(Data()),
            .contentNotFound,
            .contentNotReady,
            .downloadTimeout,
            .invalidURL("test"),
            .storageError(underlying: NSError(domain: "test", code: 1)),
            .subscriptionRequired,
            .userNotFound,
            .rateLimitExceeded(retryAfter: 60),
            .serverError(statusCode: 500, message: nil),
            .decodingError(underlying: NSError(domain: "test", code: 1))
        ]
        
        for error in fetchErrors {
            XCTAssertNotNil(error.errorDescription, "Missing error description for \(error)")
            XCTAssertNotNil(error.recoverySuggestion, "Missing recovery suggestion for \(error)")
            XCTAssertNotNil(error.failureReason, "Missing failure reason for \(error)")
        }
        
        // Test all ContentCacheError cases
        let cacheErrors: [ContentCacheError] = [
            .cacheDirectoryNotFound,
            .fileNotFound(path: "test"),
            .corruptedFile(path: "test"),
            .diskSpaceInsufficient,
            .permissionDenied,
            .cacheExpired(path: "test"),
            .invalidCacheKey
        ]
        
        for error in cacheErrors {
            XCTAssertNotNil(error.errorDescription, "Missing error description for \(error)")
            XCTAssertNotNil(error.recoverySuggestion, "Missing recovery suggestion for \(error)")
        }
        
        // Test all AudioProcessingError cases
        let audioErrors: [AudioProcessingError] = [
            .unsupportedFormat(format: "test"),
            .fileCorrupted,
            .decodingFailed,
            .playbackFailed(underlying: NSError(domain: "test", code: 1)),
            .mixingFailed,
            .volumeAdjustmentFailed,
            .deviceUnavailable
        ]
        
        for error in audioErrors {
            XCTAssertNotNil(error.errorDescription, "Missing error description for \(error)")
            XCTAssertNotNil(error.recoverySuggestion, "Missing recovery suggestion for \(error)")
        }
        
        // Test all PushNotificationError cases
        let pushErrors: [PushNotificationError] = [
            .permissionDenied,
            .tokenRegistrationFailed,
            .invalidPayload,
            .processingTimeout,
            .backgroundTaskFailed
        ]
        
        for error in pushErrors {
            XCTAssertNotNil(error.errorDescription, "Missing error description for \(error)")
            XCTAssertNotNil(error.recoverySuggestion, "Missing recovery suggestion for \(error)")
        }
        
        // Test all ContentGenerationError cases
        let generationErrors: [ContentGenerationError] = [
            .scriptGenerationFailed,
            .audioSynthesisFailed,
            .weatherDataUnavailable,
            .headlinesUnavailable,
            .marketDataUnavailable,
            .voiceServiceUnavailable,
            .quotaExceeded,
            .configurationError
        ]
        
        for error in generationErrors {
            XCTAssertNotNil(error.errorDescription, "Missing error description for \(error)")
            XCTAssertNotNil(error.recoverySuggestion, "Missing recovery suggestion for \(error)")
        }
    }
}