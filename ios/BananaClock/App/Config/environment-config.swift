//
//  Environment.swift
//  BananaClock
//
//  Environment configuration for different build schemes
//

import Foundation
import SwiftUI

enum AppEnvironment {
    // MARK: - Build Configuration
    #if DEBUG
    static let isDebug = true
    static let supabaseURL = "https://epqiarnkhzabggxiltci.supabase.co"
    static let supabaseProjectRef = "epqiarnkhzabggxiltci"
    #else
    static let isDebug = false
    static let supabaseURL = "https://yqbrfznixefqqhnvingu.supabase.co"
    static let supabaseProjectRef = "yqbrfznixefqqhnvingu"
    #endif
    
    // MARK: - API Keys (from environment or Info.plist)
    static var supabaseAnonKey: String {
        // First try Secrets.swift (for local development)
        if !Secrets.supabaseAnonKey.contains("YOUR_") {
            return Secrets.supabaseAnonKey
        }
        // Then try environment variable
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            return key
        }
        // Finally fallback to Info.plist
        return Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? ""
    }
    
    static var revenueCatAPIKey: String {
        // First try Secrets.swift (for local development)
        if !Secrets.revenueCatAPIKey.contains("YOUR_") {
            return Secrets.revenueCatAPIKey
        }
        // Then try environment variable
        if let key = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] {
            return key
        }
        // Finally fallback to Info.plist
        return Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? ""
    }
    
    // MARK: - Feature Flags
    static let enableCrashReporting = !isDebug
    static let enableAnalytics = !isDebug
    static let enableTestFlightBanner = isDebug
    
    // MARK: - API Endpoints
    static let generateContentEndpoint = "\(supabaseURL)/functions/v1/generate-banana-content"
    static let aiTimeConverterEndpoint = "\(supabaseURL)/functions/v1/ai-time-converter"
    static let subscriptionStatusEndpoint = "\(supabaseURL)/functions/v1/subscription-status"
    
    // MARK: - Storage Keys
    enum StorageKey {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let lastSyncDate = "lastSyncDate"
        static let cachedUserPreferences = "cachedUserPreferences"
        static let selectedVoice = "selectedVoice"
        static let preferredWakeUpTime = "preferredWakeUpTime"
        static let lastViewedTab = "lastViewedTab"
    }
    
    // MARK: - App Configuration
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    static let bundleIdentifier = "bananaclock.bananaintelligence.ai"
    
    // MARK: - Audio Configuration
    static let maxAudioDuration: TimeInterval = 300 // 5 minutes
    static let audioFadeInDuration: TimeInterval = 30 // 30 seconds
    static let defaultAlarmVolume: Float = 0.7
    
    // MARK: - Subscription
    static let monthlyProductID = "banana_plus_monthly"
    static let yearlyProductID = "banana_plus_yearly"
    static let entitlementID = "banana_plus"
    
    // MARK: - Limits
    static let freeAlarmLimit = Int.max // Unlimited for free users
    static let freeTimerLimit = Int.max // Unlimited timers for all users
    static let premiumTimerLimit = Int.max // Unlimited timers for all users
    static let aiGenerationsPerDay = 3
    static let aiConversionsPerDay = 100
}