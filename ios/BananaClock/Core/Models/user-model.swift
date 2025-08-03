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
    var music: MusicOption
    var wakeUpTime: Date?
    var contentPreferences: ContentPreferences
    var updatedAt: Date
    
    // AI Wake-Up Preferences (iOS Integration)
    var weatherEnabled: Bool
    var locationEnabled: Bool
    var headlinesCategories: [String]
    var sportsCategories: [String]
    var lastSyncAt: Date?
    
    init(
        id: UUID = UUID(),
        timezone: String = TimeZone.current.identifier,
        locationZip: String? = nil,
        name: String? = nil,
        city: String? = nil,
        state: String? = nil,
        voice: AIVoiceOption = .voice1,
        music: MusicOption = .chillVibes,
        wakeUpTime: Date? = nil,
        contentPreferences: ContentPreferences = ContentPreferences(),
        updatedAt: Date = Date(),
        weatherEnabled: Bool = false,
        locationEnabled: Bool = false,
        headlinesCategories: [String] = ["business", "technology"],
        sportsCategories: [String] = ["football", "basketball"],
        lastSyncAt: Date? = nil
    ) {
        self.id = id
        self.timezone = timezone
        self.locationZip = locationZip
        self.name = name
        self.city = city
        self.state = state
        self.voice = voice
        self.music = music
        self.wakeUpTime = wakeUpTime
        self.contentPreferences = contentPreferences
        self.updatedAt = updatedAt
        self.weatherEnabled = weatherEnabled
        self.locationEnabled = locationEnabled
        self.headlinesCategories = headlinesCategories
        self.sportsCategories = sportsCategories
        self.lastSyncAt = lastSyncAt
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

// MARK: - Timer Model (Enhanced BananaTimer)
struct BananaTimer: Identifiable, Codable {
    let id: UUID
    let label: String
    let duration: TimeInterval
    var remainingTime: TimeInterval
    var state: Timer.TimerState
    var startedAt: Date?
    var pausedAt: Date?
    var lastUsedAt: Date
    var soundIdentifier: String
    
    init(
        id: UUID = UUID(),
        label: String,
        duration: TimeInterval,
        remainingTime: TimeInterval? = nil,
        state: Timer.TimerState = .ready,
        startedAt: Date? = nil,
        pausedAt: Date? = nil,
        lastUsedAt: Date = Date(),
        soundIdentifier: String = "timer_complete"
    ) {
        self.id = id
        self.label = label
        self.duration = duration
        self.remainingTime = remainingTime ?? duration
        self.state = state
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.lastUsedAt = lastUsedAt
        self.soundIdentifier = soundIdentifier
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return max(0, min(1, (duration - remainingTime) / duration))
    }
    
    var formattedRemainingTime: String {
        let totalSeconds = Int(remainingTime)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    var endTime: Date? {
        guard state == .running, remainingTime > 0 else { return nil }
        return Date().addingTimeInterval(remainingTime)
    }
}

// MARK: - Timer State and Legacy Timer Support
extension Timer {
    enum TimerState: String, Codable {
        case ready, running, paused, finished
    }
}