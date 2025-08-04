//
//  WakeUpScheduleSettingsView.swift
//  BananaClock
//
//  Schedule settings for wake-up alarms (time and day selection)
//

import SwiftUI

struct WakeUpScheduleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var time: Date
    @Binding var selectedDays: Set<Alarm.Weekday>
    
    let occupiedDays: Set<Alarm.Weekday>
    
    // Day selection presets
    enum DayPreset {
        case custom, weekdays, weekends, everyday
    }
    
    @State private var dayPreset: DayPreset = .custom
    
    init(time: Binding<Date>, selectedDays: Binding<Set<Alarm.Weekday>>, occupiedDays: Set<Alarm.Weekday>) {
        self._time = time
        self._selectedDays = selectedDays
        self.occupiedDays = occupiedDays
        
        // Determine initial preset
        let initialDays = selectedDays.wrappedValue
        if initialDays.count == 5 && !initialDays.contains(.saturday) && !initialDays.contains(.sunday) {
            _dayPreset = State(initialValue: .weekdays)
        } else if initialDays.count == 2 && initialDays.contains(.saturday) && initialDays.contains(.sunday) {
            _dayPreset = State(initialValue: .weekends)
        } else if initialDays.count == 7 {
            _dayPreset = State(initialValue: .everyday)
        } else {
            _dayPreset = State(initialValue: .custom)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Time Section
                        VStack(spacing: 0) {
                            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .bananaCard()
                        .padding()
                        
                        // Day Selection Section
                        VStack(spacing: 0) {
                            // Section Header
                            HStack {
                                Text("Repeat")
                                    .font(BananaTheme.Typography.title3)
                                    .foregroundColor(.textPrimary)
                                Spacer()
                            }
                            .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            .padding(.top, BananaTheme.Spacing.md)
                            .padding(.bottom, BananaTheme.Spacing.sm)
                            
                            // Preset picker
                            Picker("Days", selection: $dayPreset) {
                                Text("Custom").tag(DayPreset.custom)
                                Text("Weekdays").tag(DayPreset.weekdays)
                                    .disabled(!canSelectWeekdays)
                                Text("Weekends").tag(DayPreset.weekends)
                                    .disabled(!canSelectWeekends)
                                Text("Every Day").tag(DayPreset.everyday)
                                    .disabled(!canSelectAll)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            .onChange(of: dayPreset) { _, newValue in
                                updateSelectedDays(for: newValue)
                            }
                            
                            // Custom day selection
                            if dayPreset == .custom {
                                VStack(spacing: 0) {
                                    ForEach(Alarm.Weekday.allCases, id: \.self) { day in
                                        HStack {
                                            Text(day.fullName)
                                                .font(BananaTheme.Typography.body)
                                                .foregroundColor(isDayAvailable(day) ? .textPrimary : .textDisabled)
                                            
                                            Spacer()
                                            
                                            if selectedDays.contains(day) {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(.bananaYellow)
                                            } else if !isDayAvailable(day) {
                                                Image(systemName: "lock.fill")
                                                    .foregroundColor(.textDisabled)
                                                    .font(.caption)
                                            }
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            toggleDay(day)
                                        }
                                        .padding(.horizontal, BananaTheme.Layout.cardPadding)
                                        .padding(.vertical, BananaTheme.Spacing.sm)
                                        
                                        if day != Alarm.Weekday.allCases.last {
                                            Divider().background(BananaTheme.Colors.divider)
                                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                                        }
                                    }
                                }
                            }
                        }
                        .bananaCard()
                        .padding()
                    }
                }
            }
            .navigationTitle("Schedule")
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
                    Button("Save") {
                        dismiss()
                    }
                    .foregroundColor(.bananaYellow)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func isDayAvailable(_ day: Alarm.Weekday) -> Bool {
        !occupiedDays.contains(day)
    }
    
    private var canSelectWeekdays: Bool {
        let weekdays: Set<Alarm.Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        return weekdays.isDisjoint(with: occupiedDays)
    }
    
    private var canSelectWeekends: Bool {
        let weekends: Set<Alarm.Weekday> = [.saturday, .sunday]
        return weekends.isDisjoint(with: occupiedDays)
    }
    
    private var canSelectAll: Bool {
        occupiedDays.isEmpty
    }
    
    private func toggleDay(_ day: Alarm.Weekday) {
        if !isDayAvailable(day) {
            // Show haptic feedback for locked day
            HapticManager.shared.notification(.warning)
            return
        }
        
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
        
        // Update preset to custom if manually changing
        dayPreset = .custom
        
        HapticManager.shared.impact(.light)
    }
    
    private func updateSelectedDays(for preset: DayPreset) {
        switch preset {
        case .custom:
            // Don't change selection
            break
        case .weekdays:
            if canSelectWeekdays {
                selectedDays = [.monday, .tuesday, .wednesday, .thursday, .friday]
            }
        case .weekends:
            if canSelectWeekends {
                selectedDays = [.saturday, .sunday]
            }
        case .everyday:
            if canSelectAll {
                selectedDays = Set(Alarm.Weekday.allCases)
            }
        }
    }
}

#Preview {
    WakeUpScheduleSettingsView(
        time: .constant(Date()),
        selectedDays: .constant([.monday, .wednesday, .friday]),
        occupiedDays: [.tuesday, .thursday]
    )
} 