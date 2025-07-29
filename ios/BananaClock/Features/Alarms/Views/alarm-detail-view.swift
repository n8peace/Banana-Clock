//
//  AlarmDetailView.swift
//  BananaClock
//
//  Alarm creation and editing view
//

import SwiftUI
import Foundation
import CoreData

struct AlarmDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var time: Date
    @State private var label: String
    @State private var isAIEnabled: Bool
    @State private var selectedSound: AlarmSound
    @State private var snoozeLength: Int?
    @State private var repeatDays: Set<Alarm.Weekday>
    @State private var volume: Float
    
    // AI Wake-Up Preferences
    @State private var aiVoice: AIVoiceOption
    @State private var aiMusic: MusicOption
    @State private var aiWeatherEnabled: Bool
    @State private var aiHeadlinesCategories: Set<HeadlinesCategory>
    @State private var aiSportsCategories: Set<SportsCategory>
    @State private var aiLocationLatitude: Double?
    @State private var aiLocationLongitude: Double?
    @State private var aiPreferredName: String
    
    // UI State
    @State private var showingDeleteConfirmation = false
    @State private var isAISectionExpanded = false

    let alarm: Alarm?
    let onSave: (Alarm) -> Void
    let onDelete: ((Alarm) -> Void)?
    
    // Computed property to check if this is a wake-up alarm
    private var isWakeUpAlarm: Bool {
        alarm?.isWakeUpAlarm ?? false
    }
    
    init(alarm: Alarm?, onSave: @escaping (Alarm) -> Void, onDelete: ((Alarm) -> Void)? = nil) {
        self.alarm = alarm
        self.onSave = onSave
        self.onDelete = onDelete
        
        // Initialize state
        _time = State(initialValue: alarm?.time ?? Date().addingTimeInterval(3600))
        _label = State(initialValue: alarm?.label ?? "Alarm")
        _isAIEnabled = State(initialValue: alarm?.isAIEnabled ?? false)
        _selectedSound = State(initialValue: AlarmSound(rawValue: alarm?.soundIdentifier ?? "default") ?? .default)
        _snoozeLength = State(initialValue: alarm?.snoozeLength ?? 9)
        _repeatDays = State(initialValue: Set(alarm?.repeatDays ?? []))
        _volume = State(initialValue: alarm?.volume ?? 0.7)
        
        // Initialize AI preferences
        _aiVoice = State(initialValue: alarm?.aiVoice ?? .voice1)
        _aiMusic = State(initialValue: alarm?.aiMusic ?? .chillVibes)
        _aiWeatherEnabled = State(initialValue: alarm?.aiWeatherEnabled ?? false)
        _aiHeadlinesCategories = State(initialValue: Set(alarm?.aiHeadlinesCategories ?? [.business, .technology]))
        _aiSportsCategories = State(initialValue: Set(alarm?.aiSportsCategories ?? [.football, .basketball]))
        _aiLocationLatitude = State(initialValue: alarm?.aiLocationLatitude)
        _aiLocationLongitude = State(initialValue: alarm?.aiLocationLongitude)
        _aiPreferredName = State(initialValue: alarm?.aiPreferredName ?? "Banana")
        
        // Initialize UI state - expand AI section if AI is enabled
        _isAISectionExpanded = State(initialValue: alarm?.isAIEnabled ?? false)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Time Picker
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .padding()
                        
                        // Options
                        VStack(spacing: 0) {
                            // Label - only for non-wake-up alarms
                            if !isWakeUpAlarm {
                                SettingsRow(title: "Label") {
                                    TextField("Alarm", text: $label)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.white)
                                }
                                
                                Divider().background(BananaTheme.Colors.divider)
                            }
                            
                            // AI Wake-up Section - only show for wake-up alarms
                            if isWakeUpAlarm {
                                aiWakeUpSection
                            }
                        }
                        .bananaCard()
                        .padding()
                        
                        // Other Settings Section (separate card)
                        if isWakeUpAlarm {
                            VStack(spacing: 0) {
                                otherSettingsSection
                            }
                            .bananaCard()
                            .padding()
                        } else {
                            // For non-wake-up alarms, include other settings in the same card
                            VStack(spacing: 0) {
                                otherSettingsSection
                            }
                            .bananaCard()
                            .padding()
                        }
                        
                        // Delete button (for existing alarms, but not wake-up alarms)
                        if alarm != nil && !isWakeUpAlarm {
                            Button {
                                showingDeleteConfirmation = true
                            } label: {
                                Text("Delete Alarm")
                                    .font(.body)
                                    .foregroundColor(BananaTheme.Colors.error)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle(alarm == nil ? "Add Alarm" : "Edit Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear {
                // Set navigation title color to white
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
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAlarm()
                    }
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                }
            }
        }

        .alert("Delete Alarm", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                if let alarm = alarm, let onDelete = onDelete {
                    onDelete(alarm)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this alarm?")
        }
    }
    
    // MARK: - AI Wake-Up Section
    
    private var aiWakeUpSection: some View {
        VStack(spacing: 0) {
            // AI Toggle Header
            HStack {
                HStack {
                    Text("🍌🧠")
                        .font(.title2)
                    Text("Wake Up AI")
                        .foregroundColor(.textPrimary)
                    Spacer()
                }
                Toggle("", isOn: $isAIEnabled)
                    .labelsHidden()
                    .onChange(of: isAIEnabled) { _, newValue in
                        if newValue && !isAISectionExpanded {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isAISectionExpanded = true
                            }
                        }
                    }
            }
            .padding(.vertical, BSpacing.sm)
            
            // AI Options (collapsible)
            if isAIEnabled && isAISectionExpanded {
                VStack(spacing: 0) {
                    // Voice Selection
                    HStack {
                        Text("Voice")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(AIVoiceOption.allCases, id: \.self) { voice in
                                Button {
                                    aiVoice = voice
                                    HapticManager.shared.impact(.light)
                                } label: {
                                    Text(voice.displayName)
                                        .font(.body)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(aiVoice == voice ? Color.bananaYellow : Color.backgroundSecondary)
                                        .foregroundColor(aiVoice == voice ? .black : .textPrimary)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }
                    .padding(.vertical, BSpacing.sm)
                    
                    Divider().background(BananaTheme.Colors.divider)
                    
                    // Music Selection
                    NavigationLink {
                        MusicPickerView(selectedMusic: $aiMusic)
                    } label: {
                        HStack {
                            Text("Background Music")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text(aiMusic.displayName)
                                .foregroundColor(BananaTheme.Colors.textSecondary)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(BananaTheme.Colors.textTertiary)
                        }
                        .padding(.vertical, BSpacing.sm)
                    }
                    
                    Divider().background(BananaTheme.Colors.divider)
                    
                    // Preferred Name
                    SettingsRow(title: "Preferred Name") {
                        TextField("Banana", text: $aiPreferredName)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, BSpacing.sm)
                    
                    Divider().background(BananaTheme.Colors.divider)
                    
                    // Weather Toggle
                    HStack {
                        Text("Weather")
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Toggle("", isOn: $aiWeatherEnabled)
                            .labelsHidden()
                            .onChange(of: aiWeatherEnabled) { _, newValue in
                                if newValue {
                                    // Request location when weather is enabled
                                    requestLocationPermission()
                                }
                            }
                    }
                    .padding(.vertical, BSpacing.sm)
                    
                    Divider().background(BananaTheme.Colors.divider)
                    
                    // Headlines Categories
                    NavigationLink {
                        HeadlinesPickerView(selectedCategories: $aiHeadlinesCategories)
                    } label: {
                        HStack {
                            Text("News Categories")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text(headlinesDescription)
                                .foregroundColor(BananaTheme.Colors.textSecondary)
                                .multilineTextAlignment(.trailing)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(BananaTheme.Colors.textTertiary)
                        }
                        .padding(.vertical, BSpacing.sm)
                    }
                    
                    Divider().background(BananaTheme.Colors.divider)
                    
                    // Sports Categories
                    NavigationLink {
                        SportsPickerView(selectedCategories: $aiSportsCategories)
                    } label: {
                        HStack {
                            Text("Sports")
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Text(sportsDescription)
                                .foregroundColor(BananaTheme.Colors.textSecondary)
                                .multilineTextAlignment(.trailing)
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(BananaTheme.Colors.textTertiary)
                        }
                        .padding(.vertical, BSpacing.sm)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Other Settings Section
    
    private var otherSettingsSection: some View {
        VStack(spacing: 0) {
            // Sound
            NavigationLink {
                SoundPickerView(selectedSound: $selectedSound)
            } label: {
                HStack {
                    Text("Sound")
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(selectedSound.displayName)
                        .foregroundColor(BananaTheme.Colors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(BananaTheme.Colors.textTertiary)
                }
                .padding(.vertical, BSpacing.sm)
            }
            
            Divider().background(BananaTheme.Colors.divider)
            
            // Snooze
            HStack {
                Text("Snooze")
                    .foregroundColor(.textPrimary)
                Spacer()
                Picker("", selection: $snoozeLength) {
                    Text("Off").tag(nil as Int?)
                    ForEach(1...15, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes as Int?)
                    }
                }
                .pickerStyle(.menu)
                .accentColor(BananaTheme.Colors.textSecondary)
            }
            .padding(.vertical, BSpacing.sm)
            
            Divider().background(BananaTheme.Colors.divider)
            
            // Repeat
            NavigationLink {
                RepeatPickerView(selectedDays: $repeatDays)
            } label: {
                HStack {
                    Text("Repeat")
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text(repeatDescription)
                        .foregroundColor(BananaTheme.Colors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(BananaTheme.Colors.textTertiary)
                }
                .padding(.vertical, BSpacing.sm)
            }
            
            Divider().background(BananaTheme.Colors.divider)
            
            // Volume
            VStack(spacing: BananaTheme.Spacing.sm) {
                HStack {
                    Text("Volume")
                        .foregroundColor(.textPrimary)
                    Spacer()
                    Text("\(Int(volume * 100))%")
                        .foregroundColor(BananaTheme.Colors.textSecondary)
                }
                .padding(.vertical, BSpacing.sm)
                
                Slider(value: $volume, in: 0...1, step: 0.05)
                    .accentColor(BananaTheme.Colors.bananaYellow)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var headlinesDescription: String {
        if aiHeadlinesCategories.isEmpty {
            return "None"
        } else if aiHeadlinesCategories.count == HeadlinesCategory.allCases.count {
            return "All"
        } else {
            return aiHeadlinesCategories.map { $0.displayName }.joined(separator: ", ")
        }
    }
    
    private var sportsDescription: String {
        if aiSportsCategories.isEmpty {
            return "None"
        } else if aiSportsCategories.count == SportsCategory.allCases.count {
            return "All"
        } else {
            return aiSportsCategories.map { $0.displayName }.joined(separator: ", ")
        }
    }
    
    private func requestLocationPermission() {
        // TODO: Implement location permission request
        // This will be implemented when WeatherKit integration is added
        print("Location permission requested for weather")
    }
    
    private var repeatDescription: String {
        if repeatDays.isEmpty {
            return "Never"
        } else if repeatDays.count == 7 {
            return "Every day"
        } else if repeatDays.count == 5 && 
                  !repeatDays.contains(.saturday) && 
                  !repeatDays.contains(.sunday) {
            return "Weekdays"
        } else if repeatDays.count == 2 && 
                  repeatDays.contains(.saturday) && 
                  repeatDays.contains(.sunday) {
            return "Weekends"
        } else {
            return repeatDays.map { $0.shortName }.joined(separator: ", ")
        }
    }
    
    private func saveAlarm() {
        let newAlarm = Alarm(
            id: alarm?.id ?? UUID(),
            time: time,
            label: isWakeUpAlarm ? "Wake Up" : label, // Use fixed label for wake-up alarms
            isEnabled: true,
            isAIEnabled: isAIEnabled,
            soundIdentifier: selectedSound.rawValue,
            snoozeLength: snoozeLength,
            repeatDays: Array(repeatDays),
            volume: volume,
            isWakeUpAlarm: isWakeUpAlarm,
            aiVoice: aiVoice,
            aiMusic: aiMusic,
            aiWeatherEnabled: aiWeatherEnabled,
            aiHeadlinesCategories: aiHeadlinesCategories,
            aiSportsCategories: aiSportsCategories,
            aiLocationLatitude: aiLocationLatitude,
            aiLocationLongitude: aiLocationLongitude,
            aiPreferredName: aiPreferredName,
            lastUsedAt: alarm?.lastUsedAt ?? Date(),
            createdAt: alarm?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        // If this is a wake-up alarm with AI enabled, save to global user preferences
        if isWakeUpAlarm && isAIEnabled {
            saveGlobalUserPreferences(from: newAlarm)
        }
        
        onSave(newAlarm)
        dismiss()
    }
    
    private func saveGlobalUserPreferences(from alarm: Alarm) {
        do {
            let preferences = UserPreferences(
                timezone: TimeZone.current.identifier,
                locationZip: nil, // Will be set by user in settings
                name: alarm.aiPreferredName,
                city: nil, // Will be set by user in settings
                state: nil, // Will be set by user in settings
                voice: alarm.aiVoice,
                weatherEnabled: alarm.aiWeatherEnabled,
                headlinesCategories: Array(alarm.aiHeadlinesCategories.map { $0.rawValue }),
                sportsCategories: Array(alarm.aiSportsCategories.map { $0.rawValue }),
                lastSyncAt: Date()
            )
            
            try CoreDataManager.shared.saveUserPreferences(preferences)
            print("✅ Wake-up alarm AI settings saved to global preferences and synced")
            
        } catch {
            print("❌ Failed to save global user preferences: \(error)")
        }
    }
}