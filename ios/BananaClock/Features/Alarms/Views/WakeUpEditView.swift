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
        
        // Initialize state
        _time = State(initialValue: schedule?.time ?? Date().addingTimeInterval(3600))
        _selectedDays = State(initialValue: schedule?.wakeUpDays ?? Set())
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
}

#Preview {
    WakeUpEditView(
        schedule: nil,
        occupiedDays: [.monday, .wednesday],
        onSave: { _ in },
        onDelete: nil
    )
} 