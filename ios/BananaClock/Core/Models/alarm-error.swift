import Foundation

enum AlarmError: LocalizedError {
    case unauthorized
    case quotaExceeded
    case invalidTime
    case systemError(String)
    case aiGenerationFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .unauthorized:
            return "Alarm permissions not granted. Please enable in Settings."
        case .quotaExceeded:
            return "You've reached the maximum number of alarms."
        case .invalidTime:
            return "Please select a valid alarm time."
        case .systemError(let message):
            return "System error: \(message)"
        case .aiGenerationFailed:
            return "Failed to generate AI wake-up content. Using standard alarm."
        case .networkError:
            return "Network connection required for AI features."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .unauthorized:
            return "Go to Settings > BANANA > Alarms to enable permissions."
        case .quotaExceeded:
            return "Delete an existing alarm to add a new one."
        case .invalidTime:
            return "Choose a time in the future."
        case .systemError:
            return "Please try again or restart the app."
        case .aiGenerationFailed:
            return "Check your internet connection and try again."
        case .networkError:
            return "Connect to the internet to use AI features."
        }
    }
}
