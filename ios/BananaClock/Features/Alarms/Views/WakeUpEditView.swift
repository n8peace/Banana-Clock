//
//  WakeUpEditView.swift
//  BananaClock
//
//  Edit view for individual wake-up schedules
//

import SwiftUI

struct WakeUpEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var time: Date
    @State private var selectedDays: Set<Alarm.Weekday>
    @State private var showingDeleteConfirmation = false
    
    let schedule: Alarm?
    let occupiedDays: Set<Alarm.Weekday>
    let onSave: (Alarm) -> Void
    let onDelete: (() -> Void)?
    
    init(schedule: Alarm?, occupiedDays: Set<Alarm.Weekday>, onSave: @escaping (Alarm) -> Void, onDelete: (() -> Void)?) {
        self.schedule = schedule
        self.occupiedDays = occupiedDays
        self.onSave = onSave
        self.onDelete = onDelete
        
        // Initialize state with explicit conditional logic
        let defaultTime: Date
        let initialSelectedDays: Set<Alarm.Weekday>
        
        if let existingSchedule = schedule {
            defaultTime = existingSchedule.time
            initialSelectedDays = existingSchedule.wakeUpDays ?? Set()
        } else {
            defaultTime = Self.defaultWakeUpTime()
            initialSelectedDays = Set()
        }
        
        _time = State(initialValue: defaultTime)
        _selectedDays = State(initialValue: initialSelectedDays)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Time Picker
                    DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .colorScheme(.dark)
                        .padding()
                    
                    // Day Selection
                    VStack(spacing: 0) {
                        ForEach(Alarm.Weekday.allCases, id: \.self) { day in
                            let isSelected = selectedDays.contains(day)
                            let isOccupied = occupiedDays.contains(day)
                            let isDisabled = isOccupied && !isSelected
                            
                            Button {
                                if !isDisabled {
                                    if isSelected {
                                        selectedDays.remove(day)
                                    } else {
                                        selectedDays.insert(day)
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(day.fullName)
                                        .foregroundColor(isDisabled ? .textTertiary : .textPrimary)
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.bananaYellow)
                                            .font(.body)
                                    }
                                }
                                .padding(.vertical, BananaTheme.Spacing.sm)
                                .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            }
                            .disabled(isDisabled)
                            
                            if day != Alarm.Weekday.allCases.last {
                                Divider().background(BananaTheme.Colors.divider)
                                    .padding(.horizontal, BananaTheme.Layout.cardPadding)
                            }
                        }
                    }
                    .bananaCard()
                    .padding()
                    
                    Spacer()
                    
                    // Delete button (for existing schedules)
                    if schedule != nil && onDelete != nil {
                        Button {
                            showingDeleteConfirmation = true
                        } label: {
                            Text("Delete Schedule")
                                .font(.body)
                                .foregroundColor(BananaTheme.Colors.error)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(schedule == nil ? "Add Schedule" : "Edit Schedule")
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
                        saveSchedule()
                    }
                    .foregroundColor(.bananaYellow)
                    .disabled(selectedDays.isEmpty)
                }
            }
        }
        .alert("Delete Schedule", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this wake-up schedule?")
        }
    }
    
    private func saveSchedule() {
        let newSchedule = Alarm(
            id: schedule?.id ?? UUID(),
            time: time,
            label: "Wake Up",
            isEnabled: schedule?.isEnabled ?? true,
            isAIEnabled: schedule?.isAIEnabled ?? true,
            soundIdentifier: schedule?.soundIdentifier ?? "default",
            snoozeLength: schedule?.snoozeLength ?? 9,
            repeatDays: [], // Not used for wake-up alarms
            volume: schedule?.volume ?? 0.7,
            isWakeUpAlarm: true,
            wakeUpDays: selectedDays,
            aiVoice: schedule?.aiVoice ?? .voice1,
            aiMusic: schedule?.aiMusic ?? .chillVibes,
            aiWeatherEnabled: schedule?.aiWeatherEnabled ?? false,
            aiHeadlinesCategories: schedule?.aiHeadlinesCategories ?? [.business, .technology],
            aiSportsCategories: schedule?.aiSportsCategories ?? [.football, .basketball],
            aiLocationLatitude: schedule?.aiLocationLatitude,
            aiLocationLongitude: schedule?.aiLocationLongitude,
            aiPreferredName: schedule?.aiPreferredName,
            lastUsedAt: schedule?.lastUsedAt ?? Date(),
            createdAt: schedule?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        onSave(newSchedule)
        dismiss()
    }
    
    private static func defaultWakeUpTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // Create 7:00 AM today
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = 7
        components.minute = 0
        components.second = 0
        
        guard let sevenAMToday = calendar.date(from: components) else {
            // Fallback to current time if date creation fails
            return now
        }
        
        // If it's already past 7 AM today, use 7 AM tomorrow
        if now > sevenAMToday {
            return calendar.date(byAdding: .day, value: 1, to: sevenAMToday) ?? sevenAMToday
        }
        
        return sevenAMToday
    }
}

#Preview {
    WakeUpEditView(
        schedule: nil,
        occupiedDays: [.monday, .wednesday],
        onSave: { _ in },
        onDelete: nil
    )
} 