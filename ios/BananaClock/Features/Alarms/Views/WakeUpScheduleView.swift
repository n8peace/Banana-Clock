//
//  WakeUpScheduleView.swift
//  BananaClock
//
//  Schedule management view for wake-up alarms
//

import SwiftUI

struct WakeUpScheduleView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WakeUpAlarmsViewModel // Shared instance, not created locally
    @State private var showingScheduleEditor = false
    @State private var selectedSchedule: Alarm?
    
    // Callback to notify parent of changes
    let onChangesMade: (() -> Void)?
    
    init(wakeUpViewModel: WakeUpAlarmsViewModel, onChangesMade: (() -> Void)? = nil) {
        self.viewModel = wakeUpViewModel
        self.onChangesMade = onChangesMade
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.wakeUpSchedules.isEmpty {
                        ScrollView {
                            emptyStateView
                                .frame(maxWidth: .infinity, minHeight: 400)
                        }
                    } else {
                        schedulesList
                    }
                }
            }
            .navigationTitle("Schedules")
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
            WakeUpEditView(
                schedule: selectedSchedule,
                occupiedDays: selectedSchedule != nil ? viewModel.getOccupiedDays(excluding: selectedSchedule!) : viewModel.occupiedDays,
                onSave: { updatedSchedule in
                    Task {
                        if selectedSchedule != nil {
                            await viewModel.updateSchedule(updatedSchedule)
                        } else {
                            await viewModel.addSchedule(updatedSchedule)
                        }
                        onChangesMade?()
                    }
                },
                onDelete: selectedSchedule != nil ? {
                    Task {
                        await viewModel.deleteSchedule(selectedSchedule!)
                        onChangesMade?()
                    }
                } : nil
            )
        }
        .task {
            await viewModel.loadWakeUpAlarms()
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: BananaTheme.Spacing.lg) {
            Image(systemName: "alarm")
                .font(.system(size: 64))
                .foregroundColor(BananaTheme.Colors.textTertiary)
            
            Text("No Wake Up Schedules")
                .font(.title2)
                .foregroundColor(BananaTheme.Colors.textPrimary)
            
            Text("Start your day right with a Banana Clock wake up")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            BananaButton("Add Schedule", icon: "plus") {
                selectedSchedule = nil
                showingScheduleEditor = true
            }
            .frame(width: 200)
        }
        .padding()
    }
    
    private var schedulesList: some View {
        List {
            // Schedules Section
            ForEach(viewModel.wakeUpSchedules) { schedule in
                WakeUpScheduleRow(
                    schedule: schedule,
                    onTap: {
                        selectedSchedule = schedule
                        showingScheduleEditor = true
                    }
                )
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
            .onDelete { indexSet in
                Task {
                    await viewModel.deleteSchedules(at: indexSet)
                    onChangesMade?()
                }
            }
            
            // Add Schedule Row (if not all days are taken)
            if !viewModel.occupiedDays.isSuperset(of: Set(Alarm.Weekday.allCases)) {
                Button {
                    selectedSchedule = nil
                    showingScheduleEditor = true
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: BananaTheme.Spacing.xxs) {
                            HStack(spacing: BananaTheme.Spacing.xs) {
                                Text("Add Schedule")
                                    .font(.headline)
                                    .foregroundColor(.bananaYellow)
                                
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.bananaYellow)
                            }
                            
                            Text("Create a new wake up schedule")
                                .font(.body)
                                .foregroundColor(.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.textTertiary)
                    }
                    .padding(.vertical, BananaTheme.Spacing.sm)
                    .padding(.horizontal, BananaTheme.Spacing.md)
                }
                .buttonStyle(PlainButtonStyle())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
    }
}

// MARK: - WakeUpScheduleRow

struct WakeUpScheduleRow: View {
    let schedule: Alarm
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: BananaTheme.Spacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: BananaTheme.Spacing.xs) {
                    Text(timeString)
                        .font(.largeTitle)
                        .foregroundColor(.white)
                        .monospacedDigit()
                    Text(periodString)
                        .font(.title2)
                        .foregroundColor(BananaTheme.Colors.textSecondary)
                }
                
                // Days of the week
                Text(scheduleDescription)
                    .font(.caption)
                    .foregroundColor(BananaTheme.Colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textTertiary)
        }
        .padding(.vertical, BananaTheme.Spacing.sm)
        .padding(.horizontal, BananaTheme.Spacing.md)
        .onTapGesture {
            onTap()
        }
    }
    
    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: schedule.time)
    }
    
    private var periodString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: schedule.time)
    }
    
    private var scheduleDescription: String {
        guard let wakeUpDays = schedule.wakeUpDays else {
            return "No days selected"
        }
        
        if wakeUpDays.isEmpty {
            return "No days selected"
        } else if wakeUpDays.count == 7 {
            return "Every day"
        } else if wakeUpDays.count == 5 && 
                  !wakeUpDays.contains(.saturday) && 
                  !wakeUpDays.contains(.sunday) {
            return "Weekdays"
        } else if wakeUpDays.count == 2 && 
                  wakeUpDays.contains(.saturday) && 
                  wakeUpDays.contains(.sunday) {
            return "Weekends"
        } else {
            return wakeUpDays.map { $0.shortName }.joined(separator: ", ")
        }
    }
}

#Preview {
    WakeUpScheduleView(wakeUpViewModel: WakeUpAlarmsViewModel()) {
        // Preview callback
    }
} 