//
//  ContentError.swift
//  BananaClock
//
//  Comprehensive error handling for AI wake-up content system
//  Provides user-friendly messages and actionable recovery suggestions
//

import Foundation

// MARK: - Content Fetch Error

/// Comprehensive error types for content fetching operations
enum ContentFetchError: LocalizedError, Sendable {
    case networkUnavailable
    case authenticationFailed
    case invalidResponse(Data)
    case contentNotFound
    case contentNotReady
    case downloadTimeout
    case invalidURL(String)
    case storageError(underlying: Error)
    case subscriptionRequired
    case userNotFound
    case rateLimitExceeded(retryAfter: TimeInterval?)
    case serverError(statusCode: Int, message: String?)
    case decodingError(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection available"
        case .authenticationFailed:
            return "Authentication failed"
        case .invalidResponse:
            return "Invalid response from server"
        case .contentNotFound:
            return "No AI content available for today"
        case .contentNotReady:
            return "AI content is still being generated"
        case .downloadTimeout:
            return "Download timed out"
        case .invalidURL(let url):
            return "Invalid audio URL: \(url)"
        case .storageError:
            return "Failed to save audio file"
        case .subscriptionRequired:
            return "Banana Plus subscription required"
        case .userNotFound:
            return "User account not found"
        case .rateLimitExceeded:
            return "Too many requests. Please wait."
        case .serverError(let statusCode, let message):
            return message ?? "Server error (\(statusCode))"
        case .decodingError:
            return "Failed to parse server response"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your internet connection and try again"
        case .authenticationFailed:
            return "Please sign in again"
        case .invalidResponse, .decodingError:
            return "Try again in a few moments"
        case .contentNotFound:
            return "Generic wake-up audio will be used instead"
        case .contentNotReady:
            return "Try again in a few minutes, or use generic audio"
        case .downloadTimeout:
            return "Check your connection and try again"
        case .invalidURL:
            return "Content will be regenerated automatically"
        case .storageError:
            return "Free up storage space and try again"
        case .subscriptionRequired:
            return "Upgrade to Banana Plus for AI wake-up features"
        case .userNotFound:
            return "Check your account settings"
        case .rateLimitExceeded(let retryAfter):
            if let retryAfter = retryAfter {
                return "Try again in \(Int(retryAfter)) seconds"
            } else {
                return "Try again in a few minutes"
            }
        case .serverError(let statusCode, _):
            if statusCode >= 500 {
                return "Server is temporarily unavailable. Try again later."
            } else {
                return "Please try again"
            }
        }
    }
    
    var failureReason: String? {
        switch self {
        case .networkUnavailable:
            return "Device is not connected to the internet"
        case .authenticationFailed:
            return "Session has expired or credentials are invalid"
        case .invalidResponse:
            return "Server returned unexpected data format"
        case .contentNotFound:
            return "No content has been generated for today's date"
        case .contentNotReady:
            return "Content generation is still in progress"
        case .downloadTimeout:
            return "Audio file download exceeded timeout limit"
        case .invalidURL:
            return "Audio URL is malformed or inaccessible"
        case .storageError:
            return "Unable to write audio file to device storage"
        case .subscriptionRequired:
            return "AI features require active subscription"
        case .userNotFound:
            return "User account does not exist in system"
        case .rateLimitExceeded:
            return "API request limit exceeded"
        case .serverError(let statusCode, _):
            return "Server responded with error code \(statusCode)"
        case .decodingError:
            return "Failed to decode JSON response from server"
        }
    }
}

// MARK: - Content Cache Error

/// Errors related to local content caching
enum ContentCacheError: LocalizedError, Sendable {
    case cacheDirectoryNotFound
    case fileNotFound(path: String)
    case corruptedFile(path: String)
    case diskSpaceInsufficient
    case permissionDenied
    case cacheExpired(path: String)
    case invalidCacheKey
    
    var errorDescription: String? {
        switch self {
        case .cacheDirectoryNotFound:
            return "Cache directory not accessible"
        case .fileNotFound:
            return "Cached file not found"
        case .corruptedFile:
            return "Cached file is corrupted"
        case .diskSpaceInsufficient:
            return "Insufficient storage space"
        case .permissionDenied:
            return "Permission denied accessing cache"
        case .cacheExpired:
            return "Cached content has expired"
        case .invalidCacheKey:
            return "Invalid cache identifier"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .cacheDirectoryNotFound:
            return "App will recreate cache directory"
        case .fileNotFound:
            return "Content will be downloaded again"
        case .corruptedFile:
            return "File will be re-downloaded automatically"
        case .diskSpaceInsufficient:
            return "Free up storage space on your device"
        case .permissionDenied:
            return "Check app permissions in Settings"
        case .cacheExpired:
            return "Fresh content will be downloaded"
        case .invalidCacheKey:
            return "Please try again"
        }
    }
}

// MARK: - Audio Processing Error

/// Errors related to audio file processing and playback
enum AudioProcessingError: LocalizedError, Sendable {
    case unsupportedFormat(format: String)
    case fileCorrupted
    case decodingFailed
    case playbackFailed(underlying: Error)
    case mixingFailed
    case volumeAdjustmentFailed
    case deviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let format):
            return "Unsupported audio format: \(format)"
        case .fileCorrupted:
            return "Audio file is corrupted"
        case .decodingFailed:
            return "Failed to decode audio file"
        case .playbackFailed:
            return "Audio playback failed"
        case .mixingFailed:
            return "Failed to mix audio tracks"
        case .volumeAdjustmentFailed:
            return "Failed to adjust audio volume"
        case .deviceUnavailable:
            return "Audio device unavailable"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unsupportedFormat:
            return "Standard alarm sound will be used"
        case .fileCorrupted:
            return "Audio will be re-downloaded automatically"
        case .decodingFailed:
            return "Try restarting the app"
        case .playbackFailed:
            return "Check audio settings and try again"
        case .mixingFailed:
            return "Single audio track will be used"
        case .volumeAdjustmentFailed:
            return "Use device volume controls"
        case .deviceUnavailable:
            return "Connect audio device and try again"
        }
    }
}

// MARK: - Push Notification Error

/// Errors related to silent push notifications
enum PushNotificationError: LocalizedError, Sendable {
    case permissionDenied
    case tokenRegistrationFailed
    case invalidPayload
    case processingTimeout
    case backgroundTaskFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Push notifications not allowed"
        case .tokenRegistrationFailed:
            return "Failed to register device for notifications"
        case .invalidPayload:
            return "Invalid notification data"
        case .processingTimeout:
            return "Background processing timed out"
        case .backgroundTaskFailed:
            return "Background task failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Enable notifications in Settings for better reliability"
        case .tokenRegistrationFailed:
            return "Try signing out and back in"
        case .invalidPayload:
            return "This will be resolved automatically"
        case .processingTimeout:
            return "Content will be fetched when alarm fires"
        case .backgroundTaskFailed:
            return "Alarm will still work with fallback audio"
        }
    }
}

// MARK: - Content Generation Error

/// Errors from backend content generation
enum ContentGenerationError: LocalizedError, Sendable {
    case scriptGenerationFailed
    case audioSynthesisFailed
    case weatherDataUnavailable
    case headlinesUnavailable
    case marketDataUnavailable
    case voiceServiceUnavailable
    case quotaExceeded
    case configurationError
    
    var errorDescription: String? {
        switch self {
        case .scriptGenerationFailed:
            return "Failed to generate wake-up script"
        case .audioSynthesisFailed:
            return "Failed to synthesize audio"
        case .weatherDataUnavailable:
            return "Weather data unavailable"
        case .headlinesUnavailable:
            return "News headlines unavailable"
        case .marketDataUnavailable:
            return "Market data unavailable"
        case .voiceServiceUnavailable:
            return "Voice service temporarily unavailable"
        case .quotaExceeded:
            return "Generation quota exceeded"
        case .configurationError:
            return "Configuration error"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .scriptGenerationFailed:
            return "Generic content will be used"
        case .audioSynthesisFailed:
            return "Text-to-speech fallback will be used"
        case .weatherDataUnavailable:
            return "Content will be generated without weather"
        case .headlinesUnavailable:
            return "Content will be generated without news"
        case .marketDataUnavailable:
            return "Content will be generated without market data"
        case .voiceServiceUnavailable:
            return "Try again later, or use generic audio"
        case .quotaExceeded:
            return "Quota will reset automatically"
        case .configurationError:
            return "Check your AI settings"
        }
    }
}

// MARK: - Error Recovery Strategies

/// Recovery actions that can be taken for different error types
enum ErrorRecoveryAction: Sendable {
    case retry
    case retryWithDelay(TimeInterval)
    case useCache
    case useFallback
    case skipFeature
    case requireUserAction
    case automaticRetry(maxAttempts: Int)
    
    var description: String {
        switch self {
        case .retry:
            return "Retry immediately"
        case .retryWithDelay(let delay):
            return "Retry after \(Int(delay)) seconds"
        case .useCache:
            return "Use cached content"
        case .useFallback:
            return "Use fallback content"
        case .skipFeature:
            return "Skip AI features"
        case .requireUserAction:
            return "User intervention required"
        case .automaticRetry(let maxAttempts):
            return "Automatic retry (max \(maxAttempts) attempts)"
        }
    }
}

// MARK: - Error Extensions

extension ContentFetchError {
    /// Recommended recovery action for this error
    var recoveryAction: ErrorRecoveryAction {
        switch self {
        case .networkUnavailable:
            return .retryWithDelay(5.0)
        case .authenticationFailed:
            return .requireUserAction
        case .invalidResponse, .decodingError:
            return .retryWithDelay(2.0)
        case .contentNotFound:
            return .useFallback
        case .contentNotReady:
            return .retryWithDelay(30.0)
        case .downloadTimeout:
            return .automaticRetry(maxAttempts: 3)
        case .invalidURL:
            return .useFallback
        case .storageError:
            return .skipFeature
        case .subscriptionRequired:
            return .requireUserAction
        case .userNotFound:
            return .requireUserAction
        case .rateLimitExceeded(let retryAfter):
            return .retryWithDelay(retryAfter ?? 60.0)
        case .serverError(let statusCode, _):
            if statusCode >= 500 {
                return .retryWithDelay(10.0)
            } else {
                return .useFallback
            }
        }
    }
    
    /// Whether this error should trigger fallback content
    var shouldUseFallback: Bool {
        switch self {
        case .contentNotFound, .contentNotReady, .invalidURL, .subscriptionRequired:
            return true
        case .serverError(let statusCode, _):
            return statusCode < 500 // Client errors should fallback, server errors should retry
        default:
            return false
        }
    }
    
    /// Whether this error is recoverable with retry
    var isRecoverable: Bool {
        switch self {
        case .networkUnavailable, .downloadTimeout, .contentNotReady, .rateLimitExceeded:
            return true
        case .serverError(let statusCode, _):
            return statusCode >= 500 // Server errors are recoverable
        default:
            return false
        }
    }
}