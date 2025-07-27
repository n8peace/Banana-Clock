//
//  AlarmDetailView.swift
//  BananaClock
//
//  Alarm creation and editing view
//

import SwiftUI
import Foundation

struct AlarmDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @State private var time: Date
    @State private var label: String
    @State private var isAIEnabled: Bool
    @State private var selectedSound: AlarmSound
    @State private var snoozeLength: Int
    @State private var repeatDays: Set<Alarm.Weekday>
    @State private var volume: Float
    @State private var vibrationEnabled: Bool
    @State private var showingPaywall = false
    @State private var showingDeleteConfirmation = false
    
    let alarm: Alarm?
    let onSave: (Alarm) -> Void
    let onDelete: ((Alarm) -> Void)?
    
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
        _volume = State(initialValue: alarm?.volume ?? 0.8)
        _vibrationEnabled = State(initialValue: alarm?.vibrationEnabled ?? true)
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
                            // Label
                            SettingsRow(title: "Label") {
                                TextField("Alarm", text: $label)
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.white)
                            }
                            
                            Divider().background(BananaTheme.Colors.divider)
                            
                            // AI Wake-up
                            HStack {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(BananaTheme.Colors.bananaYellow)
                                    Text("AI Wake-up")
                                        .foregroundColor(.textPrimary)
                                    Spacer()
                                }
                                Toggle("", isOn: $isAIEnabled)
                                    .labelsHidden()
                                    .onChange(of: isAIEnabled) { _, newValue in
                                        if newValue && !appState.isSubscribed {
                                            isAIEnabled = false
                                            showingPaywall = true
                                        }
                                    }
                            }
                            .padding(.vertical, BSpacing.sm)
                            
                            Divider().background(BananaTheme.Colors.divider)
                            
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
                                    ForEach(1...15, id: \.self) { minutes in
                                        Text("\(minutes) min").tag(minutes)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(BananaTheme.Colors.bananaYellow)
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
                            
                            Divider().background(BananaTheme.Colors.divider)
                            
                            // Vibration
                            HStack {
                                Text("Vibration")
                                    .foregroundColor(.textPrimary)
                                Spacer()
                                Toggle("", isOn: $vibrationEnabled)
                                    .labelsHidden()
                            }
                            .padding(.vertical, BSpacing.sm)
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
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
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
            isAIEnabled: isAIEnabled,
            soundIdentifier: selectedSound.rawValue,
            snoozeLength: snoozeLength,
            repeatDays: Array(repeatDays),
            volume: volume,
            vibrationEnabled: vibrationEnabled,
            createdAt: alarm?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        onSave(newAlarm)
        dismiss()
    }
}