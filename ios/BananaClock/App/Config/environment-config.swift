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
    
    // MARK: - API Keys (from secure storage)
    static var supabaseAnonKey: String {
        print("🔍 Loading Supabase key from secure storage...")
        
        // Try secure key manager first
        if let key = SecureKeyManager.shared.retrieveAPIKey(service: .supabaseAnon) {
            print("✅ Found key in secure storage")
            return key
        }
        
        // Fallback to environment variable (for CI/CD)
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] {
            print("✅ Found key in environment variable")
            return key
        }
        
        print("❌ No valid key found, returning empty string")
        return ""
    }
    
    static var supabaseServiceKey: String {
        print("🔍 Loading Supabase service key from secure storage...")
        
        // Try secure key manager first
        if let key = SecureKeyManager.shared.retrieveAPIKey(service: .supabaseService) {
            print("✅ Found service key in secure storage")
            return key
        }
        
        // Fallback to environment variable (for CI/CD)
        if let key = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"] {
            print("✅ Found service key in environment variable")
            return key
        }
        
        print("❌ No valid service key found, returning empty string")
        return ""
    }
    
    static var revenueCatAPIKey: String {
        // Try secure key manager first
        if let key = SecureKeyManager.shared.retrieveAPIKey(service: .revenueCat) {
            return key
        }
        // Fallback to environment variable (for CI/CD)
        if let key = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] {
            return key
        }
        // Finally fallback to Info.plist
        return Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String ?? ""
    }
    
    // OpenAI API key no longer needed in iOS app
    // All OpenAI calls go through Supabase proxy
    
    // MARK: - Feature Flags
    static let enableCrashReporting = !isDebug
    static let enableAnalytics = !isDebug
    static let enableTestFlightBanner = isDebug
    
    // MARK: - Development Bypass
    #if DEBUG
    static let bypassPaywallInDevelopment = true // Set to false to test paywall in dev
    #else
    static let bypassPaywallInDevelopment = false
    #endif
    
    // MARK: - API Endpoints
    static let generateContentEndpoint = "\(supabaseURL)/functions/v1/generate-banana-content"
    static let aiTimeConverterEndpoint = "\(supabaseURL)/functions/v1/ai-time-converter"
    static let subscriptionStatusEndpoint = "\(supabaseURL)/functions/v1/subscription-status"
    static let openAIProxyEndpoint = "\(supabaseURL)/functions/v1/openai-proxy"
    
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