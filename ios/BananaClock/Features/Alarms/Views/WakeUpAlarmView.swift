//
//  WakeUpAlarmView.swift
//  BananaClock
//
//  Reusable wake-up alarm display component with proper state management
//

import SwiftUI

struct WakeUpAlarmView: View {
    let alarmId: UUID
    @ObservedObject var wakeUpViewModel: WakeUpAlarmsViewModel
    let onToggle: (Alarm, Bool) -> Void
    let onTap: () -> Void
    
    // Computed property that always gets the current alarm state
    private var currentAlarm: Alarm? {
        wakeUpViewModel.wakeUpSchedules.first(where: { $0.id == alarmId })
    }
    
    var body: some View {
        Group {
            if let alarm = currentAlarm {
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: BananaTheme.Spacing.xxs) {
                            HStack(alignment: .firstTextBaseline, spacing: BananaTheme.Spacing.xs) {
                                Text(timeString(from: alarm.time))
                                    .font(.largeTitle)
                                    .foregroundColor(alarm.isEnabled ? .white : BananaTheme.Colors.textTertiary)
                                    .monospacedDigit()
                                Text(periodString(from: alarm.time))
                                    .font(.title2)
                                    .foregroundColor(alarm.isEnabled ? BananaTheme.Colors.textSecondary : BananaTheme.Colors.textTertiary)
                            }
                            
                            // Today/Tomorrow and AI status inline below time
                            HStack(spacing: BananaTheme.Spacing.xs) {
                                Text(todayTomorrowText(for: alarm))
                                    .font(.caption)
                                    .foregroundColor(BananaTheme.Colors.textSecondary)
                                
                                // Text content depends ONLY on AI toggle state
                                let aiStatusText = alarm.isAIEnabled ? "🍌🧠 Wake Up ON" : "🍌🧠 Wake Up OFF"
                                // Color depends on BOTH alarm enabled AND AI enabled
                                let textColor = (alarm.isEnabled && alarm.isAIEnabled) ? BananaTheme.Colors.bananaYellow : BananaTheme.Colors.textSecondary
                                
                                Text(aiStatusText)
                                    .font(.caption)
                                    .foregroundColor(textColor)
                            }
                        }
                        
                        Spacer()
                        
                        // Wake up alarm toggle with proper state binding
                        VStack(alignment: .trailing, spacing: BananaTheme.Spacing.xxs) {
                            Toggle("", isOn: Binding(
                                get: {
                                    // Always read from current state
                                    currentAlarm?.isEnabled ?? false
                                },
                                set: { newValue in
                                    // Use current alarm object for toggle
                                    if let currentAlarm = currentAlarm {
                                        onToggle(currentAlarm, newValue)
                                    }
                                }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: BananaTheme.Colors.bananaYellow))
                            .labelsHidden()
                        }
                    }
                    .onTapGesture {
                        onTap()
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: BananaTheme.Spacing.md, bottom: 0, trailing: BananaTheme.Spacing.md))
            } else {
                // Alarm not found - show placeholder
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading, spacing: BananaTheme.Spacing.xxs) {
                            HStack(alignment: .firstTextBaseline, spacing: BananaTheme.Spacing.xs) {
                                Text("--:--")
                                    .font(.largeTitle)
                                    .foregroundColor(BananaTheme.Colors.textTertiary)
                                    .monospacedDigit()
                                Text("--")
                                    .font(.title2)
                                    .foregroundColor(BananaTheme.Colors.textTertiary)
                            }
                            
                            Text("Loading...")
                                .font(.caption)
                                .foregroundColor(BananaTheme.Colors.textTertiary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: BananaTheme.Spacing.xxs) {
                            Toggle("", isOn: .constant(false))
                                .toggleStyle(SwitchToggleStyle(tint: BananaTheme.Colors.bananaYellow))
                                .labelsHidden()
                                .disabled(true)
                        }
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: BananaTheme.Spacing.md, bottom: 0, trailing: BananaTheme.Spacing.md))
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }
    
    private func periodString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: date)
    }
    
    private func todayTomorrowText(for alarm: Alarm) -> String {
        let calendar = Calendar.current
        let today = Date()
        let todayWeekday = calendar.component(.weekday, from: today)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today) ?? today
        let tomorrowWeekday = calendar.component(.weekday, from: tomorrow)
        
        guard let todayDay = Alarm.Weekday(rawValue: todayWeekday),
              let tomorrowDay = Alarm.Weekday(rawValue: tomorrowWeekday) else {
            return "Today" // Fallback
        }
        
        let alarmDays = alarm.wakeUpDays ?? Set(alarm.repeatDays)
        
        // Check if this alarm is scheduled for today
        if alarmDays.contains(todayDay) {
            return "Today"
        }
        
        // Check if this alarm is scheduled for tomorrow
        if alarmDays.contains(tomorrowDay) {
            return "Tomorrow"
        }
        
        // Fallback (should not happen with new logic, but safety)
        return "Today"
    }
}