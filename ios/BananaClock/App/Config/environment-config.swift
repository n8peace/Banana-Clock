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
    // For TestFlight, use development Supabase since we have those API keys
    static let supabaseURL = bypassSubscriptionForTestFlight ? "https://epqiarnkhzabggxiltci.supabase.co" : "https://yqbrfznixefqqhnvingu.supabase.co"
    static let supabaseProjectRef = bypassSubscriptionForTestFlight ? "epqiarnkhzabggxiltci" : "yqbrfznixefqqhnvingu"
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
        
        // Development: Provide helpful setup instructions
        #if DEBUG
        print("❌ No Supabase anon key found in secure storage or environment")
        print("💡 For development setup, run in Xcode debug console:")
        print("   try! SecureKeyManager.shared.storeAPIKey(\"your_supabase_anon_key\", service: .supabaseAnon)")
        print("📖 Get your key from: https://supabase.com/dashboard/project/\(AppEnvironment.supabaseProjectRef)/settings/api")
        return ""
        #else
        // Production: Fail safely if no key is available
        print("❌ CRITICAL: No Supabase anon key found in production build")
        print("🔧 Configure environment variable: SUPABASE_ANON_KEY")
        fatalError("Production build missing required Supabase anon key")
        #endif
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
        
        // Development: Provide helpful setup instructions
        #if DEBUG
        print("❌ No Supabase service key found in secure storage or environment")
        print("💡 For development setup, run in Xcode debug console:")
        print("   try! SecureKeyManager.shared.storeAPIKey(\"your_supabase_service_key\", service: .supabaseService)")
        print("📖 Get your key from: https://supabase.com/dashboard/project/\(AppEnvironment.supabaseProjectRef)/settings/api")
        return ""
        #else
        // Production: Fail safely if no key is available
        print("❌ CRITICAL: No Supabase service key found in production build")
        print("🔧 Configure environment variable: SUPABASE_SERVICE_ROLE_KEY")
        fatalError("Production build missing required Supabase service key")
        #endif
    }
    
    static var revenueCatAPIKey: String {
        // RevenueCat automatically handles sandbox vs production based on Apple receipt environment
        // So we can use the same API key for both debug and release builds
        
        // Try secure key manager first (preferred for development)
        if let key = SecureKeyManager.shared.retrieveAPIKey(service: .revenueCatSandbox) {
            return key
        }
        
        // Try production key storage (for flexibility)
        if let key = SecureKeyManager.shared.retrieveAPIKey(service: .revenueCat) {
            return key
        }
        
        // Fallback to environment variables (for CI/CD)
        if let key = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"] {
            return key
        }
        if let key = ProcessInfo.processInfo.environment["REVENUECAT_SANDBOX_API_KEY"] {
            return key
        }
        
        // Finally fallback to Info.plist
        if let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_API_KEY") as? String, !key.isEmpty {
            return key
        }
        
        // No key found - provide helpful instructions
        #if DEBUG
        print("❌ No RevenueCat API key found")
        print("💡 For development setup, run in Xcode debug console:")
        print("   try! SecureKeyManager.shared.storeAPIKey(\"your_revenuecat_key\", service: .revenueCatSandbox)")
        print("📖 RevenueCat automatically detects sandbox vs production from Apple receipts")
        return ""
        #else
        print("❌ CRITICAL: No RevenueCat API key found in production build")
        print("🔧 Configure environment variable: REVENUECAT_API_KEY")
        fatalError("Production build missing required RevenueCat API key")
        #endif
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
    static let bypassSubscriptionForTestFlight = true // Bypass subscriptions for TestFlight testing
    #else
    static let bypassPaywallInDevelopment = false
    static let bypassSubscriptionForTestFlight = true // Enable for TestFlight release builds
    #endif
    
    // MARK: - Debug Environment Strategy
    #if DEBUG
    static let isDebugEnvironment = true
    static let forceLoginOnLaunch = true  // Forces login flow on every debug launch
    static let forceSubscriptionFlow = true  // Forces subscription flow even if previously subscribed
    static let useRevenueCatSandbox = true  // Use sandbox for testing
    #else
    static let isDebugEnvironment = false
    static let forceLoginOnLaunch = false
    static let forceSubscriptionFlow = false
    static let useRevenueCatSandbox = false
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