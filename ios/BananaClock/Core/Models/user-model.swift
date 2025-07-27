//
//  User.swift
//  BananaClock
//
//  User data model
//

import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    let email: String
    var hasActiveSubscription: Bool
    var subscriptionType: SubscriptionType?
    var subscriptionExpiresAt: Date?
    let createdAt: Date
    var lastSyncAt: Date?
    
    // Relationships
    var preferences: UserPreferences?
    
    enum SubscriptionType: String, Codable {
        case monthly = "banana_plus_monthly"
        case yearly = "banana_plus_yearly"
    }
    
    var isSubscriptionActive: Bool {
        guard hasActiveSubscription,
              let expiresAt = subscriptionExpiresAt else {
            return false
        }
        return expiresAt > Date()
    }
    
    var subscriptionStatusText: String {
        guard isSubscriptionActive else {
            return "Free"
        }
        
        switch subscriptionType {
        case .monthly:
            return "Banana Plus (Monthly)"
        case .yearly:
            return "Banana Plus (Yearly)"
        case .none:
            return "Banana Plus"
        }
    }
}

// MARK: - User Preferences
struct UserPreferences: Identifiable, Codable {
    let id: UUID
    var timezone: String
    var locationZip: String?
    var name: String?
    var city: String?
    var state: String?
    var voice: AIVoiceOption
    var wakeUpTime: Date?
    var contentPreferences: ContentPreferences
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        timezone: String = TimeZone.current.identifier,
        locationZip: String? = nil,
        name: String? = nil,
        city: String? = nil,
        state: String? = nil,
        voice: AIVoiceOption = .voice1,
        wakeUpTime: Date? = nil,
        contentPreferences: ContentPreferences = ContentPreferences(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.timezone = timezone
        self.locationZip = locationZip
        self.name = name
        self.city = city
        self.state = state
        self.voice = voice
        self.wakeUpTime = wakeUpTime
        self.contentPreferences = contentPreferences
        self.updatedAt = updatedAt
    }
    
    struct ContentPreferences: Codable {
        var includeWeather: Bool = true
        var includeHeadlines: Bool = true
        var includeMarkets: Bool = false
        var includeSports: Bool = false
        var includeEncouragement: Bool = true
        var contentLength: ContentLength = .medium
        
        enum ContentLength: String, Codable, CaseIterable {
            case short = "short"
            case medium = "medium"
            case long = "long"
        }
    }
}

// MARK: - Timer Model (moved from TimersView)
struct Timer: Identifiable, Codable {
    let id: UUID
    var label: String
    var duration: TimeInterval
    var remainingTime: TimeInterval
    var state: TimerState
    var soundIdentifier: String
    let createdAt: Date
    var startedAt: Date?
    var pausedAt: Date?
    var finishedAt: Date?
    var isPreset: Bool
    var presetOrder: Int
    
    enum TimerState: String, Codable {
        case ready, running, paused, finished
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return (duration - remainingTime) / duration
    }
    
    init(
        id: UUID = UUID(),
        label: String,
        duration: TimeInterval,
        remainingTime: TimeInterval? = nil,
        state: TimerState = .ready,
        soundIdentifier: String = "timer_complete",
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        pausedAt: Date? = nil,
        finishedAt: Date? = nil,
        isPreset: Bool = false,
        presetOrder: Int = 0
    ) {
        self.id = id
        self.label = label
        self.duration = duration
        self.remainingTime = remainingTime ?? duration
        self.state = state
        self.soundIdentifier = soundIdentifier
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.finishedAt = finishedAt
        self.isPreset = isPreset
        self.presetOrder = presetOrder
    }
}