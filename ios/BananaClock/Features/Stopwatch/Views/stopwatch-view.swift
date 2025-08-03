//
//  StopwatchView.swift
//  BananaClock
//
//  Stopwatch feature with enhanced UI and banana countdown
//

import SwiftUI
import Foundation
import AudioToolbox

struct StopwatchView: View {
    @StateObject private var viewModel = StopwatchViewModel()
    @EnvironmentObject var liveActivityService: LiveActivityService
    @State private var glowAnimation = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Enhanced Sunrise Glow - Inspired by Apple Health
            LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.3).opacity(0.60),   // Soft banana yellow (was 0.45)
                    Color(red: 1.0, green: 0.6, blue: 0.1).opacity(0.50),   // Tangerine orange (was 0.35)
                    Color(red: 1.0, green: 0.4, blue: 0.3).opacity(0.40),   // Warm coral red (was 0.25)
                    Color(red: 0.8, green: 0.4, blue: 0.8).opacity(0.30),   // Soft lavender for depth (was 0.15)
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: UnitPoint(x: 0.5, y: 0.3)
            )
            .blur(radius: 40)
            .ignoresSafeArea()
            .blendMode(.screen)
            .opacity(glowAnimation ? 1.0 : 0.70)
            .animation(.easeInOut(duration: 4), value: glowAnimation)
            
            // Radial gradient behind time display
            RadialGradient(
                colors: [
                    Color(red: 1.0, green: 0.9, blue: 0.3).opacity(0.35),   // (was 0.2)
                    Color.clear
                ],
                center: .top,
                startRadius: 20,
                endRadius: 200
            )
            .frame(height: 300)
            .frame(maxHeight: .infinity, alignment: .top)
            .blur(radius: 20)
            .blendMode(.screen)
            
            VStack(spacing: 0) {
                NavigationStack {
                    VStack(spacing: BananaTheme.Spacing.lg) {
                        // Time display
                        timeDisplay
                        
                        // Controls
                        controlButtons
                        
                        // Countdown toggle
                        countdownToggle
                        
                        // Lap times
                        if !viewModel.laps.isEmpty {
                            lapsList
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, BSpacing.lg)
                    .padding(.top, BSpacing.lg)
                }
                .navigationTitle("⏱️ Stopwatch")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .onAppear {
            glowAnimation = true
        }
    }
    
    // MARK: - Views
    
    private var countdownToggle: some View {
        HStack {
            Text("Countdown")
                .font(.body)
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $viewModel.countdownEnabled)
                .toggleStyle(SwitchToggleStyle(tint: BananaTheme.Colors.bananaYellow))
        }
        .padding(.horizontal)
        .padding(.vertical, BananaTheme.Spacing.sm)
    }
    
    private var timeDisplay: some View {
        VStack(spacing: BananaTheme.Spacing.xs) {
            ZStack {
                // Stable time display (always shows actual time)
                Text(viewModel.displayTime)
                    .font(BananaTheme.Typography.displayLarge)
                    .foregroundColor(viewModel.displayColor)
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                // Banana countdown overlay with transparent background
                if viewModel.isCountdownMode || (viewModel.countdownEnabled && !viewModel.isRunning && viewModel.elapsedTime == 0) {
                    Text(viewModel.countdownBananas)
                        .font(BananaTheme.Typography.displayLarge)
                        .foregroundColor(BananaTheme.Colors.bananaYellow)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.clear)
                }
            }
            
            // Fixed height container for lap indicator
            HStack {
                Spacer()
                if viewModel.isRunning && !viewModel.laps.isEmpty && !viewModel.isCountdownActive {
                    Text("LAP \(viewModel.laps.count + 1)")
                        .font(.caption)
                        .foregroundColor(BananaTheme.Colors.textSecondary)
                }
                Spacer()
            }
            .frame(height: 20) // Fixed height to prevent layout shifts
        }
    }
    
    private var controlButtons: some View {
        HStack(spacing: BananaTheme.Spacing.xl) {
            // Left button (Lap/Reset)
            Button {
                if viewModel.isRunning {
                    viewModel.lap()
                } else {
                    viewModel.reset()
                }
            } label: {
                Text(viewModel.isRunning ? "Lap" : "Reset")
                    .font(BananaTheme.Typography.button)
                    .foregroundColor(.white)
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .fill(BananaTheme.Colors.backgroundSecondary)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                            )
                    )
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(viewModel.elapsedTime == 0 || viewModel.isCountdownActive)
            
            // Right button (Start/Stop)
            Button {
                viewModel.toggle()
            } label: {
                Text(viewModel.buttonText)
                    .font(BananaTheme.Typography.button)
                    .foregroundColor(.black)
                    .frame(width: 100, height: 100)
                    .background(
                        Circle()
                            .fill(viewModel.buttonColor)
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    private var lapsList: some View {
        VStack(alignment: .leading, spacing: BananaTheme.Spacing.xs) {
            HStack {
                Text("Laps")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if viewModel.laps.count > 1 {
                    Button("Share") {
                        shareLaps()
                    }
                    .font(.caption)
                    .foregroundColor(BananaTheme.Colors.bananaYellow)
                }
            }
            .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.laps.reversed()) { lap in
                        LapRow(lap: lap, fastest: lap.id == viewModel.fastestLap?.id, slowest: lap.id == viewModel.slowestLap?.id)
                        
                        if lap.id != viewModel.laps.first?.id {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }
    
    private func shareLaps() {
        let text = viewModel.laps.enumerated().map { index, lap in
            "Lap \(lap.number): \(formatTime(lap.time))"
        }.joined(separator: "\n")
        
        let activityController = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityController, animated: true)
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let hundredths = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
}

// MARK: - Lap Row
struct LapRow: View {
    let lap: Lap
    let fastest: Bool
    let slowest: Bool
    
    var body: some View {
        HStack {
            Text("Lap \(lap.number)")
                .font(.body)
                .foregroundColor(textColor)
            
            Spacer()
            
            Text(formatTime(lap.time))
                .font(.system(.body, design: .monospaced))
                .foregroundColor(textColor)
        }
        .padding(.horizontal)
        .padding(.vertical, BananaTheme.Spacing.sm)
    }
    
    private var textColor: Color {
        if fastest {
            return BananaTheme.Colors.success
        } else if slowest {
            return BananaTheme.Colors.error
        } else {
            return .white
        }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        let hundredths = Int((interval.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
    }
}