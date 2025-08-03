//
//  StopwatchViewModel.swift
//  BananaClock
//
//  ViewModel for managing stopwatch with Live Activity integration and banana countdown
//

import Foundation
import SwiftUI
import Combine

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
    private var liveActivityService = LiveActivityService.shared
    private let stopwatchID = UUID()
    
    var displayTime: String {
        if isCountdownMode {
            // During countdown: show nothing (empty string) - only bananas visible
            return ""
        } else if countdownEnabled && !isRunning && elapsedTime == 0 {
            // Before countdown starts: show nothing (empty string) - only bananas visible
            return ""
        } else {
            // Show normal stopwatch time when running or has elapsed time
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
        
        // Start Live Activity
        Task {
            do {
                try await liveActivityService.startStopwatchActivity(stopwatchID: stopwatchID)
                print("✅ Started stopwatch Live Activity")
            } catch {
                print("❌ Failed to start stopwatch Live Activity: \(error)")
            }
        }
        
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
        lastCountdownSecond = 4 // Start at 4 so first tick triggers 3-second beep
        
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
        
        // Update Live Activity
        if elapsedTime > 0 {
            Task {
                await liveActivityService.updateStopwatchActivity(
                    stopwatchID: stopwatchID,
                    elapsedTime: elapsedTime,
                    isRunning: false,
                    lapCount: laps.count
                )
            }
        }
        
        // Don't reset anything - just stop
    }
    
    func reset() {
        stop()
        elapsedTime = 0
        countdownTime = 3
        laps.removeAll()
        lapStartTime = 0
        
        // End Live Activity
        Task {
            await liveActivityService.endStopwatchActivity(stopwatchID: stopwatchID)
        }
        
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
        
        // Update Live Activity with new lap
        Task {
            await liveActivityService.updateStopwatchActivity(
                stopwatchID: stopwatchID,
                elapsedTime: elapsedTime,
                isRunning: true,
                lapCount: laps.count,
                lastLapTime: lap.time
            )
        }
        
        // Play lap sound (single play, no looping)
        Task {
            await MainActor.run {
                AudioService.shared.playCountdownSound("stopwatch_countdown_tick", volume: 0.6)
            }
        }
        
        HapticManager.shared.impact(.light)
    }
    
    private func updateTime() {
        guard let startTime = startTime else { return }
        elapsedTime = Date().timeIntervalSince(startTime)
        
        // Update Live Activity periodically (every 0.1 seconds for smooth animation)
        if Int(elapsedTime * 10) % 1 == 0 {
            Task {
                await liveActivityService.updateStopwatchActivity(
                    stopwatchID: stopwatchID,
                    elapsedTime: elapsedTime,
                    isRunning: true,
                    lapCount: laps.count
                )
            }
        }
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
            
            // Start Live Activity
            Task {
                do {
                    try await liveActivityService.startStopwatchActivity(stopwatchID: stopwatchID)
                    print("✅ Started stopwatch Live Activity after countdown")
                } catch {
                    print("❌ Failed to start stopwatch Live Activity after countdown: \(error)")
                }
            }
            
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
        // Play countdown tick sound using AudioService (single play, no looping)
        Task {
            await MainActor.run {
                AudioService.shared.playCountdownSound("stopwatch_countdown_tick", volume: 0.6)
            }
        }
        HapticManager.shared.impact(.light)
    }
    
    private func playGoSound() {
        // Play countdown start sound using AudioService (single play, no looping)
        Task {
            await MainActor.run {
                AudioService.shared.playCountdownSound("stopwatch_countdown_start", volume: 0.8)
            }
        }
        HapticManager.shared.impact(.medium)
    }
}