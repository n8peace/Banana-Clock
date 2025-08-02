//
//  StopwatchLiveActivity.swift
//  BananaClockWidgets
//
//  Live Activity widget for Stopwatch with Dynamic Island integration
//

import ActivityKit
import WidgetKit
import SwiftUI

struct StopwatchLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: StopwatchActivityAttributes.self) { context in
            // Lock Screen/Banner UI
            StopwatchLockScreenView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    StopwatchExpandedLeadingView(context: context)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    StopwatchExpandedTrailingView(context: context)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    StopwatchExpandedBottomView(context: context)
                }
            } compactLeading: {
                // Compact leading UI (left side of notch)
                HStack(spacing: 2) {
                    Image(systemName: "stopwatch")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.bananaYellow)
                    
                    Text(context.state.compactFormattedTime)
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                }
            } compactTrailing: {
                // Compact trailing UI (right side of notch)
                StopwatchStatusIndicator(isRunning: context.state.isRunning)
                    .frame(width: 16, height: 16)
            } minimal: {
                // Minimal UI (smallest state)
                Image(systemName: context.state.isRunning ? "stopwatch.fill" : "stopwatch")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(context.state.isRunning ? Color.bananaYellow : .gray)
            }
        }
    }
}

// MARK: - Lock Screen View

struct StopwatchLockScreenView: View {
    let context: ActivityViewContext<StopwatchActivityAttributes>
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Stopwatch")
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
                    
                    if context.state.lapCount > 0 {
                        Text("Lap \(context.state.lapCount)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Last lap time if available
            if let lastLapTime = context.state.formattedLastLapTime {
                HStack {
                    Text("Last Lap:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(lastLapTime)
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.bananaYellow.opacity(0.8))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            
            // Control buttons
            HStack(spacing: 12) {
                if context.state.isRunning {
                    Button(intent: LapStopwatchIntent(
                        stopwatchID: context.attributes.stopwatchID,
                        elapsedTime: context.state.elapsedTime,
                        lapCount: context.state.lapCount
                    )) {
                        Label("Lap", systemImage: "flag.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color.bananaYellow)
                    }
                    
                    Button(intent: StopStopwatchIntent(
                        stopwatchID: context.attributes.stopwatchID,
                        elapsedTime: context.state.elapsedTime,
                        lapCount: context.state.lapCount
                    )) {
                        Label("Stop", systemImage: "stop.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                    }
                } else if context.state.elapsedTime > 0 {
                    Button(intent: ResetStopwatchIntent(stopwatchID: context.attributes.stopwatchID)) {
                        Label("Reset", systemImage: "arrow.clockwise.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.orange)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.black)
        .cornerRadius(16)
    }
}

// MARK: - Dynamic Island Expanded Views

struct StopwatchExpandedLeadingView: View {
    let context: ActivityViewContext<StopwatchActivityAttributes>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "stopwatch")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color.bananaYellow)
                
                Text("Stopwatch")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            
            Text(context.state.statusText)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
}

struct StopwatchExpandedTrailingView: View {
    let context: ActivityViewContext<StopwatchActivityAttributes>
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(context.state.formattedTime)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundColor(Color.bananaYellow)
            
            if context.state.lapCount > 0 {
                Text("Lap \(context.state.lapCount)")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct StopwatchExpandedBottomView: View {
    let context: ActivityViewContext<StopwatchActivityAttributes>
    
    var body: some View {
        HStack(spacing: 16) {
            if context.state.isRunning {
                // Left side - Lap button
                Button(intent: LapStopwatchIntent(
                    stopwatchID: context.attributes.stopwatchID,
                    elapsedTime: context.state.elapsedTime,
                    lapCount: context.state.lapCount
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "flag.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("Lap")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(Color.bananaYellow)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.bananaYellow.opacity(0.2))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Status indicator
                StopwatchStatusIndicator(isRunning: context.state.isRunning)
                    .frame(width: 24, height: 24)
                
                Spacer()
                
                // Right side - Stop button
                Button(intent: StopStopwatchIntent(
                    stopwatchID: context.attributes.stopwatchID,
                    elapsedTime: context.state.elapsedTime,
                    lapCount: context.state.lapCount
                )) {
                    HStack(spacing: 6) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("Stop")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(12)
                }
            } else if context.state.elapsedTime > 0 {
                // Show reset button when stopped
                Spacer()
                
                Button(intent: ResetStopwatchIntent(stopwatchID: context.attributes.stopwatchID)) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 12, weight: .medium))
                        Text("Reset")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(12)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Status Indicator Component

struct StopwatchStatusIndicator: View {
    let isRunning: Bool
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .fill(isRunning ? Color.bananaYellow.opacity(0.3) : Color.gray.opacity(0.3))
                .frame(width: 16, height: 16)
            
            Circle()
                .fill(isRunning ? Color.bananaYellow : Color.gray)
                .frame(width: 8, height: 8)
                .scaleEffect(animationScale)
                .onAppear {
                    if isRunning {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            animationScale = 1.3
                        }
                    }
                }
                .onChange(of: isRunning) { newIsRunning in
                    if newIsRunning {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            animationScale = 1.3
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            animationScale = 1.0
                        }
                    }
                }
        }
    }
}