//
//  ContentBlock.swift
//  BananaClock
//
//  Core model for AI-generated content blocks from Supabase
//  Designed for immutability, thread safety, and comprehensive validation
//

import Foundation

// MARK: - Content Block Model

/// Immutable model representing AI-generated content from Supabase
/// Maps directly to content_blocks table schema
struct AIContentBlock: Codable, Identifiable, Sendable {
    let id: UUID
    let userId: UUID
    let contentType: String
    let date: String
    let script: String?
    let audioUrl: String?
    let status: String
    let voice: String
    let expirationDate: String
    let languageCode: String?
    let contentPriority: Int?
    let createdAt: String
    let updatedAt: String?
    let scriptGeneratedAt: String?
    let audioGeneratedAt: String?
    let parameters: ContentParameters?
    let content: String?
    let metadata: ContentMetadata?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case contentType = "content_type"
        case date
        case script
        case audioUrl = "audio_url"
        case status
        case voice
        case expirationDate = "expiration_date"
        case languageCode = "language_code"
        case contentPriority = "content_priority"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case scriptGeneratedAt = "script_generated_at"
        case audioGeneratedAt = "audio_generated_at"
        case parameters
        case content
        case metadata
    }
}

// MARK: - Content Parameters

/// Parameters used for content generation - maps to JSONB field in database
struct ContentParameters: Codable, Sendable {
    let userName: String?
    let city: String?
    let state: String?
    let weather: WeatherData?
    let headlines: HeadlinesData?
    let markets: MarketsData?
    
    enum CodingKeys: String, CodingKey {
        case userName = "user_name"
        case city
        case state
        case weather
        case headlines
        case markets
    }
}

// MARK: - Weather Data

/// Weather information used in content generation
struct WeatherData: Codable, Sendable {
    let temperature: Double?
    let condition: String?
    let humidity: Double?
    let windSpeed: Double?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case temperature
        case condition
        case humidity
        case windSpeed = "wind_speed"
        case description
    }
    
    /// Validates weather data contains minimum required fields
    var isValid: Bool {
        return temperature != nil && condition != nil && !condition!.isEmpty
    }
}

// MARK: - Headlines Data

/// News headlines categorized by type
struct HeadlinesData: Codable, Sendable {
    let business: String?
    let political: String?
    let popCulture: String?
    
    enum CodingKeys: String, CodingKey {
        case business
        case political
        case popCulture
    }
    
    /// Validates at least one headline is present
    var isValid: Bool {
        return (business?.isEmpty == false) || 
               (political?.isEmpty == false) || 
               (popCulture?.isEmpty == false)
    }
}

// MARK: - Markets Data

/// Financial market information
struct MarketsData: Codable, Sendable {
    let summary: String?
    let trend: String?
    let keyMovers: [String]?
    
    enum CodingKeys: String, CodingKey {
        case summary
        case trend
        case keyMovers
    }
    
    /// Validates market data contains summary
    var isValid: Bool {
        return summary?.isEmpty == false
    }
}

// MARK: - Content Metadata

/// Additional metadata about content generation process
struct ContentMetadata: Codable, Sendable {
    let generationTime: Double?
    let retryCount: Int?
    let errorMessage: String?
    let modelVersion: String?
    let voiceSettings: VoiceSettings?
    
    enum CodingKeys: String, CodingKey {
        case generationTime = "generation_time"
        case retryCount = "retry_count"
        case errorMessage = "error_message"
        case modelVersion = "model_version"
        case voiceSettings = "voice_settings"
    }
}

// MARK: - Voice Settings

/// Voice generation configuration
struct VoiceSettings: Codable, Sendable {
    let voiceId: String?
    let stability: Double?
    let similarityBoost: Double?
    let speed: Double?
    
    enum CodingKeys: String, CodingKey {
        case voiceId = "voice_id"
        case stability
        case similarityBoost = "similarity_boost"
        case speed
    }
}

// MARK: - Content Status

/// Strongly-typed content status values
enum ContentBlockStatus: String, CaseIterable, Sendable {
    case pending = "pending"
    case scriptGenerated = "script_generated"
    case audioGenerated = "audio_generated"
    case ready = "ready"
    case contentReady = "content_ready"
    case error = "error"
    case expired = "expired"
    
    /// Human-readable description of status
    var description: String {
        switch self {
        case .pending: return "Content generation in progress"
        case .scriptGenerated: return "Script generated, audio pending"
        case .audioGenerated: return "Audio generated, finalizing"
        case .ready: return "Content ready for use"
        case .contentReady: return "Content available"
        case .error: return "Generation failed"
        case .expired: return "Content expired"
        }
    }
    
    /// Whether content is ready for playback
    var isReadyForPlayback: Bool {
        return self == .ready || self == .contentReady
    }
}

// MARK: - Content Type

/// Strongly-typed content types
enum ContentType: String, CaseIterable, Sendable {
    case banana = "banana"
    case weather = "weather"
    case headlines = "headlines"
    case markets = "markets"
    
    var description: String {
        switch self {
        case .banana: return "AI Wake-up Content"
        case .weather: return "Weather Information"
        case .headlines: return "News Headlines"
        case .markets: return "Market Data"
        }
    }
}

// MARK: - Helper Extensions

extension AIContentBlock {
    /// Check if the content is ready for playback
    var isReady: Bool {
        guard let status = ContentBlockStatus(rawValue: status) else { return false }
        return status.isReadyForPlayback
    }
    
    /// Check if the content has valid audio URL
    var hasAudio: Bool {
        guard let url = audioUrl, !url.isEmpty else { return false }
        return URL(string: url) != nil
    }
    
    /// Check if the content is expired based on expiration date
    var isExpired: Bool {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let expDate = formatter.date(from: expirationDate) else {
            // If we can't parse expiration date, consider it expired for safety
            return true
        }
        
        return Date() > expDate
    }
    
    /// Get formatted creation date
    var formattedCreatedAt: Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: createdAt)
    }
    
    /// Get age of content in seconds
    var ageInSeconds: TimeInterval? {
        guard let created = formattedCreatedAt else { return nil }
        return Date().timeIntervalSince(created)
    }
    
    /// Validate content block has minimum required fields
    var isValid: Bool {
        // Must have required fields
        guard !userId.uuidString.isEmpty,
              !contentType.isEmpty,
              !date.isEmpty,
              !status.isEmpty,
              !voice.isEmpty,
              !expirationDate.isEmpty,
              !createdAt.isEmpty else {
            return false
        }
        
        // Content type must be valid
        guard ContentType(rawValue: contentType) != nil else {
            return false
        }
        
        // Status must be valid
        guard ContentBlockStatus(rawValue: status) != nil else {
            return false
        }
        
        // If audio URL is present, it must be valid
        if let audioUrl = audioUrl, !audioUrl.isEmpty {
            guard URL(string: audioUrl) != nil else {
                return false
            }
        }
        
        return true
    }
    
    /// Get strongly-typed status
    var typedStatus: ContentBlockStatus? {
        return ContentBlockStatus(rawValue: status)
    }
    
    /// Get strongly-typed content type
    var typedContentType: ContentType? {
        return ContentType(rawValue: contentType)
    }
}