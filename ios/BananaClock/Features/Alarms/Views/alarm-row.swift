import SwiftUI

struct AlarmRow: View {
    let alarm: Alarm
    @Binding var isEnabled: Bool
    let onTap: () -> Void
    let isSelected: Bool
    let showSelection: Bool
    
    init(
        alarm: Alarm,
        isEnabled: Binding<Bool>,
        onTap: @escaping () -> Void,
        isSelected: Bool = false,
        showSelection: Bool = false
    ) {
        self.alarm = alarm
        self._isEnabled = isEnabled
        self.onTap = onTap
        self.isSelected = isSelected
        self.showSelection = showSelection
    }
    
    var body: some View {
        HStack {
            // Selection checkbox (only shown in edit mode)
            if showSelection {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? BananaTheme.Colors.bananaYellow : BananaTheme.Colors.textSecondary)
                    .frame(width: 24, height: 24)
            }
            
            VStack(alignment: .leading, spacing: BananaTheme.Spacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: BananaTheme.Spacing.xs) {
                    Text(timeString)
                        .font(.largeTitle)
                        .foregroundColor(isEnabled ? .white : BananaTheme.Colors.textTertiary)
                        .monospacedDigit()
                    Text(periodString)
                        .font(.title2)
                        .foregroundColor(isEnabled ? BananaTheme.Colors.textSecondary : BananaTheme.Colors.textTertiary)
                }
                
                if alarm.isWakeUpAlarm {
                    // Today/Tomorrow and AI status inline below time
                    HStack(spacing: BananaTheme.Spacing.xs) {
                        Text(todayTomorrowText)
                            .font(.caption)
                            .foregroundColor(isEnabled ? BananaTheme.Colors.textSecondary : BananaTheme.Colors.textTertiary)
                        
                        if alarm.isAIEnabled {
                            Text("🍌🧠 Wake Up ON")
                                .font(.caption)
                                .foregroundColor(isEnabled ? BananaTheme.Colors.bananaYellow : BananaTheme.Colors.textTertiary)
                        } else {
                            Text("🍌🧠 Wake Up OFF")
                                .font(.caption)
                                .foregroundColor(isEnabled ? BananaTheme.Colors.textSecondary : BananaTheme.Colors.textTertiary)
                        }
                    }
                } else {
                    HStack(spacing: BananaTheme.Spacing.xs) {
                        if alarm.isAIEnabled {
                            Label("AI", systemImage: "sparkles")
                                .font(.caption)
                                .foregroundColor(BananaTheme.Colors.bananaYellow)
                        }
                        
                        Text(alarm.label)
                            .font(.caption)
                            .foregroundColor(BananaTheme.Colors.textSecondary)
                    }
                }
                
                if !alarm.repeatDays.isEmpty {
                    Text(alarm.repeatDescription)
                        .font(.caption)
                        .foregroundColor(BananaTheme.Colors.textTertiary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: BananaTheme.Spacing.xxs) {
                // Only show toggle when not in selection mode
                if !showSelection {
                    Toggle("", isOn: $isEnabled)
                        .toggleStyle(SwitchToggleStyle(tint: BananaTheme.Colors.bananaYellow))
                        .labelsHidden()
                }
            }
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
        return formatter.string(from: alarm.time)
    }
    
    private var periodString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: alarm.time)
    }
    
    private var todayTomorrowText: String {
        let calendar = Calendar.current
        let now = Date()
        let alarmDate = alarm.nextFireDate
        
        if calendar.isDate(alarmDate, inSameDayAs: now) {
            return "Today"
        } else {
            return "Tomorrow"
        }
    }
    

}

#Preview {
    AlarmRow(
        alarm: Alarm(
            time: Date(),
            label: "Morning Alarm",
            isEnabled: true,
            isAIEnabled: true,
            soundIdentifier: "default",
            snoozeLength: 9,
            repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            volume: 0.7
        ),
        isEnabled: .constant(true),
        onTap: {}
    )
    .background(Color.black)
}
