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
    
    private var selectedTab: Binding<Tab> {
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
        TabView(selection: selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                NavigationStack {
                    contentView(for: tab)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbarBackground(BananaTheme.Colors.backgroundPrimary, for: .navigationBar)
                        .toolbarBackground(.visible, for: .navigationBar)
                        .toolbarColorScheme(.dark, for: .navigationBar)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
        .accentColor(BananaTheme.Colors.bananaYellow)
        .onAppear {
            setupTabBarAppearance()
            setupNavigationBarAppearance()
        }
    }
    
    @ViewBuilder
    private func contentView(for tab: Tab) -> some View {
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
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.black
        
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
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(BananaTheme.Colors.backgroundPrimary)
        
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