import SwiftUI

struct AlarmRow: View {
    let alarm: Alarm
    @Binding var isEnabled: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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
                    
                    if alarm.isWakeUpAlarm {
                        // Today/Tomorrow directly below time
                        Text(todayTomorrowText)
                            .font(.caption)
                            .foregroundColor(BananaTheme.Colors.textSecondary)
                        
                        // AI indicator below Today/Tomorrow
                        if alarm.isAIEnabled {
                            Text("🍌🧠 ON")
                                .font(.caption)
                                .foregroundColor(BananaTheme.Colors.bananaYellow)
                        } else {
                            Text("🍌🧠 OFF")
                                .font(.caption)
                                .foregroundColor(BananaTheme.Colors.textSecondary)
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
                
                Toggle("", isOn: $isEnabled)
                    .toggleStyle(SwitchToggleStyle(tint: BananaTheme.Colors.bananaYellow))
                    .labelsHidden()
            }
            .padding(.vertical, BananaTheme.Spacing.sm)
            .padding(.horizontal, BananaTheme.Spacing.md)
        }
        .buttonStyle(PlainButtonStyle())
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
