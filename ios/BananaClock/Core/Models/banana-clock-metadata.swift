//
//  BananaClockMetadata.swift
//  BananaClock
//
//  Custom metadata for AlarmKit integration
//

import Foundation
import AlarmKit

// MARK: - Banana Clock Metadata

struct BananaClockMetadata: AlarmMetadata {
    let alarmType: AlarmType
    let musicSelection: String?
    let voicePreference: String?
    let customMessage: String?
    let isSubscriberOnly: Bool
    let createdAt: Date
    
    init(
        alarmType: AlarmType,
        musicSelection: String? = nil,
        voicePreference: String? = nil,
        customMessage: String? = nil,
        isSubscriberOnly: Bool = false
    ) {
        self.alarmType = alarmType
        self.musicSelection = musicSelection
        self.voicePreference = voicePreference
        self.customMessage = customMessage
        self.isSubscriberOnly = isSubscriberOnly
        self.createdAt = Date()
    }
}

// MARK: - Alarm Type

enum AlarmType: String, Codable, CaseIterable {
    case aiWakeUp = "ai_wakeup"
    case regular = "regular"
    case timer = "timer"
    
    var displayName: String {
        switch self {
        case .aiWakeUp: return "AI Wake-Up"
        case .regular: return "Regular Alarm"
        case .timer: return "Timer"
        }
    }
    
    var requiresSubscription: Bool {
        switch self {
        case .aiWakeUp: return true
        case .regular, .timer: return false
        }
    }
}

// MARK: - Codable Conformance

extension BananaClockMetadata: Codable {
    enum CodingKeys: String, CodingKey {
        case alarmType
        case musicSelection
        case voicePreference
        case customMessage
        case isSubscriberOnly
        case createdAt
    }
}

// MARK: - Equatable & Hashable Conformance

extension BananaClockMetadata: Equatable {
    static func == (lhs: BananaClockMetadata, rhs: BananaClockMetadata) -> Bool {
        return lhs.alarmType == rhs.alarmType &&
               lhs.musicSelection == rhs.musicSelection &&
               lhs.voicePreference == rhs.voicePreference &&
               lhs.customMessage == rhs.customMessage &&
               lhs.isSubscriberOnly == rhs.isSubscriberOnly &&
               lhs.createdAt == rhs.createdAt
    }
}

extension BananaClockMetadata: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(alarmType)
        hasher.combine(musicSelection)
        hasher.combine(voicePreference)
        hasher.combine(customMessage)
        hasher.combine(isSubscriberOnly)
        hasher.combine(createdAt)
    }
}

// MARK: - Helper Extensions

extension BananaClockMetadata {
    /// Creates metadata for an AI wake-up alarm
    static func aiWakeUp(
        musicSelection: String,
        voicePreference: String,
        customMessage: String? = nil
    ) -> BananaClockMetadata {
        return BananaClockMetadata(
            alarmType: .aiWakeUp,
            musicSelection: musicSelection,
            voicePreference: voicePreference,
            customMessage: customMessage,
            isSubscriberOnly: true
        )
    }
    
    /// Creates metadata for a regular alarm
    static func regular() -> BananaClockMetadata {
        return BananaClockMetadata(
            alarmType: .regular,
            isSubscriberOnly: false
        )
    }
    
    /// Creates metadata for a timer
    static func timer() -> BananaClockMetadata {
        return BananaClockMetadata(
            alarmType: .timer,
            isSubscriberOnly: false
        )
    }
}