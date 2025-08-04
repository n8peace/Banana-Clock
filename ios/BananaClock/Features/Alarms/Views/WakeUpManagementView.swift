//
//  WakeUpManagementView.swift
//  BananaClock
//
//  Wake-up alarm management view with all settings
//

import SwiftUI
import CoreData
import Combine

struct WakeUpManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: WakeUpAlarmsViewModel // Shared instance, not created locally
    @State private var showingAISettings = false
    
    // No local state needed - bind directly to viewModel
    
    // Callback to notify parent of changes
    let onChangesMade: (() -> Void)?
    
    init(wakeUpViewModel: WakeUpAlarmsViewModel, onChangesMade: (() -> Void)? = nil) {
        self.viewModel = wakeUpViewModel
        self.onChangesMade = onChangesMade
        print("DEBUG: WakeUpManagementView - initialized with SHARED viewModel instance: \(ObjectIdentifier(wakeUpViewModel))")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                // Unified scrollable List
                List {
                    // Time Picker Row
                    VStack {
                        DatePicker("", selection: nextAlarmTimeBinding, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    // Edit Schedule Row
                    NavigationLink {
                        WakeUpScheduleView(wakeUpViewModel: viewModel) {
                            Task {
                                await viewModel.loadWakeUpAlarms()
                                onChangesMade?()
                            }
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Text("Edit Wake Up Schedule")
                                .font(.headline)
                                .foregroundColor(.bananaYellow)
                            Image(systemName: "chevron.right")
                                .font(.headline)
                                .foregroundColor(.bananaYellow)
                            Spacer()
                        }
                        .padding(.vertical, BananaTheme.Spacing.sm)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    // Next Alarm Section
                    Section("Next Alarm") {
                            // Next Alarm Toggle
                            HStack {
                                Text("Next Alarm")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Toggle("", isOn: nextAlarmEnabledBinding)
                                .toggleStyle(SwitchToggleStyle(tint: .bananaYellow))
                                .labelsHidden()
                            }
                            
                            // 🍌🧠 Wake Up toggle
                            HStack {
                                Text("🍌🧠 Wake Up")
                                    .foregroundColor(nextAlarmEnabledBinding.wrappedValue ? .white : .textSecondary)
                                
                                Spacer()
                                
                                Toggle("", isOn: aiAlarmEnabledBinding)
                                .toggleStyle(SwitchToggleStyle(tint: .bananaYellow))
                                .labelsHidden()
                                .disabled(!nextAlarmEnabledBinding.wrappedValue)
                            }
                        }
                        
                        // AI Settings Section
                        Section("AI Settings") {
                            Button {
                                showingAISettings = true
                            } label: {
                                HStack {
                                    HStack(spacing: BananaTheme.Spacing.xs) {
                                        Text("AI Settings")
                                            .foregroundColor(aiAlarmEnabledBinding.wrappedValue ? .white : .textSecondary)
                                        
                                        Image(systemName: "sparkles")
                                            .font(.caption)
                                            .foregroundColor(aiAlarmEnabledBinding.wrappedValue ? .bananaYellow : .textSecondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.textTertiary)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // General Alarm Settings Section
                        Section("General Alarm Settings") {
                            // Sound Selection
                            NavigationLink {
                                SoundPickerView(
                                    selectedSound: Binding(
                                        get: { selectedSound },
                                        set: { newSound in
                                            updateAlarmSound(newSound)
                                        }
                                    )
                                )
                            } label: {
                                HStack {
                                    Text("Sound")
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(selectedSound.displayName)
                                        .foregroundColor(.textSecondary)
                                }
                            }
                            
                            // Snooze
                            HStack {
                                Text("Snooze")
                                    .foregroundColor(.white)
                                Spacer()
                                Picker("", selection: Binding(
                                    get: { snoozeLength },
                                    set: { newLength in
                                        updateSnoozeLength(newLength)
                                    }
                                )) {
                                    Text("Off").tag(nil as Int?)
                                    ForEach(Array(1...10) + [15, 30, 45, 60], id: \.self) { minutes in
                                        Text("\(minutes) min").tag(minutes as Int?)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accentColor(.textSecondary)
                            }
                            
                            // Volume
                            VStack(alignment: .leading, spacing: BananaTheme.Spacing.xs) {
                                HStack {
                                    Text("Volume")
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(volume * 100))%")
                                        .foregroundColor(.textSecondary)
                                }
                                
                                Slider(value: Binding(
                                    get: { volume },
                                    set: { newVolume in
                                        updateVolume(newVolume)
                                    }
                                ), in: 0...1, step: 0.1)
                                    .accentColor(.bananaYellow)
                            }
                        }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .navigationTitle("Change Wake Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)

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
            print("DEBUG: WakeUpManagementView - task started, loading wake up alarms")
            await viewModel.loadWakeUpAlarms()
            print("DEBUG: WakeUpManagementView - initial data load completed")
        }
        .onReceive(viewModel.$nextVisibleWakeUpAlarm) { alarm in
            print("DEBUG: WakeUpManagementView - nextVisibleWakeUpAlarm changed: \(alarm?.id.uuidString.prefix(8) ?? "nil")")
            // No need to sync toggle states - bindings update automatically
        }
    }
    
    // MARK: - Helper Methods
    
    // MARK: - Toggle Binding Properties
    
    private var nextAlarmEnabledBinding: Binding<Bool> {
        Binding(
            get: {
                guard let nextVisibleAlarm = viewModel.nextVisibleWakeUpAlarm else { return false }
                return nextVisibleAlarm.isEnabled
            },
            set: { newValue in
                guard let nextVisibleAlarm = viewModel.nextVisibleWakeUpAlarm else { return }
                print("DEBUG: WakeUpManagementView.nextAlarmEnabledBinding - setting to \(newValue)")
                Task {
                    await viewModel.toggleAlarm(nextVisibleAlarm, isEnabled: newValue)
                    onChangesMade?()
                }
            }
        )
    }
    
    private var aiAlarmEnabledBinding: Binding<Bool> {
        Binding(
            get: {
                guard let nextVisibleAlarm = viewModel.nextVisibleWakeUpAlarm else { return false }
                return nextVisibleAlarm.isAIEnabled
            },
            set: { newValue in
                guard let nextVisibleAlarm = viewModel.nextVisibleWakeUpAlarm else { return }
                print("DEBUG: WakeUpManagementView.aiAlarmEnabledBinding - setting to \(newValue)")
                Task {
                    var updatedAlarm = nextVisibleAlarm
                    updatedAlarm.isAIEnabled = newValue
                    await viewModel.updateSchedule(updatedAlarm)
                    onChangesMade?()
                }
            }
        )
    }
    
    // MARK: - Settings Computed Properties
    
    private var nextAlarmTimeBinding: Binding<Date> {
        Binding(
            get: {
                guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else {
                    print("DEBUG: WakeUpManagementView.nextAlarmTimeBinding.get - no nextVisibleWakeUpAlarm, returning default")
                    return Date().addingTimeInterval(3600) // Default to 1 hour from now
                }
                print("DEBUG: WakeUpManagementView.nextAlarmTimeBinding.get - returning \(nextAlarm.time)")
                return nextAlarm.time
            },
            set: { newTime in
                print("DEBUG: WakeUpManagementView.nextAlarmTimeBinding.set - updating to \(newTime)")
                updateNextAlarmTime(newTime)
            }
        )
    }
    
    private var selectedSound: AlarmSound {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { 
            print("DEBUG: WakeUpManagementView.selectedSound - no nextVisibleWakeUpAlarm, defaulting to .dreamExit")
            return .dreamExit 
        }
        let sound = AlarmSound(rawValue: nextAlarm.soundIdentifier) ?? .dreamExit
        print("DEBUG: WakeUpManagementView.selectedSound - \(sound.displayName)")
        return sound
    }
    
    private var snoozeLength: Int? {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { 
            print("DEBUG: WakeUpManagementView.snoozeLength - no nextVisibleWakeUpAlarm, defaulting to 9")
            return 9 
        }
        print("DEBUG: WakeUpManagementView.snoozeLength - \(nextAlarm.snoozeLength?.description ?? "nil")")
        return nextAlarm.snoozeLength
    }
    
    private var volume: Double {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { 
            print("DEBUG: WakeUpManagementView.volume - no nextVisibleWakeUpAlarm, defaulting to 0.7")
            return 0.7 
        }
        let vol = Double(nextAlarm.volume)
        print("DEBUG: WakeUpManagementView.volume - \(vol)")
        return vol
    }
    
    // syncToggleStates method removed - using direct bindings now
    
    private func updateNextAlarmTime(_ newTime: Date) {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { 
            print("DEBUG: WakeUpManagementView.updateNextAlarmTime - no nextVisibleWakeUpAlarm")
            return 
        }
        
        print("DEBUG: WakeUpManagementView.updateNextAlarmTime - using SHARED viewModel instance: \(ObjectIdentifier(viewModel))")
        print("DEBUG: WakeUpManagementView.updateNextAlarmTime - updating time from \(nextAlarm.time) to \(newTime)")
        Task {
            var updatedAlarm = nextAlarm
            updatedAlarm.time = newTime
            updatedAlarm.updatedAt = Date()
            await viewModel.updateSchedule(updatedAlarm)
            onChangesMade?()
        }
    }
    
    // toggleTomorrowAlarm and toggleAIEnabled methods removed - using direct bindings now
    
    // MARK: - Settings Update Methods
    
    private func updateAlarmSound(_ sound: AlarmSound) {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { 
            print("DEBUG: WakeUpManagementView.updateAlarmSound - no nextVisibleWakeUpAlarm")
            return 
        }
        
        print("DEBUG: WakeUpManagementView.updateAlarmSound - updating to \(sound.displayName)")
        Task {
            var updatedAlarm = nextAlarm
            updatedAlarm.soundIdentifier = sound.rawValue
            updatedAlarm.updatedAt = Date()
            await viewModel.updateSchedule(updatedAlarm)
            onChangesMade?()
        }
    }
    
    private func updateSnoozeLength(_ length: Int?) {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { 
            print("DEBUG: WakeUpManagementView.updateSnoozeLength - no nextVisibleWakeUpAlarm")
            return 
        }
        
        print("DEBUG: WakeUpManagementView.updateSnoozeLength - updating to \(length?.description ?? "nil")")
        Task {
            var updatedAlarm = nextAlarm
            updatedAlarm.snoozeLength = length
            updatedAlarm.updatedAt = Date()
            await viewModel.updateSchedule(updatedAlarm)
            onChangesMade?()
        }
    }
    
    private func updateVolume(_ newVolume: Double) {
        guard let nextAlarm = viewModel.nextVisibleWakeUpAlarm else { 
            print("DEBUG: WakeUpManagementView.updateVolume - no nextVisibleWakeUpAlarm")
            return 
        }
        
        print("DEBUG: WakeUpManagementView.updateVolume - updating to \(newVolume)")
        Task {
            var updatedAlarm = nextAlarm
            updatedAlarm.volume = Float(newVolume)
            updatedAlarm.updatedAt = Date()
            await viewModel.updateSchedule(updatedAlarm)
            onChangesMade?()
        }
    }
}

#Preview {
    WakeUpManagementView(wakeUpViewModel: WakeUpAlarmsViewModel()) {
        // Preview callback
    }
    .environmentObject(AppState())
}