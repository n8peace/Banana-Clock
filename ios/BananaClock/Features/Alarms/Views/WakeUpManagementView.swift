//
//  WakeUpManagementView.swift
//  BananaClock
//
//  Wake-up alarm management view with all settings
//

import SwiftUI
import CoreData

struct WakeUpManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = WakeUpAlarmsViewModel()
    @State private var showingScheduleEditor = false
    @State private var showingAISettings = false
    @State private var nextAlarmTime: Date = Date().addingTimeInterval(3600) // Default to 1 hour from now
    
    // General settings state
    @State private var selectedSound: AlarmSound = .dreamExit
    @State private var snoozeLength: Int? = 9
    @State private var volume: Double = 0.7
    
    // Callback to notify parent of changes
    let onChangesMade: (() -> Void)?
    
    init(onChangesMade: (() -> Void)? = nil) {
        self.onChangesMade = onChangesMade
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: BananaTheme.Spacing.md) {
                        // Time Picker Section
                        DatePicker("", selection: $nextAlarmTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .padding()
                            .onChange(of: nextAlarmTime) { _, newTime in
                                updateNextAlarmTime(newTime)
                            }
                        
                        // Edit Schedule Button
                        Button {
                            showingScheduleEditor = true
                        } label: {
                            HStack {
                                Text("Edit Wake Up Schedule")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.textTertiary)
                            }
                            .padding(.vertical, BananaTheme.Spacing.sm)
                            .padding(.horizontal, BananaTheme.Layout.cardPadding)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .bananaCard()
                        .padding(.horizontal)
                        
                        // Next Alarm Section
                        VStack(spacing: 0) {
                            // Next Alarm Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: BananaTheme.Spacing.xxs) {
                                    Text("Next Alarm")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { isTomorrowAlarmEnabled },
                                    set: { newValue in
                                        toggleTomorrowAlarm(newValue)
                                    }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .bananaYellow))
                                .labelsHidden()
                            }
                            .padding(.vertical, BananaTheme.Spacing.sm)
                            .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            
                            Divider().background(BananaTheme.Colors.divider)
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            
                            // 🍌🧠 Wake Up toggle below Next Alarm toggle
                            HStack {
                                Text("🍌🧠 Wake Up")
                                    .font(.headline)
                                    .foregroundColor(isTomorrowAlarmEnabled ? .white : .textSecondary)
                                
                                Spacer()
                                
                                Toggle("", isOn: Binding(
                                    get: { isAIEnabled },
                                    set: { newValue in
                                        toggleAIEnabled(newValue)
                                    }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: .bananaYellow))
                                .labelsHidden()
                                .disabled(!isTomorrowAlarmEnabled)
                            }
                            .padding(.vertical, BananaTheme.Spacing.sm)
                            .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            .padding(.bottom, BananaTheme.Spacing.sm)
                        }
                        .bananaCard()
                        .padding(.horizontal)
                        
                        // Rest of Settings Section
                        VStack(spacing: 0) {
                            
                            // AI Settings Button (always visible, grayed out when disabled)
                            Button {
                                showingAISettings = true
                            } label: {
                                HStack {
                                    HStack(spacing: BananaTheme.Spacing.xs) {
                                        Text("AI Settings")
                                            .font(.body)
                                            .foregroundColor(isAIEnabled ? .white : .textSecondary)
                                        
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                            .foregroundColor(isAIEnabled ? .bananaYellow : .textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.textTertiary)
                                }
                                .padding(.vertical, BananaTheme.Spacing.sm)
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            Divider().background(BananaTheme.Colors.divider)
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            
                            // Sound Selection
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
                                .padding(.vertical, BananaTheme.Spacing.sm)
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            }
                            
                            Divider().background(BananaTheme.Colors.divider)
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            
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
                            .padding(.vertical, BananaTheme.Spacing.sm)
                            .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            
                            Divider().background(BananaTheme.Colors.divider)
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            
                            // Volume
                            VStack(alignment: .leading, spacing: BananaTheme.Spacing.xs) {
                                HStack {
                                    Text("Volume")
                                        .font(.body)
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(volume * 100))%")
                                        .font(.body)
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Slider(value: $volume, in: 0...1, step: 0.1)
                                    .accentColor(.bananaYellow)
                            }
                            .padding(.vertical, BananaTheme.Spacing.sm)
                            .padding(.horizontal, BananaTheme.Layout.cardPadding)
                        }
                        .bananaCard()
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Change Wake Up")
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
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.bananaYellow)
                }
            }
        }
        .sheet(isPresented: $showingScheduleEditor) {
            WakeUpScheduleView {
                Task {
                    await viewModel.loadWakeUpAlarms()
                    loadNextAlarmTime()
                    onChangesMade?()
                }
            }
        }
        .sheet(isPresented: $showingAISettings) {
            WakeUpAISettingsView(
                preferences: viewModel.userPreferences,
                onSave: { updatedPreferences in
                    Task {
                        await viewModel.updateAISettings(updatedPreferences)
                        onChangesMade?()
                    }
                }
            )
        }
        .task {
            await viewModel.loadWakeUpAlarms()
            loadNextAlarmTime()
        }
    }
    
    // MARK: - Helper Methods
    
    private var isTomorrowAlarmEnabled: Bool {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { return false }
        return nextAlarm.isEnabled
    }
    
    private var isAIEnabled: Bool {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { return false }
        return nextAlarm.isAIEnabled
    }
    
    private func loadNextAlarmTime() {
        if let nextAlarm = viewModel.nextVisibleWakeUpAlarm {
            nextAlarmTime = nextAlarm.time
        }
    }
    
    private func updateNextAlarmTime(_ newTime: Date) {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { return }
        
        Task {
            var updatedAlarm = nextAlarm
            updatedAlarm.time = newTime
            await viewModel.updateSchedule(updatedAlarm)
            onChangesMade?()
        }
    }
    
    private func toggleTomorrowAlarm(_ isEnabled: Bool) {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { return }
        
        Task {
            await viewModel.toggleAlarm(nextAlarm, isEnabled: isEnabled)
            onChangesMade?()
        }
    }
    
    private func toggleAIEnabled(_ isEnabled: Bool) {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { return }
        
        Task {
            var updatedAlarm = nextAlarm
            updatedAlarm.isAIEnabled = isEnabled
            await viewModel.updateSchedule(updatedAlarm)
            onChangesMade?()
        }
    }
}

#Preview {
    WakeUpManagementView {
        // Preview callback
    }
    .environmentObject(AppState())
}