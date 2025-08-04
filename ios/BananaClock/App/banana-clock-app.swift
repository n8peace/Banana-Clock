//
//  BananaClockApp.swift
//  BananaClock
//
//  Updated for Core Data + CloudKit
//

import SwiftUI
import CoreData
import Supabase
import RevenueCat
import AppIntents

@main
struct BananaClockApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var purchaseService = PurchaseService.shared
    @StateObject private var secureKeyManager = SecureKeyManager.shared
    @StateObject private var alarmKitService = AlarmKitService.shared
    @StateObject private var liveActivityService = LiveActivityService.shared
    @StateObject private var supabaseService = SupabaseService.shared
    // @Environment(\.scenePhase) private var scenePhase  // Temporarily disabled
    
    // MARK: - Development Bypass
    private var shouldBypassPaywall: Bool {
        #if DEBUG
        return AppEnvironment.bypassPaywallInDevelopment
        #else
        return false
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                #if DEBUG
                // Debug mode: Check authentication first if force login is enabled
                if AppEnvironment.forceLoginOnLaunch && !supabaseService.isAuthenticated {
                    DebugLoginView()
                        .environmentObject(supabaseService)
                } else if shouldBypassPaywall || purchaseService.isSubscribed {
                    // Full app access for subscribers or development bypass
                    MainTabView()
                        .environment(\.managedObjectContext, coreDataManager.viewContext)
                        .environmentObject(coreDataManager)
                        .environmentObject(appState)
                        .environmentObject(liveActivityService)
                } else {
                    // Hard paywall - no app access without subscription
                    PaywallView()
                        .environmentObject(purchaseService)
                }
                #else
                // Production mode: Normal flow
                if shouldBypassPaywall || purchaseService.isSubscribed {
                    MainTabView()
                        .environment(\.managedObjectContext, coreDataManager.viewContext)
                        .environmentObject(coreDataManager)
                        .environmentObject(appState)
                        .environmentObject(liveActivityService)
                } else {
                    PaywallView()
                        .environmentObject(purchaseService)
                }
                #endif
            }
            .preferredColorScheme(.dark)
            .environmentObject(secureKeyManager)
            .environmentObject(alarmKitService)
            .environmentObject(supabaseService)
            .onAppear {
                configureApp()
            }
            // .onChange(of: scenePhase) { oldPhase, newPhase in
            //     handleScenePhaseChange(from: oldPhase, to: newPhase)
            // }
        }
    }
    
    private func configureApp() {
        print("🚀 App starting configuration...")
        
        // Development setup check
        #if DEBUG
        SecureKeyManager.setupDevelopmentEnvironment()
        
        // Clear debug environment if enabled
        if AppEnvironment.forceLoginOnLaunch || AppEnvironment.forceSubscriptionFlow {
            Task {
                await clearDebugEnvironment()
            }
        }
        #endif
        
        // Configure Supabase (for AI features only)
        print("🔧 About to configure Supabase...")
        supabaseService.configure()
        print("🔧 Supabase configuration completed")
        
        // Configure RevenueCat
        purchaseService.configure()
        
        // App Intents are automatically discovered by the system
        print("✅ App Intents ready for AlarmKit actions")
        
        // Configure AlarmKit
        Task {
            let authorized = await alarmKitService.requestAuthorization()
            if authorized {
                print("✅ AlarmKit authorized successfully")
            } else {
                print("⚠️ AlarmKit authorization denied - some features may not work")
            }
        }
        
        // Configure appearance
        configureAppearance()
        
        // Request permissions
        Task {
            await requestInitialPermissions()
        }
    }
    
    #if DEBUG
    private func clearDebugEnvironment() async {
        print("🧪 Clearing debug environment for testing...")
        
        // Clear authentication if force login is enabled
        if AppEnvironment.forceLoginOnLaunch {
            await supabaseService.clearDebugSession()
        }
        
        // Clear subscription if force subscription is enabled
        if AppEnvironment.forceSubscriptionFlow {
            // Only clear if RevenueCat is configured
            if !AppEnvironment.revenueCatAPIKey.isEmpty {
                await purchaseService.clearDebugSubscription()
            } else {
                print("⚠️ Skipping subscription clearing - RevenueCat not configured")
            }
        }
        
        print("✅ Debug environment cleared - ready for testing")
    }
    #endif
    
    private func configureAppearance() {
        // Navigation Bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor.black
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        
        // Tab Bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor.black
        
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        
        // Date Picker Text Color
        UIDatePicker.appearance().tintColor = UIColor.white
    }
    
    private func requestInitialPermissions() async {
        // Request alarm permissions when needed (contextual)
        // We'll request when user tries to create first alarm
    }
    
    // private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
    //     switch newPhase {
    //     case .active:
    //         // App became active
    //         Task {
    //             await appState.refreshData()
    //         }
    //     case .inactive:
    //         // App became inactive
    //         break
    //     case .background:
    //         // App moved to background
    //         // Core Data saves automatically
    //         coreDataManager.save()
    //     @unknown default:
    //         break
    //     }
    // }
}

// MARK: - App State
@MainActor
class AppState: ObservableObject {
    @Published var selectedTab: MainTabView.Tab = .alarms
    
    private let userDefaults = UserDefaults.standard
    
    init() {
        loadLastViewedTab()
    }
    
    func refreshData() async {
        // Trigger AI content generation for tomorrow's AI alarms
        // This will only run if user is subscribed (checked in main app)
        await generateAIContentForTomorrow()
    }
    
    private func generateAIContentForTomorrow() async {
        // Temporarily disabled until Supabase is configured
        print("AI content generation temporarily disabled")
    }
    
    // MARK: - Tab Persistence
    
    private func loadLastViewedTab() {
        let savedTabRawValue = userDefaults.integer(forKey: AppEnvironment.StorageKey.lastViewedTab)
        
        print("📱 Loading last viewed tab: savedTabRawValue = \(savedTabRawValue)")
        
        // Check if we have a saved tab value
        if let tab = MainTabView.Tab(rawValue: savedTabRawValue) {
            selectedTab = tab
            print("📱 Restored to tab: \(tab.title)")
        } else {
            // If no saved tab (first launch) or invalid value, default to alarms
            selectedTab = .alarms
            print("📱 No saved tab found, defaulting to alarms")
        }
    }
    
    func saveLastViewedTab() {
        userDefaults.set(selectedTab.rawValue, forKey: AppEnvironment.StorageKey.lastViewedTab)
        print("📱 Saved last viewed tab: \(selectedTab.title) (rawValue: \(selectedTab.rawValue))")
    }
}