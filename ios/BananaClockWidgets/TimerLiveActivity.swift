//
//  TimerLiveActivity.swift
//  BananaClockWidgets
//
//  Live Activity widget for Timer with Dynamic Island integration
//

import ActivityKit
import WidgetKit
import SwiftUI

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen/Banner UI
            TimerLockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    TimerExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimerExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    TimerExpandedBottomView(context: context)
                }
            } compactLeading: {
                // Compact leading UI (left side of notch)
                HStack(spacing: 2) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.bananaYellow)
                    
                    Text(context.state.formattedTime)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                // Compact trailing UI (right side of notch)
                TimerProgressRing(progress: context.state.progress)
                    .frame(width: 16, height: 16)
            } minimal: {
                // Minimal UI (smallest state)
                Image(systemName: context.state.isPaused ? "pause.circle.fill" : "timer")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(context.state.isPaused ? .orange : Color.bananaYellow)
            }
        }
    }
}

// MARK: - Lock Screen View

struct TimerLockScreenView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(context.state.statusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(context.state.formattedTime)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.bananaYellow)
                    
                    Text("of \(context.attributes.formattedDuration)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.bananaYellow)
                        .frame(width: geometry.size.width * context.state.progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.5), value: context.state.progress)
                }
            }
            .frame(height: 4)
            
            // Control buttons
            HStack(spacing: 12) {
                if context.state.isPaused {
                    Button(intent: ResumeTimerIntent(
                        timerID: context.attributes.timerID,
                        remainingTime: context.state.remainingTime
                    )) {
                        Label("Resume", systemImage: "play.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.bananaYellow)
                    }
                } else if context.state.isRunning {
                    Button(intent: PauseTimerIntent(
                        timerID: context.attributes.timerID,
                        remainingTime: context.state.remainingTime
                    )) {
                        Label("Pause", systemImage: "pause.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
                
                Button(intent: CancelTimerIntent(timerID: context.attributes.timerID)) {
                    Label("Cancel", systemImage: "xmark.circle.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
            }
        }
        .padding(16)
        .background(Color.black)
        .cornerRadius(16)
    }
}

// MARK: - Dynamic Island Expanded Views

struct TimerExpandedLeadingView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "timer")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.bananaYellow)
                
                Text(context.attributes.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Text(context.state.statusText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

struct TimerExpandedTrailingView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(context.state.formattedTime)
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .foregroundColor(Color.bananaYellow)
            
            Text("of \(context.attributes.formattedDuration)")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

struct TimerExpandedBottomView: View {
    let context: ActivityViewContext<TimerActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Play/Pause button
            if context.state.isPaused {
                Button(intent: ResumeTimerIntent(
                    timerID: context.attributes.timerID,
                    remainingTime: context.state.remainingTime
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("Resume")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color.bananaYellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.bananaYellow.opacity(0.2))
                    .cornerRadius(12)
                }
            } else if context.state.isRunning {
                Button(intent: PauseTimerIntent(
                    timerID: context.attributes.timerID,
                    remainingTime: context.state.remainingTime
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("Pause")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            // Progress indicator
            TimerProgressRing(progress: context.state.progress)
                .frame(width: 24, height: 24)
            
            Spacer()
            
            // Right side - Cancel button
            Button(intent: CancelTimerIntent(timerID: context.attributes.timerID)) {
                HStack(spacing: 6) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.red)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.red.opacity(0.2))
                .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Progress Ring Component

struct TimerProgressRing: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.bananaYellow, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

// MARK: - Banana Theme Extension

extension Color {
    static let bananaYellow = Color(red: 253/255, green: 224/255, blue: 67/255)
}