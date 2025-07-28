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

@main
struct BananaClockApp: App {
    @StateObject private var coreDataManager = CoreDataManager.shared
    @StateObject private var appState = AppState()
    @StateObject private var purchaseService = PurchaseService.shared
    // @Environment(\.scenePhase) private var scenePhase  // Temporarily disabled
    
    var body: some Scene {
        WindowGroup {
            Group {
                if purchaseService.isSubscribed {
                    MainTabView()
                        .environment(\.managedObjectContext, coreDataManager.viewContext)
                        .environmentObject(coreDataManager)
                        .environmentObject(appState)
                } else {
                    // Show main interface in demo mode if RevenueCat isn't configured
                    MainTabView()
                        .environment(\.managedObjectContext, coreDataManager.viewContext)
                        .environmentObject(coreDataManager)
                        .environmentObject(appState)
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                configureApp()
            }
            // .onChange(of: scenePhase) { oldPhase, newPhase in
            //     handleScenePhaseChange(from: oldPhase, to: newPhase)
            // }
        }
    }
    
    private func configureApp() {
        // Configure Supabase (for AI features only)
        SupabaseService.shared.configure()
        
        // Configure RevenueCat
        purchaseService.configure()
        
        // Configure appearance
        configureAppearance()
        
        // Request permissions
        Task {
            await requestInitialPermissions()
        }
    }
    
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
        
        // If no saved tab (first launch), default to alarms
        if savedTabRawValue == 0 {
            selectedTab = .alarms
        } else if let tab = MainTabView.Tab(rawValue: savedTabRawValue) {
            selectedTab = tab
        } else {
            selectedTab = .alarms
        }
    }
    
    func saveLastViewedTab() {
        userDefaults.set(selectedTab.rawValue, forKey: AppEnvironment.StorageKey.lastViewedTab)
    }
}