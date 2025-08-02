//
//  AlarmLiveActivity.swift
//  BananaClockWidgets
//
//  Live Activity widget for Alarms with Dynamic Island integration
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AlarmLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmActivityAttributes.self) { context in
            // Lock Screen/Banner UI
            AlarmLockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    AlarmExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    AlarmExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    AlarmExpandedBottomView(context: context)
                }
            } compactLeading: {
                // Compact leading UI (left side of notch)
                HStack(spacing: 4) {
                    Image(systemName: alarmIcon(for: context.state.alarmState))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(alarmColor(for: context.state.alarmState))
                    
                    if context.state.alarmState == .snoozed, let snoozeTime = context.state.formattedSnoozeTime {
                        Text(snoozeTime)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    } else {
                        Text(context.state.formattedCurrentTime)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
            } compactTrailing: {
                // Compact trailing UI (right side of notch)
                if context.state.alarmState == .snoozed {
                    SnoozeProgressRing(progress: context.state.snoozeProgress)
                        .frame(width: 16, height: 16)
                } else {
                    AlarmPulseIndicator(state: context.state.alarmState)
                        .frame(width: 16, height: 16)
                }
            } minimal: {
                // Minimal UI (smallest state)
                Image(systemName: alarmIcon(for: context.state.alarmState))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(alarmColor(for: context.state.alarmState))
            }
        }
    }
    
    // Helper functions for alarm state
    private func alarmIcon(for state: AlarmState) -> String {
        switch state {
        case .ringing: return "bell.fill"
        case .snoozed: return "clock.arrow.circlepath"
        case .dismissed: return "checkmark.circle.fill"
        case .aiWakeUpPlaying: return "brain.head.profile"
        }
    }
    
    private func alarmColor(for state: AlarmState) -> Color {
        switch state {
        case .ringing: return .red
        case .snoozed: return .orange
        case .dismissed: return .green
        case .aiWakeUpPlaying: return Color.bananaYellow
        }
    }
}

// MARK: - Lock Screen View

struct AlarmLockScreenView: View {
    let context: ActivityViewContext<AlarmActivityAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with alarm info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if context.attributes.isAIWakeUp {
                        HStack(spacing: 6) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color.bananaYellow)
                            Text("AI Wake-Up")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    } else {
                        Text(context.attributes.alarmTitle)
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    Text(context.state.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if context.state.alarmState == .snoozed, let snoozeTime = context.state.formattedSnoozeTime {
                        Text(snoozeTime)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        Text("until alarm")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(context.state.formattedCurrentTime)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.bananaYellow)
                        Text("scheduled \(context.attributes.formattedScheduledTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // AI wake-up content if available
            if let wakeUpContent = context.state.wakeUpContent {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "quote.bubble.fill")
                            .font(.system(size: 14))
                            .foregroundColor(Color.bananaYellow)
                        Text("Your AI Wake-Up Message")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Text(wakeUpContent)
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
                .padding(12)
                .background(Color.bananaYellow.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Snooze progress bar for snoozed state
            if context.state.alarmState == .snoozed && context.state.snoozeProgress > 0 {
                VStack(spacing: 4) {
                    HStack {
                        Text("Snooze Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(context.state.snoozeProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 4)
                                .cornerRadius(2)
                            
                            Rectangle()
                                .fill(.orange)
                                .frame(width: geometry.size.width * context.state.snoozeProgress, height: 4)
                                .cornerRadius(2)
                                .animation(.easeInOut(duration: 0.5), value: context.state.snoozeProgress)
                        }
                    }
                    .frame(height: 4)
                }
            }
            
            // Action buttons
            alarmActionButtons(for: context)
        }
        .padding(16)
        .background(backgroundGradient(for: context.state.alarmState))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func alarmActionButtons(for context: ActivityViewContext<AlarmActivityAttributes>) -> some View {
        switch context.state.alarmState {
        case .ringing, .aiWakeUpPlaying:
            HStack(spacing: 16) {
                Button(intent: Snooze10Intent(alarmID: context.attributes.alarmID)) {
                    VStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20, weight: .medium))
                        Text("Snooze")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(16)
                }
                
                Button(intent: ImAwakeIntent(alarmID: context.attributes.alarmID, alarmType: context.attributes.alarmType.rawValue)) {
                    VStack(spacing: 4) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 20, weight: .medium))
                        Text("I'm Awake!")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.green)
                    .cornerRadius(16)
                }
            }
            
        case .snoozed:
            HStack {
                Text("💤 Snoozed - Alarm will ring again soon")
                    .font(.body)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(intent: ImAwakeIntent(alarmID: context.attributes.alarmID, alarmType: context.attributes.alarmType.rawValue)) {
                    Text("Cancel Snooze")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
        case .dismissed:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.green)
                
                VStack(alignment: .leading) {
                    Text("Good Morning!")
                        .font(.headline)
                        .foregroundColor(.white)
                    Text("Have a great day! 🌅")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private func backgroundGradient(for state: AlarmState) -> LinearGradient {
        switch state {
        case .ringing:
            return LinearGradient(
                colors: [Color.red.opacity(0.3), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .snoozed:
            return LinearGradient(
                colors: [Color.orange.opacity(0.3), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .dismissed:
            return LinearGradient(
                colors: [Color.green.opacity(0.3), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .aiWakeUpPlaying:
            return LinearGradient(
                colors: [Color.bananaYellow.opacity(0.3), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Dynamic Island Expanded Views

struct AlarmExpandedLeadingView: View {
    let context: ActivityViewContext<AlarmActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: context.attributes.isAIWakeUp ? "brain.head.profile" : "bell.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(context.attributes.isAIWakeUp ? Color.bananaYellow : .white)
                
                Text(context.attributes.isAIWakeUp ? "AI Wake-Up" : context.attributes.alarmTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Text(context.state.statusMessage)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

struct AlarmExpandedTrailingView: View {
    let context: ActivityViewContext<AlarmActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            if context.state.alarmState == .snoozed, let snoozeTime = context.state.formattedSnoozeTime {
                Text(snoozeTime)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                Text("snooze")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            } else {
                Text(context.state.formattedCurrentTime)
                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                    .foregroundColor(Color.bananaYellow)
                Text("now")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct AlarmExpandedBottomView: View {
    let context: ActivityViewContext<AlarmActivityAttributes>
    
    var body: some View {
        switch context.state.alarmState {
        case .ringing, .aiWakeUpPlaying:
            HStack(spacing: 12) {
                // Left side - Snooze button
                Button(intent: Snooze10Intent(alarmID: context.attributes.alarmID)) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 12, weight: .medium))
                        Text("Snooze")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(16)
                }
                
                Spacer()
                
                // Center - Alarm indicator
                AlarmPulseIndicator(state: context.state.alarmState)
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                // Right side - I'm Awake button
                Button(intent: ImAwakeIntent(alarmID: context.attributes.alarmID, alarmType: context.attributes.alarmType.rawValue)) {
                    HStack(spacing: 6) {
                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("I'm Awake!")
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .cornerRadius(16)
                }
            }
            .padding(.horizontal, 16)
            
        case .snoozed:
            HStack {
                Text("💤 Snoozed")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                SnoozeProgressRing(progress: context.state.snoozeProgress)
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                Button(intent: ImAwakeIntent(alarmID: context.attributes.alarmID, alarmType: context.attributes.alarmType.rawValue)) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 16)
            
        case .dismissed:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
                
                Text("Good Morning! 🌅")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Component Views

struct AlarmPulseIndicator: View {
    let state: AlarmState
    @State private var animationScale: CGFloat = 1.0
    @State private var animationOpacity: Double = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(indicatorColor.opacity(0.3))
                .frame(width: 20, height: 20)
                .scaleEffect(animationScale)
                .opacity(animationOpacity)
            
            Circle()
                .fill(indicatorColor)
                .frame(width: 12, height: 12)
        }
        .onAppear {
            startPulseAnimation()
        }
        .onChange(of: state) { _ in
            startPulseAnimation()
        }
    }
    
    private var indicatorColor: Color {
        switch state {
        case .ringing: return .red
        case .snoozed: return .orange
        case .dismissed: return .green
        case .aiWakeUpPlaying: return Color.bananaYellow
        }
    }
    
    private func startPulseAnimation() {
        guard state == .ringing || state == .aiWakeUpPlaying else {
            // Stop animation for non-active states
            withAnimation(.easeInOut(duration: 0.3)) {
                animationScale = 1.0
                animationOpacity = 1.0
            }
            return
        }
        
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            animationScale = 1.5
            animationOpacity = 0.5
        }
    }
}

struct SnoozeProgressRing: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}