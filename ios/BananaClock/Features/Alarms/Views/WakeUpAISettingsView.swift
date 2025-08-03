//
//  WakeUpAISettingsView.swift
//  BananaClock
//
//  AI settings for wake-up alarms
//

import SwiftUI

struct WakeUpAISettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var voice: AIVoiceOption
    @State private var music: MusicOption
    @State private var weatherEnabled: Bool
    @State private var headlinesCategories: Set<HeadlinesCategory>
    @State private var sportsCategories: Set<SportsCategory>
    @State private var preferredName: String
    @State private var locationEnabled: Bool
    @State private var showingMusicPicker = false
    @State private var showingHeadlinesPicker = false
    @State private var showingSportsPicker = false
    
    @StateObject private var weatherService = WeatherService.shared
    
    let preferences: UserPreferences?
    let onSave: (UserPreferences) -> Void
    
    init(preferences: UserPreferences?, onSave: @escaping (UserPreferences) -> Void) {
        self.preferences = preferences
        self.onSave = onSave
        
        // Initialize state from preferences
        _voice = State(initialValue: preferences?.voice ?? .voice1)
        _music = State(initialValue: preferences?.music ?? .chillVibes)
        // Weather toggle represents both weather and location preferences
        _weatherEnabled = State(initialValue: (preferences?.weatherEnabled ?? false) || (preferences?.locationEnabled ?? false))
        _headlinesCategories = State(initialValue: Set(preferences?.headlinesCategories.compactMap { HeadlinesCategory(rawValue: $0) } ?? [.business, .technology]))
        _sportsCategories = State(initialValue: Set(preferences?.sportsCategories.compactMap { SportsCategory(rawValue: $0) } ?? [.football, .basketball]))
        _preferredName = State(initialValue: preferences?.name ?? "")
        // Location follows weather state
        _locationEnabled = State(initialValue: (preferences?.weatherEnabled ?? false) || (preferences?.locationEnabled ?? false))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                List {
                    // Voice Section
                    Section("Voice Personality") {
                        NavigationLink {
                            VoicePickerView(selectedVoice: $voice)
                        } label: {
                            HStack {
                                Text("Voice Style")
                                Spacer()
                                Text(voice.displayName)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    // Music Section
                    Section("Background Music") {
                        NavigationLink {
                            MusicPickerView(selectedMusic: $music)
                        } label: {
                            HStack {
                                Text("Music Style")
                                Spacer()
                                Text(music.displayName)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                    
                    // Content Section
                    Section("Morning Content") {
                        // Preferred Name
                        HStack {
                            Text("Your Name")
                            Spacer()
                            TextField("Banana", text: $preferredName)
                                .multilineTextAlignment(.trailing)
                                .foregroundColor(.white)
                        }
                        
                        // Weather (includes location)
                        Toggle("Weather", isOn: $weatherEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .bananaYellow))
                            .onChange(of: weatherEnabled) { _, newValue in
                                // Weather toggle drives both weather and location
                                locationEnabled = newValue
                                
                                if newValue {
                                    Task {
                                        await requestLocationPermission()
                                    }
                                } else {
                                    // Clear location data when disabled
                                    weatherService.clearDetectedLocation()
                                }
                            }
                        
                        // Headlines
                        NavigationLink {
                            HeadlinesPickerView(selectedCategories: $headlinesCategories)
                        } label: {
                            HStack {
                                Text("News Categories")
                                Spacer()
                                Text(formatCategories(headlinesCategories))
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        // Sports
                        NavigationLink {
                            SportsPickerView(selectedCategories: $sportsCategories)
                        } label: {
                            HStack {
                                Text("Sports")
                                Spacer()
                                Text(formatSports(sportsCategories))
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .navigationTitle("AI Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // Set navigation title color to white and unbolded
                UINavigationBar.appearance().titleTextAttributes = [
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 17, weight: .regular)
                ]
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSettings()
                    }
                    .foregroundColor(.bananaYellow)
                }
            }

        }
    }
    
    // MARK: - Helper Methods
    
    private func formatCategories(_ categories: Set<HeadlinesCategory>) -> String {
        if categories.isEmpty {
            return "None"
        } else if categories.count == HeadlinesCategory.allCases.count {
            return "All"
        } else if categories.count > 3 {
            return "\(categories.count) selected"
        } else {
            return categories.map { $0.displayName }.joined(separator: ", ")
        }
    }
    
    private func formatSports(_ sports: Set<SportsCategory>) -> String {
        if sports.isEmpty {
            return "None"
        } else if sports.count == SportsCategory.allCases.count {
            return "All"
        } else if sports.count > 3 {
            return "\(sports.count) selected"
        } else {
            return sports.map { $0.displayName }.joined(separator: ", ")
        }
    }
    
    private func requestLocationPermission() async {
        await weatherService.requestLocationAndDetect()
    }
    
    private func saveSettings() {
        // Weather toggle drives both location and weather backend fields
        let finalLocationEnabled = weatherEnabled
        let finalWeatherEnabled = weatherEnabled
        
        // Use detected location if weather is enabled, otherwise clear
        let locationZip = finalLocationEnabled ? weatherService.detectedZipCode : nil
        let locationCity = finalLocationEnabled ? weatherService.detectedCity : nil  
        let locationState = finalLocationEnabled ? weatherService.detectedState : nil
        
        let updatedPreferences = UserPreferences(
            id: preferences?.id ?? UUID(),
            timezone: preferences?.timezone ?? TimeZone.current.identifier,
            locationZip: locationZip,
            name: preferredName.isEmpty ? nil : preferredName,
            city: locationCity,
            state: locationState,
            voice: voice,
            music: music,
            wakeUpTime: preferences?.wakeUpTime,
            contentPreferences: preferences?.contentPreferences ?? UserPreferences.ContentPreferences(),
            updatedAt: Date(),
            weatherEnabled: finalWeatherEnabled,
            locationEnabled: finalLocationEnabled,
            headlinesCategories: headlinesCategories.map { $0.rawValue },
            sportsCategories: sportsCategories.map { $0.rawValue },
            lastSyncAt: preferences?.lastSyncAt
        )
        
        onSave(updatedPreferences)
        dismiss()
    }
}

#Preview {
    WakeUpAISettingsView(
        preferences: nil,
        onSave: { _ in }
    )
}