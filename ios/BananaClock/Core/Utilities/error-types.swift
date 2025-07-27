//
//  ErrorTypes.swift
//  BananaClock
//
//  Error type definitions
//

import Foundation

// MARK: - Supabase Errors
enum SupabaseError: LocalizedError {
    case notConfigured
    case notAuthenticated
    case networkError(String)
    case invalidResponse
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured"
        case .notAuthenticated:
            return "User is not authenticated"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid response from server"
        case .userNotFound:
            return "User not found"
        }
    }
}

// MARK: - Audio Errors
enum AudioError: LocalizedError {
    case playerCreationFailed
    case soundNotFound
    case audioSessionError(String)
    case playbackError(String)
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .playerCreationFailed:
            return "Failed to create audio player"
        case .soundNotFound:
            return "Sound file not found"
        case .audioSessionError(let message):
            return "Audio session error: \(message)"
        case .playbackError(let message):
            return "Playback error: \(message)"
        case .fileNotFound:
            return "Audio file not found"
        }
    }
}

// MARK: - AlarmKit Errors
// Note: AlarmKitError is defined in AlarmKitService.swift
// This enum is temporarily disabled until AlarmKit is available

// MARK: - Alarm Errors
// Note: AlarmError is defined in Core/Models/alarm-error.swift 