//
//  MainTabView.swift
//  BananaClock
//
//  Main tab navigation
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @EnvironmentObject var appState: AppState
    @State private var glowAnimation = false
    
    private var selectedTab: Binding<MainTabView.Tab> {
        Binding(
            get: { appState.selectedTab },
            set: { newTab in
                appState.selectedTab = newTab
                appState.saveLastViewedTab()
            }
        )
    }
    
    enum Tab: Int, CaseIterable {
        case worldClock
        case alarms
        case stopwatch
        case timers
        
        var title: String {
            switch self {
            case .worldClock: return "World Clock"
            case .alarms: return "Alarms"
            case .stopwatch: return "Stopwatch"
            case .timers: return "Timers"
            }
        }
        
        var navigationTitle: String {
            switch self {
            case .worldClock: return "🌍🕒 World Clock"
            case .alarms: return "⏰ Alarms"
            case .stopwatch: return "⏱️ Stopwatch"
            case .timers: return "⏲️ Timers"
            }
        }
        
        var icon: String {
            switch self {
            case .worldClock: return "globe"
            case .alarms: return "alarm"
            case .stopwatch: return "stopwatch"
            case .timers: return "timer"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Base black background (foundation layer)
            Color.black.ignoresSafeArea()
            
            // Enhanced Sunrise Glow - Inspired by Apple Health
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.3).opacity(0.60),   // Soft banana yellow
                    Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.50),   // Tangerine orange
                    Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.40),   // Warm coral red
                    Color(red: 0.8, green: 0.4, blue: 0.8).opacity(0.30),   // Soft lavender for depth
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.5, y: 0.3)
            )
            .blur(radius: 40)
            .ignoresSafeArea()
            .blendMode(.screen)

            .opacity(glowAnimation ? 1.0 : 0.70)
            .animation(.easeInOut(duration: 4), value: glowAnimation)
            
            // Radial gradient behind time display
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.3).opacity(0.35),
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 200
            )
            .frame(height: 300)
            .frame(maxHeight: .infinity, alignment: .top)
            .blur(radius: 20)
            .blendMode(.screen)
            
            TabView(selection: selectedTab) {
            ForEach(MainTabView.Tab.allCases, id: \.self) { tab in
                NavigationStack {
                    contentView(for: tab)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(.hidden, for: .navigationBar)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .background(Color.clear)
                .tabItem {
                    Label(tab.title, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        }
        .background(Color.clear)
        .accentColor(BananaTheme.Colors.bananaYellow)
        .onAppear {
            setupTabBarAppearance()
            setupNavigationBarAppearance()
            glowAnimation = true
        }
    }
    
    @ViewBuilder
    private func contentView(for tab: MainTabView.Tab) -> some View {
        switch tab {
        case .worldClock:
            WorldClockView()
        case .alarms:
            AlarmsView()
        case .stopwatch:
            StopwatchView()
        case .timers:
            TimersView()
        }
    }
    
    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = UIColor.clear
        
        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor.systemGray
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.systemGray
        ]
        
        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(BananaTheme.Colors.bananaYellow)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(BananaTheme.Colors.bananaYellow)
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private func setupNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        
        // Title appearance
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(BananaTheme.Colors.bananaYellow),
            .font: UIFont.systemFont(ofSize: 22, weight: .bold)
        ]
        
        // Large title appearance
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(BananaTheme.Colors.bananaYellow),
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        
        // Button appearance
        appearance.buttonAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(BananaTheme.Colors.bananaYellow)
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}