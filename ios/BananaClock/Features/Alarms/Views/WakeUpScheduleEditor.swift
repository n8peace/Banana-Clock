//
//  WakeUpScheduleEditor.swift
//  BananaClock
//
//  Editor for wake-up alarm schedules
//

import SwiftUI

struct WakeUpScheduleEditor: View {
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
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Time Picker
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .colorScheme(.dark)
                            .padding()
                        
                        // Schedule Settings
                        VStack(spacing: 0) {
                            // Day Selection
                            NavigationLink {
                                RepeatPickerView(selectedDays: $selectedDays)
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
                        }
                        .bananaCard()
                        .padding()
                        
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
    
    // MARK: - Helper Methods
    
    private var repeatDescription: String {
        if selectedDays.isEmpty {
            return "Never"
        } else if selectedDays.count == 7 {
            return "Every day"
        } else if selectedDays.count == 5 && 
                  !selectedDays.contains(.saturday) && 
                  !selectedDays.contains(.sunday) {
            return "Weekdays"
        } else if selectedDays.count == 2 && 
                  selectedDays.contains(.saturday) && 
                  selectedDays.contains(.sunday) {
            return "Weekends"
        } else {
            return selectedDays.map { $0.shortName }.joined(separator: ", ")
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
    WakeUpScheduleEditor(
        schedule: nil,
        occupiedDays: [.monday, .wednesday],
        onSave: { _ in },
        onDelete: nil
    )
}