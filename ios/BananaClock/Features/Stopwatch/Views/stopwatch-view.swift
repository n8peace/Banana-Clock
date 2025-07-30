//
//  StopwatchView.swift
//  BananaClock
//
//  Stopwatch feature
//

import SwiftUI
import Foundation
import AudioToolbox

struct StopwatchView: View {
    @StateObject private var viewModel = StopwatchViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
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
                
                // Banana countdown overlay with black background
                if viewModel.isCountdownMode || (viewModel.countdownEnabled && !viewModel.isRunning && viewModel.elapsedTime == 0) {
                    Text(viewModel.countdownBananas)
                        .font(BananaTheme.Typography.displayLarge)
                        .foregroundColor(BananaTheme.Colors.bananaYellow)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(Color.black)
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

// MARK: - Models
struct Lap: Identifiable {
    let id = UUID()
    let number: Int
    let time: TimeInterval
    let totalTime: TimeInterval
}

// MARK: - View Model
@MainActor
class StopwatchViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var laps: [Lap] = []
    @Published var countdownEnabled = false {
        didSet {
            // Only stop countdown if it's currently running
            if !countdownEnabled && isCountdownMode {
                stop()
            }
        }
    }
    
    var navigationTitle: String { "Stopwatch" }
    
    private var timer: Foundation.Timer?
    private var startTime: Date?
    private var lapStartTime: TimeInterval = 0
    private var countdownTime: TimeInterval = 3 // 3 seconds
    var isCountdownMode = false
    private var lastCountdownSecond: Int = 3 // Track last second to trigger audio
    
    var displayTime: String {
        if isCountdownMode {
            // Show active countdown
            let minutes = Int(countdownTime) / 60
            let seconds = Int(countdownTime) % 60
            let hundredths = Int((countdownTime.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "-%02d:%02d.%02d", minutes, seconds, hundredths)
        } else if countdownEnabled && !isRunning && elapsedTime == 0 {
            // Show countdown ready state only when no time has elapsed
            return "-00:03.00"
        } else {
            // Show normal stopwatch time
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            let hundredths = Int((elapsedTime.truncatingRemainder(dividingBy: 1)) * 100)
            return String(format: "%02d:%02d.%02d", minutes, seconds, hundredths)
        }
    }
    
    var isCountdownActive: Bool {
        return isCountdownMode
    }
    
    var countdownBananas: String {
        if isCountdownMode {
            let currentSecond = Int(ceil(countdownTime))
            switch currentSecond {
            case 3:
                return "🍌🍌🍌"
            case 2:
                return "🍌🍌"
            case 1:
                return "🍌"
            case 0:
                return "GO!"
            default:
                return "🍌🍌🍌"
            }
        } else {
            // Initial state when countdown is enabled but not started
            return "🍌🍌🍌"
        }
    }
    
    var displayColor: Color {
        if countdownEnabled && !isRunning && !isCountdownMode && elapsedTime == 0 {
            return BananaTheme.Colors.bananaYellow
        } else if isCountdownMode {
            return BananaTheme.Colors.bananaYellow
        } else {
            return .white
        }
    }
    
    var buttonText: String {
        if isCountdownMode {
            return "Stop"
        } else if isRunning {
            return "Stop"
        } else {
            return "Start"
        }
    }
    
    var buttonColor: Color {
        if isCountdownMode || isRunning {
            return BananaTheme.Colors.error
        } else {
            return BananaTheme.Colors.bananaYellow
        }
    }
    
    var fastestLap: Lap? {
        laps.min(by: { $0.time < $1.time })
    }
    
    var slowestLap: Lap? {
        guard laps.count > 1 else { return nil }
        return laps.max(by: { $0.time < $1.time })
    }
    
    func toggle() {
        if isRunning || isCountdownMode {
            stop()
        } else {
            if countdownEnabled && elapsedTime == 0 {
                startCountdown()
            } else {
                start()
            }
        }
        HapticManager.shared.impact(.medium)
    }
    
    func start() {
        isRunning = true
        startTime = Date().addingTimeInterval(-elapsedTime)
        
        timer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateTime()
            }
        }
        
        // Add timer to main run loop
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    func startCountdown() {
        isCountdownMode = true
        countdownTime = 3 // Reset to 3 seconds
        lastCountdownSecond = 3
        
        timer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
            DispatchQueue.main.async {
                self.updateCountdown()
            }
        }
        
        // Add timer to main run loop
        RunLoop.main.add(timer!, forMode: .common)
        
        // Force UI update
        objectWillChange.send()
    }
    
    func stop() {
        isRunning = false
        isCountdownMode = false
        timer?.invalidate()
        timer = nil
        // Don't reset anything - just stop
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        countdownTime = 3
        laps.removeAll()
        lapStartTime = 0
        HapticManager.shared.impact(.light)
    }
    
    func lap() {
        let lapTime = elapsedTime - lapStartTime
        let lap = Lap(
            number: laps.count + 1,
            time: lapTime,
            totalTime: elapsedTime
        )
        laps.append(lap)
        lapStartTime = elapsedTime
        HapticManager.shared.impact(.light)
    }
    
    private func updateTime() {
        guard let startTime = startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
    }
    
    private func updateCountdown() {
        countdownTime -= 0.01
        
        // Check if we've crossed a second boundary
        let currentSecond = Int(ceil(countdownTime))
        if currentSecond != lastCountdownSecond && currentSecond > 0 {
            lastCountdownSecond = currentSecond
            playCountdownBeep()
        }
        
        // Force UI update
        objectWillChange.send()
        
        if countdownTime <= 0 {
            // Countdown finished, start the stopwatch
            isCountdownMode = false
            isRunning = true
            startTime = Date()
            elapsedTime = 0 // Reset elapsed time when countdown finishes
            
            // Play go sound
            playGoSound()
            
            // Switch timer to normal stopwatch mode
            timer?.invalidate()
            timer = Foundation.Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                DispatchQueue.main.async {
                    self.updateTime()
                }
            }
            
            // Add timer to main run loop
            RunLoop.main.add(timer!, forMode: .common)
        }
    }
    
    private func playCountdownBeep() {
        // Play a simple beep sound for countdown
        // Using system sound for simplicity
        AudioServicesPlaySystemSound(1103) // System sound ID for beep
        HapticManager.shared.impact(.light)
    }
    
    private func playGoSound() {
        // Play a different sound for "Go!"
        AudioServicesPlaySystemSound(1104) // Different system sound
        HapticManager.shared.impact(.medium)
    }
}