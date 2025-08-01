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
    let wakeUpViewModel: WakeUpAlarmsViewModel
    
    // Computed property to check if this is a wake-up alarm
    private var isWakeUpAlarm: Bool {
        alarm?.isWakeUpAlarm ?? false
    }
    
    init(alarm: Alarm?, wakeUpViewModel: WakeUpAlarmsViewModel, onSave: @escaping (Alarm) -> Void, onDelete: ((Alarm) -> Void)? = nil) {
        self.alarm = alarm
        self.onSave = onSave
        self.onDelete = onDelete
        self.wakeUpViewModel = wakeUpViewModel
        
        // Initialize state
        _time = State(initialValue: alarm?.time ?? Date().addingTimeInterval(3600))
        _label = State(initialValue: alarm?.label ?? "Alarm")
        _isAIEnabled = State(initialValue: alarm?.isAIEnabled ?? false)
        _selectedSound = State(initialValue: AlarmSound(rawValue: alarm?.soundIdentifier ?? "default") ?? .dreamExit)
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
        // Redirect wake-up alarms to the new management view
        if isWakeUpAlarm {
            WakeUpManagementView(wakeUpViewModel: wakeUpViewModel)
        } else {
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
                                // Label
                                SettingsRow(title: "Label") {
                                    TextField("Alarm", text: $label)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(.white)
                                }
                                
                                Divider().background(BananaTheme.Colors.divider)
                                
                                // Other settings in same card
                                otherSettingsSection
                            }
                            .bananaCard()
                            .padding()
                            
                            // Delete button (for existing alarms)
                            if alarm != nil {
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
                    ForEach(Array(1...10) + [15, 30, 45, 60], id: \.self) { minutes in
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
            label: label,
            isEnabled: true,
            isAIEnabled: false, // Regular alarms don't have AI
            soundIdentifier: selectedSound.rawValue,
            snoozeLength: snoozeLength,
            repeatDays: Array(repeatDays),
            volume: volume,
            isWakeUpAlarm: false, // This view is only for regular alarms now
            lastUsedAt: alarm?.lastUsedAt ?? Date(),
            createdAt: alarm?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        onSave(newAlarm)
        dismiss()
    }
    
}